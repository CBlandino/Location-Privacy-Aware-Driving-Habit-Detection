package insurance

import (
	"database/sql"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type UserScoreResponse struct {
	UserID       int       `json:"user_id"`
	FirstName    string    `json:"first_name"`
	LastName     string    `json:"last_name"`
	OverallScore float64   `json:"score"`
	BrakeScore   float64   `json:"brake_score"`
	AccelScore   float64   `json:"accel_score"`
	TripScore    float64   `json:"trip_score"`
	UpdatedAt    time.Time `json:"updated_at"`
}

func GetUserScore(c *gin.Context, db *sql.DB) {
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

	// 3. Database query
	log.Printf("Fetching comprehensive scores for user %d", userIDInt)
	var response UserScoreResponse
	var updatedAt sql.NullTime

	err = db.QueryRow(`
		SELECT 
			user_id,
			first_name,
			last_name,
			score,
			brake_score,
			accel_score,
			updated_at
		FROM Users 
		WHERE user_id = $1
	`, userIDInt).Scan(
		&response.UserID,
		&response.FirstName,
		&response.LastName,
		&response.OverallScore,
		&response.BrakeScore,
		&response.AccelScore,
		&updatedAt,
	)

	// Handle NULL updated_at
	if updatedAt.Valid {
		response.UpdatedAt = updatedAt.Time
	} else {
		response.UpdatedAt = time.Now()
	}

	// 4. Handle query results
	if err != nil {
		handleDatabaseError(c, userIDInt, err)
		return
	}

	// 5. Calculate trip score average (if needed)
	response.TripScore = (response.BrakeScore + response.AccelScore) / 2

	// 6. Successful response
	log.Printf("Successfully fetched scores for user %d", userIDInt)
	c.JSON(http.StatusOK, gin.H{
		"status":      "success",
		"user_id":     response.UserID,
		"first_name":  response.FirstName,
		"last_name":   response.LastName,
		"score":       response.OverallScore,
		"brake_score": response.BrakeScore,
		"accel_score": response.AccelScore,
		"trip_score":  response.TripScore,
		"updated_at":  response.UpdatedAt.Format(time.RFC3339),
	})
}

// Helper functions
func validateAuthHeader(c *gin.Context) gin.H {
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		log.Println("Missing authorization header")
		return gin.H{
			"error": "Authorization header required",
			"code":  "missing_auth_header",
		}
	}
	return nil
}

func validateUserID(userID string) (int, gin.H) {
	if userID == "" || userID == "null" {
		log.Println("Invalid user ID:", userID)
		return 0, gin.H{
			"error": "Valid user ID required",
			"code":  "invalid_user_id",
		}
	}

	userIDInt, err := strconv.Atoi(userID)
	if err != nil || userIDInt <= 0 {
		log.Println("Invalid user ID format:", userID)
		return 0, gin.H{
			"error": "User ID must be a positive integer",
			"code":  "invalid_id_format",
		}
	}
	return userIDInt, nil
}

func handleDatabaseError(c *gin.Context, userID int, err error) {
	if err == sql.ErrNoRows {
		log.Printf("No user found with ID %d", userID)
		c.JSON(http.StatusNotFound, gin.H{
			"error": "User not found",
			"code":  "user_not_found",
		})
		return
	}
	log.Printf("Database error for user %d: %v", userID, err)
	c.JSON(http.StatusInternalServerError, gin.H{
		"error":  "Failed to retrieve user scores",
		"code":   "database_error",
		"detail": err.Error(),
	})
}
