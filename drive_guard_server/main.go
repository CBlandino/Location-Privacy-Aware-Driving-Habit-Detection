package main

import (
	"log"

	"database/sql"
	_ "github.com/lib/pq"

	"github.com/gin-gonic/gin"

    "context"

	"drive_guard_server/auth"
	// "drive_guard_server/score"
	"drive_guard_server/trips"
)

var (
    addr string = ":8080"
)

func main() {
    log.Println("STARTING SERVER")

	//connect and configure database
    db_conn := "user=dg_api dbname=dg_db sslmode=disable"
    db, err := sql.Open("postgres", db_conn)
    if err != nil {
        log.Fatal(err)
    }
    db.SetMaxIdleConns(50)
	db.SetMaxOpenConns(50)


	// ping database to ensure successful connection
    if err := db.PingContext(context.Background()); err != nil {
        log.Println("DATABASE CONNECTION UNSUCCESSFUL")
	} else {
        log.Println("DATABASE CONNECTION SUCCESSFUL")
    }

	//initialize the web server and handlers
    server := gin.Default()
    server.POST("/signup", func(c *gin.Context) {
        auth.SignupUser(c, db)
    }) 
    server.POST("/login", func(c *gin.Context) {
        auth.LoginUser(c, db)
    })
    server.POST("/trip", func(c *gin.Context) {
        trips.TransmitPoints(c, db)
    })
	server.GET("/previous_trips", func(c *gin.Context) {
		trips.Previous_trips(c, db)
	})

    server.Run(addr)
}
