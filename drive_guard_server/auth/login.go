package auth

import (
	"crypto/sha256"
	"database/sql"
	"log"
	"net/http"
    "bytes"
    "errors"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"

	"drive_guard_server/util"
)

func LoginUser(c *gin.Context, db *sql.DB) {
    log.Println("POST: login user")
    var loggedUser util.User 
    err := c.BindJSON(&loggedUser)
    if err != nil {
        log.Fatal(err)
		c.IndentedJSON(http.StatusNotAcceptable, err)
		return
    }

    //TODO better error handling... either user email is not registered or incorrect password
    err = verifyLogin(&loggedUser, db)
    if err != nil {
        log.Println(err)
        log.Println("USER NOT FOUND. STATUS:", http.StatusNotAcceptable)
        c.Status(http.StatusNotAcceptable)
        return
    }

    jwt, status := util.NewJWT(loggedUser)
    if status != http.StatusAccepted { 
        log.Println("USER:", loggedUser.Email, "NOT ACCEPTED")
        c.Status(status)
    }
    c.IndentedJSON(http.StatusAccepted, &authResponse{jwt})
}

func verifyLogin(logUser *util.User, db *sql.DB) error {
    var pass, salt []byte
    usrRow := db.QueryRow("SELECT password_hash, salt, first_name, last_name, class FROM users WHERE email = $1", logUser.Email)
    if err := usrRow.Scan(&pass, &salt, &logUser.Firstname, &logUser.Lastname, &logUser.Role); err != nil {
        return err
    }

	//compare the stored password hash to the inputted hash
    loginHash := sha256.Sum256(append([]byte(logUser.Password), salt...)) 
    if !bytes.Equal(pass, loginHash[:]){
        return errors.New("passwords do not match")
    }
    return nil
}



type authResponse struct {
	AccToken string `json:"access_token"`
}

