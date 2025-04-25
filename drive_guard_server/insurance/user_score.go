package insurance

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetUserScore(c *gin.Context, db *sql.DB) {
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

	// 3. Query database for user score
	var score float64
	var updatedAt string
	err := db.QueryRow(`
		SELECT score, updated_at 
		FROM user_scores 
		WHERE user_id = $1
	`, userID).Scan(&score, &updatedAt)

	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "User score not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// 4. Return the score data
	c.JSON(http.StatusOK, gin.H{
		"score":      score,
		"updated_at": updatedAt,
		"user_id":    userID,
	})
}
