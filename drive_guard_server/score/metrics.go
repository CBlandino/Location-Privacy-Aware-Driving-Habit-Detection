package score

import (
	"database/sql"
	"encoding/json"
	"log"

	_ "github.com/lib/pq"

	"math"
)

// given a trip ID (with trip data that can be retrieved from the DB) pass over the data in the trip and look for windows
// where particular metrics can be detected.
func TripMetricsPasses(tripID int, db *sql.DB) error {
	var data []point 
	var dataRaw []byte 

	dataRow := db.QueryRow("SELECT data FROM trips WHERE trip_id = $1", tripID) 	
	if err := dataRow.Scan(&dataRaw); err != nil {
		return err
	}

	if err := json.Unmarshal(dataRaw, &data); err != nil {
		return err
	}

	// center of collins circle: 42.688309, -73.821711
	// integer conversion (multiplied by 10^6): 42688309, -73821711
	var PkLat int = 42688309
	var PkLong int = -73821711

	var tripMetrics metrics
	var prevVelocity float64 = 0.0
	var prevBearing float64 = 0.0 
	var currentBearing float64 = 0.0

	for _, point := range data {
		if d := getDistance(&point, PkLat); d != math.NaN() {
			tripMetrics.distance += d
			dvelocity := (d / 5) * 3600 
			if tripMetrics.max_velo < dvelocity {
				tripMetrics.max_velo = dvelocity
			}
			//accumulate velocity
			tripMetrics.avg_velo += dvelocity
			// accumulate brake severity
			tripMetrics.brake_sev += getBrakingSev(dvelocity, prevVelocity)
			// accumulate accel severity 
			tripMetrics.accel_sev += getAccelSev(dvelocity, prevVelocity)
			// calculate bearing angle for next point
			prevBearing, currentBearing = currentBearing, getBearing(&point, PkLat)
			tripMetrics.bearing_sev += getBearingSev(prevBearing, currentBearing)
			prevVelocity = dvelocity
		}
		PkLat += point.Lat 
		PkLong += point.Long
	}

	// calculate average velocity
	tripMetrics.avg_velo = (tripMetrics.distance / (5.0 * float64(len(data)))) * 3600
	// save the length of the trip
	tripMetrics.trip_length = len(data)

	score, accel_score, brake_score := scoreTrip(&tripMetrics)

	insrtString := "INSERT INTO tripsmetrics VALUES ($1, $2, $3, $4, $5, $6, $7)"
	_, err := db.Exec(insrtString, tripID, tripMetrics.distance, tripMetrics.avg_velo, tripMetrics.max_velo, brake_score, accel_score, score)
	if err != nil {
		log.Println("error entering metrics into tripsmetrics table", err.Error())
		return err
	}
	return nil
}

// function that passes over all of the points in a transmitted point set prior to their inclusion in the db 
// we can calculate distance on the set here, as well as any other metrics we wanted to/needed to
func getDistance(p *point, lati int) float64 {

	var totalDist float64 = 0.0

	// radius of the earth in miles (6371km)
	const R float64 = 3958.756 

	latj := lati + p.Lat

	latiRad := (float64(lati) * 0.000001) * (math.Pi / 180.0)
	latjRad := (float64(latj) * 0.000001) * (math.Pi / 180.0)
	
	var Beta float64 = math.Cos(latiRad) * math.Cos(latjRad)

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

	return totalDist
}

func getBearing(p *point, lati int) float64 {
	
	latj := lati + p.Lat 

	latiRad := (float64(lati) * 0.000001) * (math.Pi / 180.0) 
	latjRad := (float64(latj) * 0.000001) * (math.Pi / 180.0) 
	dlonijRad := (float64(p.Long) * 0.000001) * (math.Pi / 180.0)

	alpha := math.Cos(latiRad) * math.Sin(latjRad) - math.Sin(latiRad) * math.Cos(latjRad) * math.Cos(dlonijRad) 

	beta := math.Sin(dlonijRad) * math.Cos(latjRad)

	theta := math.Atan2(alpha, beta)

	return math.Abs(math.Mod((theta * (180.0 / math.Pi)), 360.0)) 
}

// the numbers in these functions that determine severity for a given metric,
// are approximate estimates about what the measurements would be according to 
// observations I made on data gathered on trips I took
// 
// basically if ur calculated acceleration for example is larger than 8 mph that particular interval gets marked
// with the highest level of severity, 2 (BAD) if your acceleration is between 6 and 8 you get a severity rank of 
// 1 on the point (MODERATE) anything below that gets a 0 severity (GOOD) 
// it was recommended that we track based on windows ( for example if the previous window has a low severity and the next window has
// a high severity, mark that window)
// 
// - Ryan
func getBearingSev(prev, current float64) int {
	bearingDiff := math.Abs(prev - current) 
	if bearingDiff > 100 {
		return 2 
	} else if bearingDiff > 80 {
		return 1 
	} else {
		return 0
	}
}

func getBrakingSev(velocity, prevVelocity float64) int {
	decel := (prevVelocity - velocity) / 5.0
	if decel >= 7 {
		return 2 
	} else if decel >= 5 {
		return 1
	} else {
		return 0
	}
}

func getAccelSev(velocity, prevVelocity float64) int {
	accel := (velocity - prevVelocity) / 5.0
	if accel >= 8 {
		return 2
	} else if accel >= 6 {
		return 1
	} else {
		return 0
	}
}

type point struct {
	// Lattitude delta
	Lat int `json:"dlat"`
	// Longitude delta
	Long int `json:"dlon"`
	// time stamp of point capture time
	Timestamp string `json:"t"`
	// order of this point in the batch
	Order int `json:"p"`
	// calculated velocity of this point within its varying time interval
	Velo int `json:"v"`
}

type metrics struct {
	//total distance travelled in the trip
	distance float64
	// average velocity captured during the trip
	avg_velo float64 
	// maximum velocity captured during the trip
	max_velo float64 
	// braking severity measurement
	brake_sev int 
	// acceleration severity measurement
	accel_sev int
	// bearing severity 
	bearing_sev int
	// length of the trip in points
	trip_length int 
}
