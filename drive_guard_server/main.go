package main

import (
	"log"
	"flag"

	"database/sql"
	_ "github.com/lib/pq"

	"github.com/gin-gonic/gin"

	"context"

	"drive_guard_server/auth"
	"drive_guard_server/trips"
)

var (
	ADDR string 
	DB_HOST string 
	DB_USER string 
	DB_PASS string 
	DB_NAME string
)

func init() {
	flag.StringVar(&ADDR, "addr", ":8080", "address to run the server on")
	flag.StringVar(&DB_HOST, "dbaddr", "", "address of databse")
	flag.StringVar(&DB_USER, "dbuser", "dg_api", "database username")
	flag.StringVar(&DB_PASS, "dbpass", "secure", "database user password")
	flag.StringVar(&DB_NAME, "dbname", "dg_db", "database name")
	flag.Parse()
}

func main() {
	log.Println("STARTING SERVER")

	//connect and configure database
	dbConnStr :=  " user=" + DB_USER + " password=" + DB_PASS + " dbname=" + DB_NAME 
	if DB_HOST != "" {
		dbConnStr += " host=" + DB_HOST + " sslmode=require"
	} else {
		dbConnStr += " sslmode=disable"
	}

	db, err := sql.Open("postgres", dbConnStr)
	if err != nil {
		log.Fatal(err)
	}
	db.SetMaxIdleConns(50)
	db.SetMaxOpenConns(50)


	// ping database to ensure successful connection
	if err := db.PingContext(context.Background()); err != nil {
		log.Println("DATABASE CONNECTION UNSUCCESSFUL")
		log.Println(err)
	} else {
		log.Println("DATABASE CONNECTION SUCCESSFUL")
	}

	//initialize the web server and handlers
	server := gin.Default()
	server.POST("/7d2abf2d0fa7c3a0c13236910f30bc43", func(c *gin.Context) {
		auth.SignupUser(c, db)
	}) 
	server.POST("/d56b699830e77ba53855679cb1d252da", func(c *gin.Context) {
		auth.LoginUser(c, db)
	})
	server.POST("/2d13f826de6251aef204690750c1da99", func(c *gin.Context) {
		trips.TransmitPoints(c, db)
	})
	server.GET("/55a4a318d8473bd5b80cea42331e473c", func(c *gin.Context) {
		trips.Previous_trips(c, db)
	})

	server.Run(ADDR)
}
