package main

import (
	"flag"
	"log"
	"time"

	"database/sql"

	_ "github.com/lib/pq"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"context"

	"drive_guard_server/AdminInfo"
	"drive_guard_server/auth"
	"drive_guard_server/insurance"
	"drive_guard_server/score"
	"drive_guard_server/trips"
	"drive_guard_server/util"
)

var (
	ADDR    string
	DB_HOST string
	DB_USER string
	DB_PASS string
	DB_NAME string
	UPDATE  bool
)

func init() {
	flag.StringVar(&ADDR, "addr", ":8080", "address to run the server on")
	flag.StringVar(&DB_HOST, "dbaddr", "", "address of databse")
	flag.StringVar(&DB_USER, "dbuser", "dg_api", "database username")
	flag.StringVar(&DB_PASS, "dbpass", "secure", "database user password")
	flag.StringVar(&DB_NAME, "dbname", "dg_db", "database name")
	flag.BoolVar(&UPDATE, "update", false, "update metrics and score on all stored trips on server startup")
	flag.Parse()
}

func main() {
	log.Println("STARTING SERVER")

	// Connect and configure database
	dbConnStr := " user=" + DB_USER + " password=" + DB_PASS + " dbname=" + DB_NAME
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

	// Ping database to ensure successful connection
	if err := db.PingContext(context.Background()); err != nil {
		log.Println(util.ANSI_RED_BACKGROUND + "DATABASE CONNECTION UNSUCCESSFUL" + util.ANSI_RESET)
		log.Println(err)
	} else {
		log.Println(util.ANSI_GREEN_BACKGROUND + "DATABASE CONNECTION SUCCESSFUL" + util.ANSI_RESET)
	}

	// update all trips
	if UPDATE {
		log.Println("UPDATING ALL TRIPS")
		updateAllTrips(db)
		log.Println("TRIP UPDATE SUCCESSFUL")
	}

	// Initialize the web server and handlers
	server := gin.Default()

	server.Use(cors.New(cors.Config{
		AllowOriginFunc: func(origin string) bool {
			log.Println("Origin request:", origin)
			return true
		},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	server.POST("/7d2abf2d0fa7c3a0c13236910f30bc43", func(c *gin.Context) {
		log.Println(util.ANSI_YELLOW + "SIGNUP REQ --------------------------------------------------------------------------------------------------" + util.ANSI_RESET)
		auth.SignupUser(c, db)
		log.Println(util.ANSI_YELLOW + "-------------------------------------------------------------------------------------------------------------" + util.ANSI_RESET)
	})
	server.POST("/d56b699830e77ba53855679cb1d252da", func(c *gin.Context) {
		log.Println(util.ANSI_YELLOW + "LOGIN REQ ---------------------------------------------------------------------------------------------------" + util.ANSI_RESET)
		auth.LoginUser(c, db)
		log.Println(util.ANSI_YELLOW + "-------------------------------------------------------------------------------------------------------------" + util.ANSI_RESET)
	})
	server.POST("/2d13f826de6251aef204690750c1da99", func(c *gin.Context) {
		log.Println(util.ANSI_YELLOW + "TRANSMIT REQ ------------------------------------------------------------------------------------------------" + util.ANSI_RESET)
		trips.TransmitPoints(c, db)
		log.Println(util.ANSI_YELLOW + "-------------------------------------------------------------------------------------------------------------" + util.ANSI_RESET)
	})
	server.GET("/55a4a318d8473bd5b80cea42331e473c", func(c *gin.Context) {
		log.Println(util.ANSI_YELLOW + "PREV TRIP REQ -----------------------------------------------------------------------------------------------" + util.ANSI_RESET)
		trips.Previous_trips(c, db)
		log.Println(util.ANSI_YELLOW + "-------------------------------------------------------------------------------------------------------------" + util.ANSI_RESET)
	})
	// GetScore
	server.GET("/ca1cd3c3055991bf20499ee86739f7e2", func(c *gin.Context) {
		log.Println(util.ANSI_YELLOW + "SIGNUP REQ --------------------------------------------------------------------------------------------------" + util.ANSI_RESET)
		score.GetUserScore(c, db)
		log.Println(util.ANSI_YELLOW + "-------------------------------------------------------------------------------------------------------------" + util.ANSI_RESET)
	})

	server.GET("/userLookup", func(c *gin.Context) {
		log.Println(util.ANSI_BLUE + "USER LOOKUP REQ ---------------------------------------------------------------------------------------------" + util.ANSI_RESET)
		insurance.SearchUsers(c, db)
		log.Println(util.ANSI_BLUE + "-------------------------------------------------------------------------------------------------------------" + util.ANSI_RESET)
	})

	server.GET("/user_score/:userId", func(c *gin.Context) {
		log.Println(util.ANSI_BLUE + "USER SCORE LOOKUP REQ ---------------------------------------------------------------------------------------------" + util.ANSI_RESET)
		insurance.GetUserScore(c, db)
		log.Println(util.ANSI_BLUE + "-------------------------------------------------------------------------------------------------------------" + util.ANSI_RESET)
	})

	server.GET("/user_trips/:userId", func(c *gin.Context) {
		log.Println(util.ANSI_BLUE + "USER TRIPS LOOKUP REQ ---------------------------------------------------------------------------------------------" + util.ANSI_RESET)
		insurance.GetUserTrips(c, db)
		log.Println(util.ANSI_BLUE + "-------------------------------------------------------------------------------------------------------------" + util.ANSI_RESET)
	})

	server.GET("/insurance/status", func(c *gin.Context) {
		log.Println(util.ANSI_BLUE + "USER OPTIONAL INFO REQ---------------------------------------------------------------------------------------------" + util.ANSI_RESET)
		insurance.CheckInsuranceStatus(c, db)
		log.Println(util.ANSI_BLUE + "-------------------------------------------------------------------------------------------------------------" + util.ANSI_RESET)

	})

	// Add routes for Ping Server
	server.GET("/ping", AdminInfo.HandlePing)

	// Add routes for Insurance Lookup
	server.GET("/insurance", func(c *gin.Context) {
		AdminInfo.HandleInsuranceLookup(c, db)
	})

	// Add routes for Server Information
	server.GET("/server-info", func(c *gin.Context) {
		AdminInfo.HandleServerInfo(c, db)
	})

	// Add routes for ID Generator
	server.POST("/generate-id", func(c *gin.Context) {
		log.Println("SetupIDRoutes: /generate-id route triggered")
		AdminInfo.HandleIDGeneration(c, db)
	})

	server.GET("/admin/stats", func(c *gin.Context) {
		log.Println("SetupStatsRoutes: /admin/stats route triggered")
		AdminInfo.HandleQuickStats(c, db)
	})
	server.Run(ADDR)
}

// possibly dangerous, trigger with care
func updateAllTrips(db *sql.DB) {
	tripsSet := func() []struct{ uid, tid int } {
		var trips []struct{ uid, tid int }

		tripResSet, err := db.Query("SELECT user_id, trip_id FROM trips")
		if err != nil {
			log.Println("UNABLE TO TRIGGER UPDATE ON ALL RECORDED TRIPS")
			log.Fatal(err)
		}
		defer tripResSet.Close()

		for tripResSet.Next() {
			var u, i int
			if err := tripResSet.Scan(&u, &i); err != nil {
				log.Println("unable to update trip in db")
				log.Println(err)
			}

			trips = append(trips, struct{ uid, tid int }{u, i})
		}
		return trips
	}

	for _, trip := range tripsSet() {
		trips.EndTrip(trip.uid, trip.tid, db)
	}
}
