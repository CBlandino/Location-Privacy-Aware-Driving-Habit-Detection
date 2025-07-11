package main

import (
	"context"
	"database/sql"
	"flag"
	"log"
	"time"
	"os"

	_ "github.com/lib/pq"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/awslabs/aws-lambda-go-api-proxy/gin"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

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
	db      *sql.DB
)

func init() {
	flag.StringVar(&ADDR, "addr", ":8080", "address to run the server on")
	flag.StringVar(&DB_HOST, "dbaddr", os.Getenv("DB_HOST"), "address of database")
	flag.StringVar(&DB_USER, "dbuser", os.Getenv("DB_USER"), "database username")
	flag.StringVar(&DB_PASS, "dbpass", os.Getenv("DB_PASS"), "database user password")
	flag.StringVar(&DB_NAME, "dbname", os.Getenv("DB_NAME"), "database name")
	flag.BoolVar(&UPDATE, "update", false, "update metrics and score on all stored trips on server startup")
	flag.Parse()
}

func main() {
	log.Println("STARTING SERVER (Lambda Mode)")

	// Setup DB connection
	dbConnStr := "user=" + DB_USER + " password=" + DB_PASS + " dbname=" + DB_NAME
	if DB_HOST != "" {
		dbConnStr += " host=" + DB_HOST + " sslmode=require"
	} else {
		dbConnStr += " sslmode=disable"
	}

	var err error
	db, err = sql.Open("postgres", dbConnStr)
	if err != nil {
		log.Fatal(err)
	}
	db.SetMaxIdleConns(50)
	db.SetMaxOpenConns(50)

	if err := db.PingContext(context.Background()); err != nil {
		log.Println(util.ANSI_RED_BACKGROUND + "DATABASE CONNECTION UNSUCCESSFUL" + util.ANSI_RESET)
		log.Fatal(err)
	}
	log.Println(util.ANSI_GREEN_BACKGROUND + "DATABASE CONNECTION SUCCESSFUL" + util.ANSI_RESET)

	if UPDATE {
		log.Println("UPDATING ALL TRIPS")
		updateAllTrips(db)
		log.Println("TRIP UPDATE SUCCESSFUL")
	}

	r := gin.Default()

	r.Use(cors.New(cors.Config{
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

	r.POST("/7d2abf2d0fa7c3a0c13236910f30bc43", func(c *gin.Context) {
		auth.SignupUser(c, db)
	})
	r.POST("/d56b699830e77ba53855679cb1d252da", func(c *gin.Context) {
		auth.LoginUser(c, db)
	})
	r.POST("/2d13f826de6251aef204690750c1da99", func(c *gin.Context) {
		trips.TransmitPoints(c, db)
	})
	r.GET("/55a4a318d8473bd5b80cea42331e473c", func(c *gin.Context) {
		trips.Previous_trips(c, db)
	})
	r.GET("/ca1cd3c3055991bf20499ee86739f7e2", func(c *gin.Context) {
		score.GetUserScore(c, db)
	})
	r.GET("/userLookup", func(c *gin.Context) {
		insurance.SearchUsers(c, db)
	})
	r.GET("/user_score/:userId", func(c *gin.Context) {
		insurance.GetUserScore(c, db)
	})
	r.GET("/user_trips/:userId", func(c *gin.Context) {
		insurance.GetUserTrips(c, db)
	})
	r.GET("/insurance/status", func(c *gin.Context) {
		insurance.CheckInsuranceStatus(c, db)
	})
	r.GET("/ping", AdminInfo.HandlePing)
	r.GET("/insurance", func(c *gin.Context) {
		AdminInfo.HandleInsuranceLookup(c, db)
	})
	r.GET("/server-info", func(c *gin.Context) {
		AdminInfo.HandleServerInfo(c, db)
	})
	r.POST("/generate-id", func(c *gin.Context) {
		AdminInfo.HandleIDGeneration(c, db)
	})
	r.GET("/admin/stats", func(c *gin.Context) {
		AdminInfo.HandleQuickStats(c, db)
	})

	// Use AWS Lambda handler
	ginLambda := ginadapter.New(r)
	lambda.Start(ginLambda.ProxyWithContext)
}

func updateAllTrips(db *sql.DB) {
	tripsSet := func() []struct{ uid, tid int } {
		var trips []struct{ uid, tid int }
		tripResSet, err := db.Query("SELECT user_id, trip_id FROM trips")
		if err != nil {
			log.Fatal("UNABLE TO TRIGGER UPDATE ON ALL RECORDED TRIPS:", err)
		}
		defer tripResSet.Close()

		for tripResSet.Next() {
			var u, i int
			if err := tripResSet.Scan(&u, &i); err != nil {
				log.Println("unable to update trip in db:", err)
			}
			trips = append(trips, struct{ uid, tid int }{u, i})
		}
		return trips
	}
	for _, trip := range tripsSet() {
		trips.EndTrip(trip.uid, trip.tid, db)
	}
}
