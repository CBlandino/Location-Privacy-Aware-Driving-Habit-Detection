package main

import (
    "log"
    "github.com/gin-gonic/gin"
    "net/http"
)
// url/trip is for reporting delta points



func transmitPoints(c *gin.Context) {
    log.Println("RECIEVING POINTS")


    var data map[string]interface{}

    if err := c.ShouldBindJSON(&data); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        log.Println(err)
        return
    }

    
    for key, data := range data {
        log.Println("Key:", key, "Data:", data) 
    }

    c.Status(http.StatusOK)
}


