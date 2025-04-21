package score

import (
	"math" // maybe need

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

// Represents a driving habit
type drivingHabit struct {
	name        string
	weight      float64
	input       float64
	threshold   float64
	rawInput    float64
	decrementFn func(float64, float64) float64 // takes (rawInput, threshold) and returns input [0,1]
}

// Factory for new driving habits
func newHabit(name string, weight float64, threshold float64, rawInput float64, decrementFn func(float64, float64) float64) drivingHabit {
	return drivingHabit{
		name:        name,
		weight:      weight,
		threshold:   threshold,
		rawInput:    rawInput,
		decrementFn: decrementFn,
	}
}

// Sample decrement function (linear penalty)
func linearDecrement(rawInput, threshold float64) float64 {
	decrementFromInput := 0.2
	if rawInput <= threshold {
		return 1
	}
	return math.Max(0, 1-(decrementFromInput*(rawInput-threshold)))
}

// Calculates score. More habits can be easily added in the future
func calculateScore() float64 {

	// Replace these nums with a struct that contains number of occurences as well as the list of lists for waypoints ryan will pass
	numBreaks := 5.0
	numAccel := 3.0
	timeSpeeding := 20.0

	// Define all habits here — easy to add more
	habits := []drivingHabit{
		newHabit("Harsh Braking", 0.3, 2, numBreaks, linearDecrement),
		newHabit("Harsh Acceleration", 0.3, 2, numAccel, linearDecrement),
		newHabit("Speeding", 0.4, 10, timeSpeeding, linearDecrement),
		// Example of future addition:
		// newHabit("Phone Usage", 0.2, 5, phoneUsageTime, customDecrementFn),
	}

	// Calculate score
	totalWeighted := 0.0
	for i, h := range habits {
		habits[i].input = h.decrementFn(h.rawInput, h.threshold)
		totalWeighted += h.weight * habits[i].input
	}

	score := 1.0 - totalWeighted
	if score < 0 {
		score = 0
	}
	return score
}

// acrually ill be passed a struct with lists of lists in fields that contian, speeding, breaks, acceleration
// ryan will pass a speeding function where a list is passed containing lists of point in which they were speeding. so it will essentially be a list of lists where each elements if the points in which they were speeding. i can multiply by 5 to get total time spedeing because each point.
// make it so you get more penalized for speeding higher than if you were just going a few miles over the speeding
