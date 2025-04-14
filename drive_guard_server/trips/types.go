package trips 

// a point batch incoming from a client. parsed raw from the post request
type pointSet struct {
	// flag signifying the start of the trip
	Start bool `json:"isStart"`
	// flag signifying that the trip has ended
	End bool `json:"isEnd"`
	// batch start time
	Start_time string `json:"start_time"`
	// elapsed time of the batch
	Elapsed_time int `json:"elapsed_time"`
	// compressed points in the batch
	Points []point `json:"delta_points"`
}

// indivisual point contained within a batch set
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

// struct for previous trip response to the client
type PrevTrip struct {
	// trip starting time
	TimeStamp string `json:"timestamp"`
	// total distance travelled during the trip
	Distance float64 `json:"distance"`
	// average velocity for the trip 
	Velocity float64 `json:"velocity"`
}
