package AdminInfo

import (
	"github.com/gin-gonic/gin"
)


func HandlePing(c *gin.Context) {//this fuctios to handle ping requests
	c.JSON(200, gin.H{"message": "pong"})
}


func SetupPingRoutes(router *gin.Engine) {//this setups ping route regis
	router.GET("/ping", HandlePing)}
