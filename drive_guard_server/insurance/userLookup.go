package insurance

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"strconv"

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

	// 2. JWT claims parsing
	claims, err := util.GetClaims(authHeader)
	if err != nil {
		log.Printf("JWT parsing error: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":  "Invalid token",
			"detail": err.Error(),
		})
		return
	}

	// 3. Role validation
	if claims.Role != "admin" && claims.Role != "insurance" {
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

	// Check if query is numeric (potential ID)
	var rows *sql.Rows
	if id, errr := strconv.Atoi(query); errr == nil {
		// Search by ID
		rows, err = db.Query(`
			SELECT user_id, first_name, last_name, email, class 
			FROM users 
			WHERE user_id = $1`, id)
	} else {
		// Search by name or email
		rows, err = db.Query(`
			SELECT user_id, first_name, last_name, email, class 
			FROM users 
			WHERE first_name ILIKE $1 
			OR last_name ILIKE $1
			OR email ILIKE $1`,
			"%"+query+"%")
	}

	if err != nil {
		log.Printf("Database query error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":  "Database operation failed",
			"detail": err.Error(),
		})
		return
	}
	defer rows.Close()

	// Results processing
	var users []map[string]interface{}
	for rows.Next() {
		var id int
		var firstName, lastName, email, userClass string
		if err := rows.Scan(&id, &firstName, &lastName, &email, &userClass); err != nil {
			log.Printf("Row scanning error: %v", err)
			continue
		}
		users = append(users, gin.H{
			"user_id":    id,
			"first_name": firstName,
			"last_name":  lastName,
			"email":      email,
			"role":       userClass,
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

	// Success response
	c.JSON(http.StatusOK, gin.H{
		"count": len(users),
		"users": users,
	})
}
