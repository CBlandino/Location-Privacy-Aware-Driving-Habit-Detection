package insurance

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetUserTrips(c *gin.Context, db *sql.DB) {
	// 1. Authentication check
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing Authorization header"})
		return
	}

	// 2. Get user ID from URL
	userID := c.Param("userId")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing user ID"})
		return
	}

	// 3. Get sort parameter
	sortBy := c.Query("sort")
	query := `
		SELECT trip_id, user_id, start_time, distance, duration, velocity
		FROM trips
		WHERE user_id = $1
	`

	// 4. Add sorting
	switch sortBy {
	case "distance":
		query += " ORDER BY distance DESC"
	default: // "recent"
		query += " ORDER BY start_time DESC"
	}

	// 5. Execute query
	rows, err := db.Query(query, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	defer rows.Close()

	// 6. Process results
	var trips []map[string]interface{}
	for rows.Next() {
		var tripID int
		var userID int
		var startTime string
		var distance float64
		var duration float64
		var velocity float64

		err := rows.Scan(&tripID, &userID, &startTime, &distance, &duration, &velocity)
		if err != nil {
			continue // Skip malformed rows
		}

		trips = append(trips, gin.H{
			"trip_id":    tripID,
			"user_id":    userID,
			"start_time": startTime,
			"distance":   distance,
			"duration":   duration,
			"velocity":   velocity,
		})
	}

	// 7. Return results
	c.JSON(http.StatusOK, trips)
}
