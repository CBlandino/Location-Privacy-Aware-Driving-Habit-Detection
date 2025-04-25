package insurance

import (
	"database/sql"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

func GetUserScore(c *gin.Context, db *sql.DB) {
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

	// 4. Database query to get user scores and basic info
	log.Printf("Fetching score for user %d", userIDInt)
	var score, brakeScore, accelScore float64
	var firstName, lastName string
	var tripCount int

	// Main user query with trip count
	err = db.QueryRow(`
		SELECT 
			u.score, 
			u.brake_score, 
			u.accel_score, 
			u.first_name, 
			u.last_name,
			(SELECT COUNT(*) FROM Trips WHERE user_id = $1) as trip_count
		FROM Users u
		WHERE u.user_id = $1
	`, userIDInt).Scan(&score, &brakeScore, &accelScore, &firstName, &lastName, &tripCount)

	// 5. Handle query results
	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("No user found with ID %d", userIDInt)
			c.JSON(http.StatusNotFound, gin.H{
				"error": "User not found",
				"code":  "user_not_found",
			})
			return
		}
		log.Printf("Database error for user %d: %v", userIDInt, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to retrieve user score",
			"code":  "database_error",
		})
		return
	}

	// 6. Get ALL trip metrics for the user
	var allTrips []gin.H
	rows, err := db.Query(`
		SELECT 
			t.trip_id,
			t.start_time,
			tm.distance,
			tm.avg_velo,
			tm.max_velo,
			tm.brake_score,
			tm.accel_score,
			tm.trip_score,
			EXTRACT(EPOCH FROM (SELECT MAX((p->>'t')::timestamp) - MIN((p->>'t')::timestamp)
				FROM jsonb_array_elements(t.data) as p)) / 60 AS duration
		FROM Trips t
		JOIN TripsMetrics tm ON t.trip_id = tm.trip_id
		WHERE t.user_id = $1
		ORDER BY t.start_time DESC
	`, userIDInt)

	if err != nil {
		log.Printf("Error fetching trips: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to retrieve trip data",
			"code":  "database_error",
		})
		return
	}
	defer rows.Close()

	for rows.Next() {
		var tripID int
		var startTime string
		var distance, avgVelo, maxVelo, brakeScore, accelScore, tripScore, duration float64
		if err := rows.Scan(&tripID, &startTime, &distance, &avgVelo, &maxVelo,
			&brakeScore, &accelScore, &tripScore, &duration); err != nil {
			log.Printf("Error scanning trip row: %v", err)
			continue
		}
		allTrips = append(allTrips, gin.H{
			"trip_id":     tripID,
			"start_time":  startTime,
			"distance":    distance,
			"avg_speed":   avgVelo,
			"max_speed":   maxVelo,
			"brake_score": brakeScore,
			"accel_score": accelScore,
			"trip_score":  tripScore,
			"duration":    duration,
		})
	}

	if err = rows.Err(); err != nil {
		log.Printf("Error processing trips: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to process trip data",
			"code":  "data_processing_error",
		})
		return
	}

	// 7. Successful response with all score details
	log.Printf("Successfully fetched score and %d trips for user %d", len(allTrips), userIDInt)
	c.JSON(http.StatusOK, gin.H{
		"user_id":     userIDInt,
		"first_name":  firstName,
		"last_name":   lastName,
		"score":       score,
		"brake_score": brakeScore,
		"accel_score": accelScore,
		"trip_count":  tripCount,
		"all_trips":   allTrips,
		"calculation": gin.H{
			"formula": "Overall Score = (Average Speed × 0.16) + (Max Speed × 0.16) + (Distance × 0.16) + (Accel Score × 0.16) + (Brake Score × 0.16) + (Turns × 0.16)",
			"weights": gin.H{
				"average_speed": 0.16,
				"max_speed":     0.16,
				"distance":      0.16,
				"acceleration":  0.16,
				"braking":       0.16,
				"turns":         0.16,
			},
			"description": "Scores are calculated per trip and then averaged across all trips. " +
				"Braking and acceleration scores are based on severity of events during the trip. " +
				"Speed scores consider both average and maximum speeds.",
		},
		"status": "success",
	})
}
