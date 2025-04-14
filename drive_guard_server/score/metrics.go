package score

import (
	"database/sql"
	"encoding/json"

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

	var totalDistance float64 = 0.0
	for _, point := range data {
		totalDistance += getDistance(&point)
	}

	var averageVelocity float64 = (totalDistance / (5.0 * float64(len(data)))) * 3600.0

	_, err := db.Exec("UPDATE trips SET distance = $1, velocity = $2 WHERE trip_id = $3", totalDistance, averageVelocity, tripID)
	return err
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

	return totalDist
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
	Velo float64 `json:"v"`
}
