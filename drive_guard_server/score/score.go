package score

import (
	"log"
	"math" // maybe need
	"net/http"

	"database/sql"

	_ "github.com/lib/pq"

	"github.com/gin-gonic/gin"

	"drive_guard_server/util"
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
func GetUserScore(c *gin.Context, db *sql.DB) {

	log.Println("FETCHING USER SCORE")

	// Attempt to verify the JWT that should be held within the Authorization header of the request
	token := c.GetHeader("Authorization")
	if token == "" {
		c.JSON(http.StatusBadRequest, "No Authorization header found on request")
		log.Println("No Authorization header found on request")
		return
	}

	claims, err := util.GetClaims(token)
	if err != nil {
		c.JSON(http.StatusBadRequest, err)
		log.Println("BAD REQUEST! :", err)
		return
	}

	log.Println("CLAIMS EMAIL:", claims.Email)

	// brake, acceleration, and speed severity
	var brakeSeverity, accelSeverity, speedSeverity int

	// change to correct query grabs
	query := `SELECT brake_severity, accel_severity, speed_severity FROM trips WHERE email=$1 ORDER BY timestamp DESC LIMIT 1`
	err = db.QueryRow(query, claims.Email).Scan(&brakeSeverity, &accelSeverity, &speedSeverity)
	if err != nil {
		log.Println("DB ERROR:", err)
		c.JSON(http.StatusInternalServerError, "Could not fetch trip data")
		return
	}

	// Use dummy flags just to simulate the threshold
	dummyFlags := make([]metricFlag, 5)
	for i := range dummyFlags {
		dummyFlags[i] = metricFlag{
			Severity: 1,
			Velo:     0,
			Accel:    0,
		}
	}
	breakingPass := metricPass{totalSeverity: brakeSeverity, flags: dummyFlags}
	accelPass := metricPass{totalSeverity: accelSeverity, flags: dummyFlags}
	speedingPass := metricPass{totalSeverity: speedSeverity, flags: dummyFlags}

	finalScore, brakeScore, accelScore, speedScore := takeInput(breakingPass, accelPass, speedingPass)

	c.JSON(http.StatusOK, gin.H{
		"totalScore":   finalScore * 100,
		"braking":      brakeScore * 100,
		"acceleration": accelScore * 100,
		"speedControl": speedScore * 100,
	})

}

//for second func that calculates score and updates
// can process the 30 seconds blocks of data at a time or wait till all blocks are done (go with wait till all blocks)

// argument is a map from string to int where each cell represents block of points, key will be long and lat, and pair will be time stamp

// Represents a driving habit
type metricData struct {
	name            string                 // Name of habit
	totalSeverity   int                    // Total severity of the trip, each severity data ranges from 0(no severity), 1(mild severity), 2(high severity)
	individSeverity int                    // Each individual points severity (not currently in use)
	threshold       int                    // Threshold for serverity, based off the length of the trip
	score           float64                // Individual habits score
	decrementFn     func(int, int) float64 // Takes (severity, threshold) and returns input [0,1]
}

// Factory for new driving habits
func newHabit(name string, totalSeverity int, threshold int, decrementFn func(int, int) float64) metricData {
	score := decrementFn(totalSeverity, threshold)
	return metricData{
		name:          name,
		totalSeverity: totalSeverity,
		threshold:     threshold,
		score:         score,
		decrementFn:   decrementFn,
	}
}

// Calculates individual score depending on the threshold
func linearDecrement(totalSeverity, threshold int) float64 {
	// If severity is over threshold, decrement score by .1, this is only for testing, change in future
	decrementFromInput := 0.1

	if totalSeverity <= threshold {
		return 1
	}
	return math.Max(0, 1-(decrementFromInput*float64(totalSeverity-threshold)))
}

// Takes metricPass (1 for each habit) and calculates their individual score, as well as a final averaged score
func takeInput(breakingPass metricPass, accelerationPass metricPass, speedingPass metricPass) (float64, float64, float64, float64) {

	habits := []metricData{
		newHabit("Harsh Breaking", breakingPass.totalSeverity, int(.15*float64(5*len(breakingPass.flags))), linearDecrement),
		newHabit("Harsh Acceleration", accelerationPass.totalSeverity, int(.15*float64(5*len(accelerationPass.flags))), linearDecrement),
		newHabit("Speeding", speedingPass.totalSeverity, int(.15*float64(5*len(speedingPass.flags))), linearDecrement),
	}

	var total float64
	for _, h := range habits {
		log.Printf("%s Score: %.2f\n", h.name, h.score)
		total += h.score
	}

	finalScore := total / float64(len(habits))
	log.Printf("Final Average Score: %.2f\n", finalScore)
	//return the total score for the trip, the total score for harsh braking, accelration and
	return finalScore, habits[0].score, habits[1].score, habits[2].score
}

// threshold is 15% of trips length .15 * (5 * number of points)
// 24 is max the threshold can be for 1 minute

// make it so you get more penalized for speeding higher than if you were just going a few miles over the speeding

// take ryans metric pass struct and create a score for each individual habit and then create an average score for that trip, do this for every trip
// take one score from the first trip, then from every trip after calculate the acerage score which will be in users table
// threshold will be 15% of the trips length
