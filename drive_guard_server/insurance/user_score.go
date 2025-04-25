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

	// 4. Database query - updated to use Users table
	log.Printf("Fetching score for user %d", userIDInt)
	var score, brakeScore, accelScore float64
	var firstName, lastName string
	err = db.QueryRow(`
		SELECT score, brake_score, accel_score, first_name, last_name 
		FROM Users 
		WHERE user_id = $1
	`, userIDInt).Scan(&score, &brakeScore, &accelScore, &firstName, &lastName)

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

	// 6. Successful response
	log.Printf("Successfully fetched score for user %d", userIDInt)
	c.JSON(http.StatusOK, gin.H{
		"user_id":     userIDInt,
		"score":       score,
		"brake_score": brakeScore,
		"accel_score": accelScore,
		"first_name":  firstName,
		"last_name":   lastName,
		"status":      "success",
	})
}
