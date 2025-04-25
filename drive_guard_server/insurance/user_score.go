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

	// 4. Database query
	log.Printf("Fetching score for user %d", userIDInt)
	var score float64
	var updatedAt string
	err = db.QueryRow(`
		SELECT score, updated_at 
		FROM user_scores 
		WHERE user_id = $1
	`, userIDInt).Scan(&score, &updatedAt)

	// 5. Handle query results
	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("No score found for user %d", userIDInt)
			c.JSON(http.StatusNotFound, gin.H{
				"error": "User score not found",
				"code":  "score_not_found",
			})
			return
		}
		log.Printf("Database error for user %d: %v", userIDInt, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to retrieve score",
			"code":  "database_error",
		})
		return
	}

	// 6. Successful response
	log.Printf("Successfully fetched score for user %d", userIDInt)
	c.JSON(http.StatusOK, gin.H{
		"user_id":    userIDInt,
		"score":      score,
		"updated_at": updatedAt,
		"status":     "success",
	})
}
