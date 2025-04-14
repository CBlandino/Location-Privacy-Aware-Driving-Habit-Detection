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
		dbConnStr += "host=" + DB_HOST + " sslmode=require"
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

    server.Run(ADDR)
}
