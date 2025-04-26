package AdminInfo

import (
	"database/sql"
	"log"
	"math/rand" // Import the math/rand package
	"time"

	"github.com/gin-gonic/gin"
)

// GenerateID generates a random ID
func GenerateID(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	seededRand := rand.New(rand.NewSource(time.Now().UnixNano())) // Use math/rand
	id := make([]byte, length)
	for i := range id {
		id[i] = charset[seededRand.Intn(len(charset))]
	}
	return string(id)
}

// HandleIDGeneration handles ID generation requests and saves the ID to the database
func HandleIDGeneration(c *gin.Context, db *sql.DB) {
	id := GenerateID(12) // Generate a 12-character ID

	// Insert the generated ID into the database
	_, err := db.Exec("INSERT INTO generated_ids (generated_id) VALUES ($1)", id)
	if err != nil {
		log.Println("Error inserting generated ID:", err)
		c.JSON(500, gin.H{"error": "Failed to save generated ID"})
		return
	}

	c.JSON(200, gin.H{"id": id})
}

// SetupIDRoutes registers the ID generator routes with Gin
func SetupIDRoutes(router *gin.Engine, db *sql.DB) {
	router.GET("/generate-id", func(c *gin.Context) {
		HandleIDGeneration(c, db)
	})
}
