package insurance

import (
	"database/sql"

	_ "github.com/lib/pq"

	"net/http"

	"drive_guard_server/util"

	"github.com/gin-gonic/gin"
)

func SearchUsers(c *gin.Context, db *sql.DB) {
	// Extract the Authorization header
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing Authorization header"})
		return
	}

	// Parse the JWT token and extract claims
	claims, err := util.GetClaims(authHeader)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
		return
	}

	// Check if the user has admin role
	if claims.Role != "admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "You must be an admin to perform this action"})
		return
	}

	// Extract the query parameter
	query := c.Query("query")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing search query"})
		return
	}

	rows, err := db.Query(`
		SELECT user_id, first_name, last_name, email, role 
		FROM users 
		WHERE first_name ILIKE '%' || $1 || '%' 
		OR last_name ILIKE '%' || $1 || '%'`, query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database query failed"})
		return
	}
	defer rows.Close()

	var users []map[string]interface{}
	for rows.Next() {
		var id int
		var firstName, lastName, email, role string
		if err := rows.Scan(&id, &firstName, &lastName, &email, &role); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read user data"})
			return
		}
		users = append(users, gin.H{
			"user_id":    id,
			"first_name": firstName,
			"last_name":  lastName,
			"email":      email,
			"role":       role,
		})
	}

	c.JSON(http.StatusOK, users)
}
