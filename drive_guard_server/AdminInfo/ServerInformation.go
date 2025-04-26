package AdminInfo

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

// ServerInfo represents a server information record
type ServerInfo struct {
	ID      int    `json:"id"`
	BaseURL string `json:"base_url"`
	Port    string `json:"port"`
	APIKey  string `json:"api_key"`
}

// HandleServerInfo handles server information requests
func HandleServerInfo(c *gin.Context, db *sql.DB) {
	// Query the database for server information
	var serverInfo ServerInfo
	err := db.QueryRow("SELECT id, base_url, port, api_key FROM server_information LIMIT 1").
		Scan(&serverInfo.ID, &serverInfo.BaseURL, &serverInfo.Port, &serverInfo.APIKey)

	if err != nil {
		log.Println("Error querying server information:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve server information"})
		return
	}

	// Return the server information as JSON
	c.JSON(http.StatusOK, serverInfo)
}

// SetupServerRoutes registers the Server Information routes with Gin
func SetupServerRoutes(router *gin.Engine, db *sql.DB) {
	router.GET("/server-info", func(c *gin.Context) {
		HandleServerInfo(c, db)
	})
}
