package main


import (
    "log"
    "github.com/gin-gonic/gin"
)

var addr string = "localhost:8080"

func main() {
    log.Println("STARTING SERVER")
    
    server := gin.Default()
    server.POST("/signup", signupUser) 
    server.POST("/login", loginUser)

    server.Run(addr)
}


