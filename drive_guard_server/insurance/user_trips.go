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

type LocationPoint struct {
	PointNum  int     `json:"p"`
	Timestamp string  `json:"t"`
	DLat      float64 `json:"dlat"`
	DLon      float64 `json:"dlon"`
}

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

	// 5. Build query - we should join with TripMetrics table
	query := `
		SELECT 
			t.trip_id, 
			t.user_id, 
			t.start_time, 
			tm.distance,
			tm.avg_velo,
			tm.max_velo,
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
		Distance   float64   `json:"distance"`
		AvgSpeed   float64   `json:"average_speed"`
		MaxSpeed   float64   `json:"max_speed"`
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
			&t.Distance,
			&t.AvgSpeed,
			&t.MaxSpeed,
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
