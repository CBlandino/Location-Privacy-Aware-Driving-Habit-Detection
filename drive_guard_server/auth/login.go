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

	"drive_guard_server/tokens"
)

func LoginUser(c *gin.Context, db *sql.DB) {
    log.Println("POST: login user")
    var loggedUser tokens.User 
    err := c.BindJSON(&loggedUser)
    if err != nil {
        log.Fatal(err)
    }

    //TODO better error handling... either user email is not registered or incorrect password
    err = verifyLogin(loggedUser, db)
    if err != nil {
        log.Println(err)
        log.Println("USER NOT FOUND. STATUS:", http.StatusNotAcceptable)
        c.Status(http.StatusNotAcceptable)
        return
    }

    jwt, status := tokens.NewJWT([]string{loggedUser.Email})
    if status != http.StatusAccepted { 
        log.Println("USER:", loggedUser.Email, "NOT ACCEPTED")
        c.Status(status)
    }
    c.IndentedJSON(http.StatusAccepted, &authResponse{jwt})
}

func verifyLogin(logUser tokens.User, db *sql.DB) error {
    var pass, salt []byte
    usrRow := db.QueryRow("SELECT password_hash, salt FROM users WHERE email = $1", logUser.Email)
    if err := usrRow.Scan(&pass, &salt); err != nil {
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

