package insurance

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type Trip struct {
	TripID     int       `json:"trip_id"`
	UserID     int       `json:"user_id"`
	StartTime  time.Time `json:"start_time"`
	Duration   float64   `json:"duration"`
	Distance   float64   `json:"distance"`
	AvgSpeed   float64   `json:"average_speed"`
	MaxSpeed   float64   `json:"max_speed"`
	BrakeScore float64   `json:"brake_score"`
	AccelScore float64   `json:"accel_score"`
	TripScore  float64   `json:"trip_score"`
}

func GetUserTrips(c *gin.Context, db *sql.DB) {
	// 1. Authentication and validation
	if err := validateAuthHeader(c); err != nil {
		c.JSON(http.StatusUnauthorized, err)
		return
	}

	// 2. Validate and parse user ID
	userIDInt, err := validateUserID(c.Param("userId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, err)
		return
	}

	// 3. Validate sort parameter
	sortBy := validateSortParam(c.DefaultQuery("sort", "recent"))

	// 4. Build and execute query
	query := buildTripQuery(sortBy)
	ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
	defer cancel()

	rows, err := db.QueryContext(ctx, query, userIDInt)
	if err != nil {
		log.Printf("Database query error for user %d: %v", userIDInt, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":  "Failed to retrieve trips",
			"code":   "database_error",
			"detail": err.Error(),
		})
		return
	}
	defer rows.Close()

	// 5. Process results
	trips, err := processTripRows(rows)
	if err != nil {
		log.Printf("Trip processing error for user %d: %v", userIDInt, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to process trips",
			"code":  "data_processing_error",
		})
		return
	}

	// 6. Successful response
	log.Printf("Returning %d trips for user %d", len(trips), userIDInt)
	c.JSON(http.StatusOK, gin.H{
		"user_id": userIDInt,
		"count":   len(trips),
		"trips":   trips,
		"status":  "success",
	})
}

// Helper functions
func validateSortParam(sortBy string) string {
	if sortBy != "recent" && sortBy != "distance" {
		return "recent"
	}
	return sortBy
}

func buildTripQuery(sortBy string) string {
	query := `
		SELECT 
			t.trip_id, 
			t.user_id, 
			t.start_time, 
			EXTRACT(EPOCH FROM (
				SELECT MAX((p->>'t')::timestamp) - MIN((p->>'t')::timestamp
				FROM jsonb_array_elements(t.data) as p
			)) / 60 AS duration,
			tm.distance,
			COALESCE(tm.avg_velo, 0) AS avg_speed,
			COALESCE(tm.max_velo, 0) AS max_speed,
			COALESCE(tm.brake_score, 0) AS brake_score,
			COALESCE(tm.accel_score, 0) AS accel_score,
			COALESCE(tm.trip_score, 0) AS trip_score
		FROM Trips t
		JOIN TripsMetrics tm ON t.trip_id = tm.trip_id
		WHERE t.user_id = $1
	`

	switch sortBy {
	case "distance":
		return query + " ORDER BY tm.distance DESC"
	default:
		return query + " ORDER BY t.start_time DESC"
	}
}

func processTripRows(rows *sql.Rows) ([]Trip, error) {
	var trips []Trip
	for rows.Next() {
		var t Trip
		err := rows.Scan(
			&t.TripID,
			&t.UserID,
			&t.StartTime,
			&t.Duration,
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
	return trips, rows.Err()
}
