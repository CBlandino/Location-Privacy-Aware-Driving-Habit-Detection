package insurance

import (
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type TripData struct {
	Distance   float64 `json:"distance"`
	Duration   float64 `json:"duration"`
	AvgSpeed   float64 `json:"avg_speed"`
	BrakeScore float64 `json:"brake_score"`
	AccelScore float64 `json:"accel_score"`
}

type TripDataArray []TripData

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

	// 5. Build query with parameterized inputs
	query := `
		SELECT 
			trip_id, 
			user_id, 
			start_time, 
			data
		FROM Trips
		WHERE user_id = $1
	`

	switch sortBy {
	case "distance":
		query += " ORDER BY (data->0->>'distance')::float DESC"
	default:
		query += " ORDER BY start_time DESC"
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
		TripID    int       `json:"trip_id"`
		UserID    int       `json:"user_id"`
		StartTime time.Time `json:"start_time"`
		Distance  float64   `json:"distance"`
		Duration  float64   `json:"duration"`
		AvgSpeed  float64   `json:"average_speed"`
	}

	var trips []Trip
	for rows.Next() {
		var t struct {
			TripID    int
			UserID    int
			StartTime time.Time
			Data      []byte
		}

		err := rows.Scan(
			&t.TripID,
			&t.UserID,
			&t.StartTime,
			&t.Data,
		)
		if err != nil {
			log.Printf("Error scanning trip row: %v", err)
			continue
		}

		var tripDataArray TripDataArray
		if err := json.Unmarshal(t.Data, &tripDataArray); err != nil {
			log.Printf("Error unmarshaling trip data: %v", err)
			continue
		}

		// Use the first element of the array if it exists
		if len(tripDataArray) > 0 {
			tripData := tripDataArray[0]
			trips = append(trips, Trip{
				TripID:    t.TripID,
				UserID:    t.UserID,
				StartTime: t.StartTime,
				Distance:  tripData.Distance,
				Duration:  tripData.Duration,
				AvgSpeed:  tripData.AvgSpeed,
			})
		}
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
