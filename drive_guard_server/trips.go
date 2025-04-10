package main

import (
    "log"
	"errors"
	"strings"
	"slices"
    "net/http"	
	"encoding/json"
	"math"

    "database/sql"
	_ "github.com/lib/pq"
	"github.com/golang-jwt/jwt"
    "github.com/gin-gonic/gin"
)


type pointSet struct {
	Start bool `json:"isStart"`
	End bool `json:"isEnd"`
	Start_time string `json:"start_time"`
	Elapsed_time int `json:"elapsed_time"`
	Points []point `json:"delta_points"`
}

type point struct {
	Lat int `json:"dlat"`
	Long int `json:"dlon"`
	Timestamp string `json:"t"`
	Order int `json:"p"`
	Velo float64 `json:"v"`
}

func transmitPoints(c *gin.Context, db *sql.DB) {
    log.Println("RECIEVING POINTS")

	set := new(pointSet)

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

func insertStartTrip(set *pointSet, claims *UserClaims, db *sql.DB) error {
	log.Println("STARTING TRIP INSERT")
	id, err := getUserID(claims.Email, db)
	if err != nil {
		return err
	}


	var distanceSet float64 = 0.0
	for _, p := range set.Points {
		d := getDistance(&p)
		distanceSet += d
		// velocity = distance / time. 0.00138 = 5 seconds(point capture interval) in hours
		p.Velo = d / 0.00138
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
	// $5 = total accumulated distance thus far, in miles
	insertSTR := "INSERT INTO trips VALUES (DEFAULT, $1, $2, $3, $4, $5)"
	_, err = db.Exec(insertSTR, id, set.Start_time, set.End, jsonPoints, distanceSet)
	if err != nil {
		return err
	}

	return nil
}

func updateExistingTrip(set *pointSet, claims *UserClaims, db *sql.DB) error {
	log.Println("UPDATING TRIP. END?:", set.End)
	id, err := getUserID(claims.Email, db)
	if err != nil {
		return err
	}

	var distanceSet float64 = 0.0
	for _, p := range set.Points {
		d := getDistance(&p)
		distanceSet += d
		// velocity = distance / time. 0.00138 = 5 seconds(point capture interval) in hours
		p.Velo = d / 0.00138
	}

	jsonPoints, err := json.Marshal(set.Points)
	if err != nil {
		return err
	}	

	updateSTR := "UPDATE trips SET data = data || $1::jsonb, distance = distance + $2, done = $3 WHERE user_id = $4 AND done = FALSE"
	_, err = db.Exec(updateSTR, jsonPoints, distanceSet, set.End, id)
	if err != nil {
		log.Println(err)
		return err
	}

	return nil
}

// function that passes over all of the points in a transmitted point set prior to their inclusion in the db 
// we can calculate distance on the set here, as well as any other metrics we wanted to/needed to
func getDistance(p *point) float64 {

	var totalDist float64 = 0.0

	// radius of the earth in miles (6371km)
	const R float64 = 3958.756 
	// using beta approximation of 1 until implementation of R points is done
	const Beta float64 = 1.0

	//running accumulator for the haversine distance between points for every point in the batch

	dLat := (float64(p.Lat) * 0.000001) * (math.Pi / 180.0)
	dLong := (float64(p.Long) * 0.000001) * (math.Pi / 180.0)

	lat_over2 := dLat / 2.0
	lat_sin := math.Sin(lat_over2)
	lat_squared := math.Pow(lat_sin, 2)

	long_over2 := dLong / 2.0 
	long_sin := math.Sin(long_over2) 
	long_squared := math.Pow(long_sin, 2)

	a := lat_squared + Beta * long_squared
	c := 2.0 * math.Atan2(math.Sqrt(a), math.Sqrt(1.0 - a)) 
	totalDist += R * c

	//total distance for the trip
	log.Println(totalDist)

	return totalDist
}


func getUserID(claimsEmail string, db *sql.DB) (int, error) {
	var id int 
	row := db.QueryRow("SELECT user_id FROM users WHERE email = $1", claimsEmail)
	if err := row.Scan(&id); err != nil {
		return -1, err
	}

	return id, nil
}


func getClaims(tokenStr string) (*UserClaims, error) {
	// split "Bearer" off the header string
	splt := strings.Split(tokenStr, " ")
	if len(splt) != 2 && splt[0] != "Bearer" {
		return nil, errors.New("Invalid Authorization header format")
	}

	tokenStr = splt[1]
	claims := new(UserClaims)
	claims.Email = "test"
	// verify the integrity of the JWT and parse its claims into the claims struct (UserClaims type from auth.go)
	tok, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (any, error) {
		return signingKey, nil
	})
	if err != nil {
		log.Fatal(err)
		return nil, err
	}

	log.Println(tok)

	return claims, nil
}


