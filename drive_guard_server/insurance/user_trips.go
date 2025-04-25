package insurance

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

func GetUserTrips(c *gin.Context, db *sql.DB) {
	// 1. Authentication and validation
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		log.Println("Missing authorization header")
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Authorization header required",
			"code":  "missing_auth_header",
		})
		return
	}

	// 2. Validate user ID
	userID := c.Param("userId")
	if userID == "" || userID == "null" {
		log.Println("Invalid user ID:", userID)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Valid user ID required",
			"code":  "invalid_user_id",
		})
		return
	}

	// 3. Convert to integer and validate
	userIDInt, err := strconv.Atoi(userID)
	if err != nil || userIDInt <= 0 {
		log.Println("Invalid user ID format:", userID)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "User ID must be a positive integer",
			"code":  "invalid_id_format",
		})
		return
	}

	// 4. Get sort parameter with validation
	sortBy := c.DefaultQuery("sort", "recent")
	if sortBy != "recent" && sortBy != "distance" {
		sortBy = "recent"
	}

	// 5. Build query - join with TripMetrics
	query := `
    SELECT 
        t.trip_id, 
        t.user_id, 
        t.start_time, 
        EXTRACT(EPOCH FROM (SELECT MAX((p->>'t')::timestamp) - MIN((p->>'t')::timestamp)
                           FROM jsonb_array_elements(t.data) as p)) / 60 AS duration,
        tm.distance,
        COALESCE(tm.avg_velo, 0) AS avg_velo,
        COALESCE(tm.max_velo, 0) AS max_velo,
        tm.brake_score,
        tm.accel_score,
        tm.trip_score
    FROM Trips t
    JOIN TripsMetrics tm ON t.trip_id = tm.trip_id
    WHERE t.user_id = $1
`

	switch sortBy {
	case "distance":
		query += " ORDER BY tm.distance DESC"
	default:
		query += " ORDER BY t.start_time DESC"
	}

	// 6. Execute query with timeout
	ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
	defer cancel()

	rows, err := db.QueryContext(ctx, query, userIDInt)
	if err != nil {
		log.Printf("Database query error for user %d: %v", userIDInt, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to retrieve trips",
			"code":  "database_error",
		})
		return
	}
	defer rows.Close()

	// 7. Process results
	type Trip struct {
		TripID     int       `json:"trip_id"`
		UserID     int       `json:"user_id"`
		StartTime  time.Time `json:"start_time"`
		Duration   float64   `json:"duration"`
		Distance   float64   `json:"distance"`
		AvgVelo    float64   `json:"average_speed"` // Maps avg_velo to average_speed
		MaxVelo    float64   `json:"max_speed"`     // Maps max_velo to max_speed
		BrakeScore float64   `json:"brake_score"`
		AccelScore float64   `json:"accel_score"`
		TripScore  float64   `json:"trip_score"`
	}

	var trips []Trip
	for rows.Next() {
		var t Trip
		err := rows.Scan(
			&t.TripID,
			&t.UserID,
			&t.StartTime,
			&t.Duration,
			&t.Distance,
			&t.AvgVelo,
			&t.MaxVelo,
			&t.BrakeScore,
			&t.AccelScore,
			&t.TripScore,
		)
		if err != nil {
			log.Printf("Error scanning trip row: %v", err)
			continue
		}
		trips = append(trips, t)
	}

	if err = rows.Err(); err != nil {
		log.Printf("Row iteration error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to process trips",
			"code":  "data_processing_error",
		})
		return
	}

	// 8. Successful response
	log.Printf("Returning %d trips for user %d", len(trips), userIDInt)
	c.JSON(http.StatusOK, gin.H{
		"user_id": userIDInt,
		"count":   len(trips),
		"trips":   trips,
		"status":  "success",
	})
}
