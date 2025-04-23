package util


import (

	"database/sql"
	_ "github.com/lib/pq"

)

func GetUserID(claimsEmail string, db *sql.DB) (int, error) {
	var id int 
	row := db.QueryRow("SELECT user_id FROM users WHERE email = $1", claimsEmail)
	if err := row.Scan(&id); err != nil {
		return -1, err
	}

	return id, nil
}

func GetTripID(userID int, db *sql.DB) (int, error) {
	var id int 
	row := db.QueryRow("SELECT trip_id FROM trips WHERE user_id = $1 ORDER BY start_time DESC LIMIT 1", userID)

	if err := row.Scan(&id); err != nil {
		return -1, err
	}

	return id, nil
}
