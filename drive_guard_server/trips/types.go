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
}


