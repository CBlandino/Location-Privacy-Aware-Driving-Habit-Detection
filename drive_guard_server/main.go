package main

import (
	"log"

	"database/sql"
	_ "github.com/lib/pq"

	"github.com/gin-gonic/gin"

)

var (
	db  *sql.DB
    addr string = "localhost:8080"
)

func main() {
    log.Println("STARTING SERVER")

    db_conn := "user=dg_api_user dbname=dg_db sslmode=disable"

    db, err := sql.Open("postgres", db_conn)
    if err != nil {
        log.Fatal(err)
    }


    if err := db.Ping(); err != nil {
        log.Println("DATABASE CONNECTION UNSUCCESSFUL")
	} else {
        log.Println("DATABASE CONNECTION SUCCESSFUL")
    }

    server := gin.Default()
    server.POST("/signup", signupUser) 
    server.POST("/login", loginUser)
    server.POST("/trip", transmitPoints)

    server.Run(addr)
}


