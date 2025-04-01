package main 


import (
	"log"
	"net/http"

	"database/sql"
	_ "github.com/lib/pq"

	"github.com/gin-gonic/gin"
)

func previous_trips(c *gin.Context, db *sql.DB) {
	// select all of the users trips in the trips table.
	// dont think distance information has to be sent back unless they click on a trip

	// Attempt to verify the JWT that should be held within the Authorization header of the request
	token := c.GetHeader("Authorization")
	if token == "" {
		c.JSON(http.StatusBadRequest, "No Authorization header found on request")
		log.Println("No Authorization header found on request")
		return
	}
	claims, err := getClaims(token)
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

	querySTR := "SELECT start_time, distance FROM trips WHERE user_id = $1" 

	rows, err := db.Query(querySTR, id)
	if err != nil {
		log.Println(err) 
		c.JSON(http.StatusBadRequest, err)
		return
	}

	defer rows.Close() 

	trips := make([]PrevTrip, 0)
	for rows.Next() {
		var trip PrevTrip 
		if err := rows.Scan(&trip.TimeStamp, &trip.Distance); err != nil {
			log.Println(err)
			c.JSON(http.StatusBadRequest, err)
			return
		}

		trips = append(trips, trip)
	}

	c.JSON(http.StatusOK, trips)
}


type PrevTrip struct {
	TimeStamp string `json:"timestamp"`
	Distance float32 `json:"distance"`
}
