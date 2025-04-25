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

	"drive_guard_server/util"
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

	claims, err := util.GetClaims(token)
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

func insertStartTrip(set *pointSet, claims *util.UserClaims, db *sql.DB) error {
	log.Println("STARTING TRIP INSERT")
	id, err := util.GetUserID(claims.Email, db)
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
	// $3 = json array representation of the points
	insertSTR := "INSERT INTO trips (user_id, start_time, data) VALUES ($1, $2, $3)"
	_, err = db.Exec(insertSTR, id, set.Start_time, jsonPoints)
	if err != nil {
		return err
	}

	if set.End {
		trip_id, err := util.GetTripID(id, db)
		if err != nil {
			return err
		}

		err = endTrip(id, trip_id, db)
		if err != nil {
			return err
		}
	}

	return nil
}

func updateExistingTrip(set *pointSet, claims *util.UserClaims, db *sql.DB) error {
	log.Println("UPDATING TRIP. END?:", set.End)
	id, err := util.GetUserID(claims.Email, db)
	if err != nil {
		return err
	}

	jsonPoints, err := json.Marshal(set.Points)
	if err != nil {
		return err
	}	

	updateSTR := "UPDATE trips SET data = data || $1::jsonb WHERE user_id = $2 ORDER BY start_time DESC LIMIT 1"
	_, err = db.Exec(updateSTR, jsonPoints, id)
	if err != nil {
		log.Println(err)
		return err
	}

	if set.End {
		trip_id, err := util.GetTripID(id, db)
		if err != nil {
			return err
		}

		err = endTrip(id, trip_id, db) 
		if err != nil {
			return err
		}
	}

	return nil
}

func endTrip(user_id, trip_id int, db *sql.DB) error {
	err := score.TripMetricsPasses(trip_id, db) 
	if err != nil {
		return err
	}

	err = score.UpdateUserScore(user_id, db)
	if err != nil {
		return err
	}
	return nil
}
