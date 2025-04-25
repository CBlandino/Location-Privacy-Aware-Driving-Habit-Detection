package trips 


import (
	"log"
	"net/http"

	"database/sql"
	_ "github.com/lib/pq"

	"github.com/gin-gonic/gin"

	"drive_guard_server/util"
)

func Previous_trips(c *gin.Context, db *sql.DB) {
	// select all of the users trips in the trips table.

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

	id, err := util.GetUserID(claims.Email, db)
	if err != nil {
		c.JSON(http.StatusBadRequest, err) 
		log.Println(err)
		return
	}

	// select the all of the timestamps and distances for a users trips
	querySTR := "SELECT" +  
		" trips.start_time," + 
		" tripsmetrics.distance," +
		" tripsmetrics.avg_velocity," +
		" tripsmetrics.max_velocity," +
		" tripsmetrics.brake_score" +
		" tripsmetrics.accel_score" + 
		" tripsmetrics.trip_score" + 
		" FROM trips JOIN tripmetrics ON trips.trip_id = tripsmetrics.trip_id WHERE trips.user_id = $1" 

	rows, err := db.Query(querySTR, id)
	if err != nil {
		log.Println("failed to fetch previous trips data from the db", err) 
		c.JSON(http.StatusBadRequest, err)
		return
	}
	defer rows.Close() 

	// serialize the trips into the json response body
	trips := make([]PrevTrip, 0)
	for rows.Next() {
		var trip PrevTrip 
		if err := rows.Scan(&trip.TimeStamp, &trip.Distance, &trip.Velocity, &trip.MaxVelocity, &trip.BrakeScore, &trip.AccelScore, &trip.TripScore); err != nil {
			log.Println("failed to scan previous trip from db", err)
			c.JSON(http.StatusBadRequest, err)
			return
		}

		trips = append(trips, trip)
	}

	c.JSON(http.StatusOK, trips)
}

// struct for previous trip response to the client
type PrevTrip struct {
	// trip starting time
	TimeStamp string `json:"timestamp"`
	// total distance travelled during the trip
	Distance float64 `json:"distance"`
	// average velocity for the trip 
	Velocity float64 `json:"velocity"`
	// max trip velocity
	MaxVelocity float64 `json:"max_velocity"`
	// brake score for the trip
	BrakeScore float64 `json:"brake_score"`
	// accel score for the trip
	AccelScore float64 `json:"accel_score"`
	// total trip score
	TripScore float64 `json:"trip_score"`
}


