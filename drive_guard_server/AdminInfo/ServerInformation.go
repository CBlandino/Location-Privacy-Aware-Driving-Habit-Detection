package AdminInfo

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

type ServerInfo struct {
	ID      int    `json:"id"`
	BaseURL string `json:"base_url"`
	Port    string `json:"port"`
	APIKey  string `json:"api_key"`
}

func HandleServerInfo(c *gin.Context, db *sql.DB) {
	// Get server ID from the request parameters
	serverID := c.Query("server_id")
	
	// If no server ID is provided, use a default value like 1
	if serverID == "" {
		log.Println("No server ID provided, using default server")
		serverID = "1" // Default server ID
	}
	
	// Query the database for the specific server
	var serverInfo ServerInfo
	query := "SELECT id, base_url, port, api_key FROM server_information WHERE id = $1"
	
	err := db.QueryRow(query, serverID).Scan(
		&serverInfo.ID,
		&serverInfo.BaseURL,
		&serverInfo.Port,
		&serverInfo.APIKey,
	)
	
	if err == sql.ErrNoRows {
		log.Println("No server found with ID:", serverID)
		c.JSON(http.StatusNotFound, gin.H{"error": "Server not found"})
		return
	} else if err != nil {
		log.Println("Error querying server information:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve server information"})
		return
	}

	// Return the server information as JSON
	c.JSON(http.StatusOK, serverInfo)
}
