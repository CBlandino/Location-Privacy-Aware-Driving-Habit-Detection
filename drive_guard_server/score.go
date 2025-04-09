package main

import (

	//"math" // maybe need

	"database/sql"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
)

// come up with a mathemtical function i want for trip then implement into go
// linear weighted function where the inputs are the number of breaks / seconds spent speeding
// implement number of hard breaks, seconds spent speeding, number of times you sudden acceleration
// maybe stick score in user table, can get user by looking up email for user

// score is calculated off first trip then every subsequent trip changes that first score
// steps algorithm will take, input, output, etc

// (first func) when app calls score sever returns score by doing a database querery
// (second func) separeate function for the trip page to call on everytime it gets a new trip to update score, this func will recieve all points and data from phone

// for first function
func getUserScore(c *gin.Context, db *sql.DB) {

}

//for second func that calculates score and updates
// can process the 30 seconds blocks of data at a time or wait till all blocks are done (go with wait till all blocks)

// argument is a map from string to int where each cell represents block of points, key will be long and lat, and pair will be time stamp
func cacluateScore(pointsData []map[string]int) {

}
