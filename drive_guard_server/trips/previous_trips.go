package trips 


import (
	"log"
	"net/http"

	"database/sql"
	_ "github.com/lib/pq"

	"github.com/gin-gonic/gin"

	"drive_guard_server/tokens"
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
	claims, err := tokens.GetClaims(token)
	if err != nil {
		c.JSON(http.StatusBadRequest, err)	
		log.Println("BAD REQUEST! :", err)
		return
	}
	log.Println("CLAIMS EMAIL:", claims.Email)

	id, err := getUserID(claims.Email, db)
	if err != nil {
		c.JSON(http.StatusBadRequest, err) 
		log.Println(err)
		return
	}

	// select the all of the timestamps and distances for a users trips
	querySTR := "SELECT start_time, distance, velocity FROM trips WHERE user_id = $1" 

	rows, err := db.Query(querySTR, id)
	if err != nil {
		log.Println(err) 
		c.JSON(http.StatusBadRequest, err)
		return
	}
	defer rows.Close() 

	// serialize the trips into the json response body
	trips := make([]PrevTrip, 0)
	for rows.Next() {
		var trip PrevTrip 
		if err := rows.Scan(&trip.TimeStamp, &trip.Distance, &trip.Velocity); err != nil {
			log.Println(err)
			c.JSON(http.StatusBadRequest, err)
			return
		}

		trips = append(trips, trip)
	}

	c.JSON(http.StatusOK, trips)
}



