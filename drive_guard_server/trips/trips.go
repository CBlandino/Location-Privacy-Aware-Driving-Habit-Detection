package trips

import (
    "log"
	"slices"
    "net/http"	
	"encoding/json"
	// "math"

    "database/sql"
	_ "github.com/lib/pq"
    "github.com/gin-gonic/gin"

	"drive_guard_server/tokens"
	"drive_guard_server/score"
)

func TransmitPoints(c *gin.Context, db *sql.DB) {
    log.Println("RECIEVING POINTS")

	set := new(pointSet)

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

	// bind the trip data into point set struct
    if err := c.ShouldBindJSON(&set); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        log.Println(err)
        return
    }

	// the points are recieved in reverse order. reorder them before db insertion 
	slices.Reverse(set.Points)


	log.Println("SET:")
	log.Println("AUTH HEADER:", token)
	log.Println("Start:", set.Start)
	log.Println("END:", set.End)
	log.Println("NUM OF POINTS:", len(set.Points))

	// log.Println("POINTS:") 
	//
	// for _, p := range set.Points {
	// 	log.Println("POINT:", p.Order)
	//
	// 	log.Println("LAT:", p.Lat, "LONG:", p.Long)
	//
	// 	log.Println("TIME:", p.Timestamp)
	//
	// 	log.Println()
	// }

	if set.Start {
		//insertStartTrip
		err = insertStartTrip(set, claims, db)
	} else {
		//updateExistingTrip
		err = updateExistingTrip(set, claims, db)
	}
	if err != nil {
		c.JSON(http.StatusBadRequest, err) 
		log.Println(err)
		return
	}
    
    c.Status(http.StatusAccepted)
}

func insertStartTrip(set *pointSet, claims *tokens.UserClaims, db *sql.DB) error {
	log.Println("STARTING TRIP INSERT")
	id, err := getUserID(claims.Email, db)
	if err != nil {
		return err
	}

	//Serialize the delta points into json array form
	jsonPoints, err := json.Marshal(set.Points) 
	if err != nil {
		return err
	}

	// $1 = user_id 
	// $2 = trip start timestamp 
	// $3 = boolean value for if the trip is still in progress
	// $4 = json array representation of the points
	insertSTR := "INSERT INTO trips (user_id, start_time, done, data) VALUES ($1, $2, $3, $4)"
	_, err = db.Exec(insertSTR, id, set.Start_time, set.End, jsonPoints)
	if err != nil {
		return err
	}

	if set.End {
		trip_id, err := getTripID(id, db)
		if err != nil {
			return err
		}

		err = score.TripMetricsPasses(trip_id, db)
		if err != nil {
			return err
		}
	}

	return nil
}

func updateExistingTrip(set *pointSet, claims *tokens.UserClaims, db *sql.DB) error {
	log.Println("UPDATING TRIP. END?:", set.End)
	id, err := getUserID(claims.Email, db)
	if err != nil {
		return err
	}

	jsonPoints, err := json.Marshal(set.Points)
	if err != nil {
		return err
	}	

	updateSTR := "UPDATE trips SET data = data || $1::jsonb, done = $2 WHERE user_id = $3 AND done = FALSE"
	_, err = db.Exec(updateSTR, jsonPoints, set.End, id)
	if err != nil {
		log.Println(err)
		return err
	}

	if set.End {
		trip_id, err := getTripID(id, db)
		if err != nil {
			return err
		}

		err = score.TripMetricsPasses(trip_id, db)
		if err != nil {
			return err
		}
	}

	return nil
}

func getUserID(claimsEmail string, db *sql.DB) (int, error) {
	var id int 
	row := db.QueryRow("SELECT user_id FROM users WHERE email = $1", claimsEmail)
	if err := row.Scan(&id); err != nil {
		return -1, err
	}

	return id, nil
}

func getTripID(userID int, db *sql.DB) (int, error) {
	var id int 
	row := db.QueryRow("SELECT trip_id FROM trips WHERE user_id = $1 ORDER BY start_time DESC LIMIT 1", userID)

	if err := row.Scan(&id); err != nil {
		return -1, err
	}

	return id, nil
}
