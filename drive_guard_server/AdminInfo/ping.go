package AdminInfo

import (
	"github.com/gin-gonic/gin"
)

// HandlePing handles health check requests
func HandlePing(c *gin.Context) {
	c.JSON(200, gin.H{"message": "pong"})
}

// SetupPingRoutes registers the Ping routes with Gin
func SetupPingRoutes(router *gin.Engine) {
	router.GET("/ping", HandlePing)
}
