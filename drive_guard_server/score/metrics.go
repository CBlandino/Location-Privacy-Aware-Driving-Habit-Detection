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
	var totalDistance float64 = 0.0
	for i, point := range data {
		if d := getDistance(&point, PkLat); d != math.NaN() {
			totalDistance += d
			velo := int((d / 5) * 3600)
			data[i].Velo = velo
		}
		PkLat += point.Lat 
		PkLong += point.Long
	}

	brakingPass := getBrakingFlags(data)
	accelPass := getAccelerationFlags(data)
	speedingPass := getSpeedingFlags(data)

	log.Println("braking severity:", brakingPass.totalSeverity)
	log.Println("accel severity:", accelPass.totalSeverity)
	log.Println("speeding severity:", speedingPass.totalSeverity)
	
	var averageVelocity float64 = (totalDistance / (5.0 * float64(len(data)))) * 3600.0

	// calculate score for the trip
	tripScore, brakingScore, accelScore, speedingScore := takeInput(brakingPass, accelPass, speedingPass)

	// store calculated information in the trips table
	updateStmnt := "UPDATE trips SET distance = $1, velocity = $2, trip_score = $3, speed_score = $4, brake_score = $5, accel_score = $6 WHERE trip_id = $7"
	_, err := db.Exec(updateStmnt, totalDistance, averageVelocity, tripScore, speedingScore, brakingScore, accelScore, tripID)
	return err
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
	// using beta approximation of 1 until implementation of R geographical points is done
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


func getSpeedingFlags(data []point) metricPass {

	metrics := make([]metricFlag, 0)
	totalSev := 0

	for _, point := range data {
		var severity int
		if point.Velo >= 85 {
			severity = 2
		} else if point.Velo >= 75  {
			severity = 1
		} else {
			severity = 0
		}

		totalSev += severity
		metrics = append(metrics, metricFlag{severity, point.Velo, -1})
	}

	return metricPass{metrics, totalSev}
}

func getBrakingFlags(data []point) metricPass {
	metrics := make([]metricFlag, 0)
	totalSev := 0

	previousVelo := 0
	for _, point := range data {
		var severity int

		//calculate deceleration between points
		decel := (previousVelo - point.Velo) / 5
		if decel >= 7 {
			severity = 2
		} else if decel >= 5 {
			severity = 1
		} else {
			severity = 0
		}

		totalSev += severity
		metrics = append(metrics, metricFlag{severity, point.Velo, decel})
		previousVelo = point.Velo
	}

	return metricPass{metrics, totalSev}
}

func getAccelerationFlags(data []point) metricPass {
	metrics := make([]metricFlag, 0) 
	totalSev := 0
	
	previousVelo := 0
	for _, point := range data {
		var severity int

		//calculate acceleration between points
		accel := (point.Velo - previousVelo) / 5 
		if accel >= 8 {
			severity = 2
		} else if accel >= 6 {
			severity = 1 
		} else {
			severity = 0
		}

		totalSev += severity
		metrics = append(metrics, metricFlag{severity, point.Velo, accel})
		previousVelo = point.Velo
	}

	return metricPass{metrics, totalSev}
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

type metricPass struct {
	flags []metricFlag 
	totalSeverity int
}

type metricFlag struct {
	// severity of the event ranging from 0(no severity), 1(mild severity), 2(high severity)
	Severity int
	// speed recorded at the current point
	Velo int 
	// acceleration recorded at the current point
	Accel int
}
