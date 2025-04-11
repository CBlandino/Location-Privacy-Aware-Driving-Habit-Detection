package score

import (

	//"math" // maybe need

	"database/sql"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
)

// come up with a mathemtical function i want for trip then implement into go
// linear weighted function where the inputs are the number of breaks / seconds spent speeding
// implement number of hard breaks, seconds spent speeding, number of times you suddenly accelerate
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

// struct for driving habits
type drivingHabit struct {
	weight float64 // weight
	input  float64 // input

	numHabits float64 // number of habits that occured
}

// constructor for driving habit, sets the weight and input
func newHabit(weight float64, numHabits float64) drivingHabit {
	return drivingHabit{
		weight:    weight,
		numHabits: numHabits,
	}
}

func calcuateScore(pointsData []float64) float64 {

	// purely for test, implement later. decrements score based on number of habits that occured
	var decrementFromInput = .2

	// driving habits
	var numBreaks float64
	var numAccel float64
	var timeSpeeding float64

	harshBreak := newHabit(0.3, numBreaks)
	harshAcceleration := newHabit(0.3, numAccel)
	speeding := newHabit(0.4, timeSpeeding)

	// thresholds for habits
	if numBreaks <= 2 {
		harshBreak.input = 1
	} else {
		harshBreak.input = 1 - (decrementFromInput * (numBreaks - 2))
	}

	if numAccel <= 2 {
		harshAcceleration.input = 1
	} else {
		harshAcceleration.input = 1 - (decrementFromInput * (numAccel - 2))
	}

	if timeSpeeding <= 10 {
		speeding.input = 1
	} else {
		speeding.input = 1 - (decrementFromInput * (timeSpeeding - 10))
	}

	// Calculate final score
	var totalWeighted float64
	habits := []drivingHabit{harshBreak, harshAcceleration, speeding}
	for _, habit := range habits {
		totalWeighted += habit.weight * habit.input
	}

	score := 1.0 - totalWeighted
	if score < 0 {
		score = 0
	}

	return score

}
