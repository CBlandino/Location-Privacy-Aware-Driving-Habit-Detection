package main


import (
    "log"
    "net/http"
    "github.com/gin-gonic/gin"
)

var Users []User
var addr string

func main() {
    addr = "localhost:6969"
    log.Println("STARTING SERVER")
    Users = make([]User, 0)
    log.Println("USER TABLE INITIALIZED")
    
    server := gin.Default()
    server.POST("/signup", signupUser) 
    server.POST("/login", loginUser)

    server.Run(addr)
}

func signupUser(c *gin.Context) {
    log.Println("POST: signup user")
    var newUser User 
    err := c.BindJSON(&newUser)
    if err != nil {
        log.Fatal(err)
    }

    log.Println("USER:", newUser)

    Users = append(Users, newUser)
    c.IndentedJSON(http.StatusCreated, newUser)
    log.Println("RESPONSE:", http.StatusCreated)
}

func loginUser(c *gin.Context) {
    log.Println("POST: login user")
    var loggedUser User 
    err := c.BindJSON(&loggedUser)
    if err != nil {
        log.Fatal(err)
    }

    log.Println("USER:", loggedUser)

    for _, user := range Users {
        if user.Username == loggedUser.Username && user.Password == loggedUser.Password {
            c.IndentedJSON(http.StatusAccepted, user)
            log.Println("USER FOUND:", user, "RESPONSE:", http.StatusAccepted)
            return
        }
    }

    c.Status(http.StatusNotAcceptable)
    log.Println("USER NOT FOUND. STATUS:", http.StatusNotAcceptable)
}


type User struct {
    Username string `json:"username"`
    Password string `json:"password"`
}
