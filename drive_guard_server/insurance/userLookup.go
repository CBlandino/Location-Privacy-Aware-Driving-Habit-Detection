package insurance

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"

	"drive_guard_server/util"

	"github.com/gin-gonic/gin"
)

func SearchUsers(c *gin.Context, db *sql.DB) {
	// 1. Authorization header check
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing Authorization header"})
		return
	}

	// 2. JWT claims parsing with better error handling
	claims, err := util.GetClaims(authHeader)
	if err != nil {
		log.Printf("JWT parsing error: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":  "Invalid token",
			"detail": err.Error(),
		})
		return
	}

	// 3. Enhanced role validation
	allowedRoles := map[string]bool{
		"admin":     true,
		"insurance": true,
	}
	if !allowedRoles[claims.Role] {
		c.JSON(http.StatusForbidden, gin.H{
			"error":  "Insufficient permissions",
			"detail": fmt.Sprintf("Role '%s' not authorized", claims.Role),
		})
		return
	}

	// 4. Query parameter validation
	query := c.Query("query")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Search query cannot be empty"})
		return
	}

	// 5. Database query with improved error handling
	rows, err := db.Query(`
		SELECT user_id, first_name, last_name, email, role 
		FROM users 
		WHERE first_name ILIKE $1 
		OR last_name ILIKE $1`,
		"%"+query+"%") // Proper parameterization

	if err != nil {
		log.Printf("Database query error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":  "Database operation failed",
			"detail": err.Error(),
		})
		return
	}
	defer rows.Close()

	// 6. Results processing
	var users []map[string]interface{}
	for rows.Next() {
		var id int
		var firstName, lastName, email, role string
		if err := rows.Scan(&id, &firstName, &lastName, &email, &role); err != nil {
			log.Printf("Row scanning error: %v", err)
			continue // Skip bad rows instead of failing entire request
		}
		users = append(users, gin.H{
			"user_id":    id,
			"first_name": firstName,
			"last_name":  lastName,
			"email":      email,
			"role":       role,
		})
	}

	if err := rows.Err(); err != nil {
		log.Printf("Rows iteration error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":  "Data processing error",
			"detail": err.Error(),
		})
		return
	}

	// 7. Success response
	c.JSON(http.StatusOK, gin.H{
		"count": len(users),
		"users": users,
	})
}
