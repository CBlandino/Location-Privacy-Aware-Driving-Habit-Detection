package AdminInfo

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

type ServerInfo struct { // this struct function to print out a server info board
	ID      int    `json:"id"`
	BaseURL string `json:"base_url"`
	Port    string `json:"port"`
	APIKey  string `json:"api_key"`
}

func HandleServerInfo(c *gin.Context, db *sql.DB) { //server infpo requests

	var serverInfo ServerInfo //data  base is querid for sever info
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

func SetupServerRoutes(router *gin.Engine, db *sql.DB) {
	// Original server-info endpoint
	router.GET("/server-info", func(c *gin.Context) {
		HandleServerInfo(c, db)
	})

	// New test endpoint for server information
	router.GET("/server-test", func(c *gin.Context) {
		// This endpoint doesn't access the database
		c.JSON(200, gin.H{
			"status":  "success",
			"message": "Server info test endpoint is working"})
	})
}
