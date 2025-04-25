package score

import (
	"log"
	"math"
	"net/http"

	"database/sql"

	_ "github.com/lib/pq"

	"github.com/gin-gonic/gin"

	"drive_guard_server/util"
)

func GetUserScore(c *gin.Context, db *sql.DB) {

	log.Println("FETCHING USER SCORE")

	// Attempt to verify the JWT that should be held within the Authorization header of the request
	token := c.GetHeader("Authorization")
	if token == "" {
		c.JSON(http.StatusBadRequest, "No Authorization header found on request")
		log.Println("No Authorization header found on request")
		return
	}

	// parse users claims out of the jwt
	claims, err := util.GetClaims(token)
	if err != nil {
		c.JSON(http.StatusBadRequest, err)
		log.Println("BAD REQUEST! :", err)
		return
	}

	log.Println("CLAIMS EMAIL:", claims.Email)

	// fetch score values from the db
	var bScore, aScore, Score float64
	qString := "SELECT brake_score, accel_score, score FROM users WHERE email = $1"
	row := db.QueryRow(qString, claims.Email)
	if err := row.Scan(&bScore, &aScore, &Score); err != nil {
		log.Println("failed to fetch users score from db", err.Error())
		c.JSON(http.StatusInternalServerError, err)
		return
	}

	// respond with score values
	c.JSON(http.StatusOK, gin.H{
		"totalScore": Score, 
		"braking" : bScore, 
		"acceleration": aScore,
	})
}



// takes metrics data for a trip and calculates 
// tripScore float64 
// accelScore float64 
// brakeScore float64
func scoreTrip(tripMetrics *metrics) (float64, float64, float64) {
	log.Println("CALCULATING TRIP SCORE")
	// WEIGHTS
	// p1 = avergage speed
	const P1W float64 = 0.2
	// p2 = max speed 
	const P2W float64 = 0.2
	// p3 = average daily distance (coming soon)
	const P3W float64 = 0.2
	// p4 = acceleration severity
	const P4W float64 = 0.2
	// p5 braking 
	const P5W float64 = 0.2
	// p6 abrupt turns (coming soon)
	const P6W float64 = 0.2

	p1v := func() float64 {
		avgv := tripMetrics.avg_velo
		if avgv >= 60.0 {
			return 0.0
		} else if 10.0 <= avgv && avgv <= 20.0 {
			return 0.5 * (1.0 - math.Cos(math.Pi * (avgv - 10.0) / 10.0))
		} else if 20.0 < avgv && avgv < 40.0 {
			return 1.0
		} else if 40.0 <= avgv && avgv <= 50.0 {
			return 0.5 * (1.0 + math.Cos(math.Pi * (avgv - 40.0) / 10.0))
		} else {
			return 0.0
		}
	}

	p2v := func() float64 {
		maxv := tripMetrics.max_velo
		if maxv > 65 {
			return 0.0
		} else {
			return 1
		}
	}

	p3v := func() float64 {
		return 1.0
	}

	p4v := func() float64 {
		sev := tripMetrics.accel_sev
		length := tripMetrics.trip_length

		// calculates how much of the trip was spent with high severity
		percentSev := float64(sev) / float64(length)
		if percentSev >= 1.0 {
			return 0.0
		}
		// invert the percentage 
		return 1.0 - percentSev
	}

	p5v := func() float64 {
		sev := tripMetrics.accel_sev
		length := tripMetrics.trip_length

		// calculates how much of the trip was spent with high severity
		percentSev := float64(sev) / float64(length)
		if percentSev >= 1.0 {
			return 0.0
		}
		// invert the percentage 
		return 1.0 - percentSev
	}

	p6v := func() float64 {
		return 1.0
	}

	pList := make([]subScore, 0)
	pList = append(pList, subScore{p1v(), P1W})
	pList = append(pList, subScore{p2v(), P2W})
	pList = append(pList, subScore{p3v(), P3W})
	pList = append(pList, subScore{p4v(), P4W})
	pList = append(pList, subScore{p5v(), P5W})
	pList = append(pList, subScore{p6v(), P6W})

	score := 0.0
	for _, param := range pList {
		score += (param.val * param.weight)
	}

	log.Println("trip score:", score)
	log.Println("accel score:", pList[3].val)
	log.Println("brake score:", pList[4].val)

	return score, pList[3].val, pList[4].val
}

func UpdateUserScore(user_id int, db *sql.DB) error {

	log.Println("User Score update triggered: userID =", user_id)

	// fetch all of the users trips from the db
	qString := "SELECT brake_score, accel_score, trip_score FROM tripsmetrics JOIN trips ON trips.trip_id = tripsmetrics.trip_id WHERE trips.user_id = $1" 
	rows, err := db.Query(qString, user_id) 
	if err != nil {
		log.Println("failed to query all of a users trips!", err.Error())
		return err
	}
	defer rows.Close()

	//accumulate all score values
	rowsCount := 0
	avgBrake := 0.0 
	avgAccel := 0.0
	avgScore := 0.0 
	for rows.Next() {
		var b, a, s float64	
		if err := rows.Scan(&b, &a, &s); err != nil {
			log.Println("failed to scan trip score values", err.Error())
			return err
		}

		avgBrake += b
		avgAccel += a 
		avgScore += s
		rowsCount++
	}

	// this should be impossible... but if u query no user trips, dont update their score
	if rowsCount == 0 {
		log.Println("ALERT: no trips found for this user...")
		return nil
	}

	// calculate score averages
	avgBrake = avgBrake / float64(rowsCount)
	avgAccel = avgAccel / float64(rowsCount)
	avgScore = avgScore / float64(rowsCount)

	log.Println("UPDATING USER SCORE")
	// update user score in the db
	_, err = db.Exec("UPDATE users SET brake_score = $1, accel_score = $2, score = $3 WHERE user_id = $4", avgBrake, avgAccel, avgScore, user_id)
	return err
}

type subScore struct {
	val float64 
	weight float64
}
