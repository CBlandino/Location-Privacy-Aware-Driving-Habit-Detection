package main

import (
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"log"
	"net/http"
    "bytes"
    "errors"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt"
	_ "github.com/lib/pq"
)

// this will be updated eventually
// use crypto/rand
var signingKey = []byte("SUPERSECRETSIGNINGKEY")

func signupUser(c *gin.Context, db *sql.DB) {
    log.Println("POST: signup user")
    var newUser User 
    err := c.BindJSON(&newUser)
    if err != nil {
        log.Fatal(err)
    }

    result, err := insertUser(newUser, db)
    if err != nil {
        // if an error occurs during db insert reject the signup
        c.Status(http.StatusNotAcceptable)
        return
    }

    log.Println("RESULT:", result)

    // instead of passing the users email in the JWT, u can isntead pass their users table ID
    jwt, status := newJWT([]string{ newUser.Email })
    if status != http.StatusAccepted {
        // if token creation fails send back abd response
        c.Status(status)
        return
    }

    log.Println("USER CREATED:", newUser.Email, "fname:", newUser.Firstname, "lname:", newUser.Lastname)
    log.Println("USER JWT:", jwt)
    c.IndentedJSON(http.StatusCreated, &authResponse{jwt})
    log.Println("RESPONSE:", http.StatusCreated)
}

func insertUser(newUser User, db *sql.DB) (sql.Result, error) {
    salt := make([]byte, 50) 
    rand.Read(salt)

    pass_hash := sha256.Sum256(append([]byte(newUser.Password), salt...))
    insertStmnt := "INSERT INTO users VALUES (DEFAULT, $1, $2, $3, $4, $5)"
    result, err := db.Exec(insertStmnt, newUser.Firstname, newUser.Lastname, newUser.Email, pass_hash[:], salt) 
    // TODO: check for duplicate email
    if err != nil {
        log.Println(err)
        return result, err
    }

    return result, nil
}

func loginUser(c *gin.Context, db *sql.DB) {
    log.Println("POST: login user")
    var loggedUser User 
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

    jwt, status := newJWT([]string{loggedUser.Email})
    if status != http.StatusAccepted { 
        log.Println("USER:", loggedUser.Email, "NOT ACCEPTED")
        c.Status(status)
    }
    c.IndentedJSON(http.StatusAccepted, &authResponse{jwt})
}

func verifyLogin(logUser User, db *sql.DB) error {
    var pass, salt []byte
    usrRow := db.QueryRow("SELECT password_hash, salt FROM users WHERE email = $1", logUser.Email)
    if err := usrRow.Scan(&pass, &salt); err != nil {
        return err
    }

    loginHash := sha256.Sum256(append([]byte(logUser.Password), salt...)) 
    if !bytes.Equal(pass, loginHash[:]){
        return errors.New("passwords do not match")
    }
    return nil
}


func newJWT(claimsList []string) (string, int) {

    // create user claims... this can all be expanded upon based on user class 
    // different inputs etc.
    // for now its just email
    claims := &UserClaims{
        // add more claims later (adjust parameters)
        claimsList[0], 
        jwt.StandardClaims{},
    }

    // create the token
    userJWT := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    // sign the token... signing algo likely to change
    signedJWT, err := userJWT.SignedString(signingKey)
    // if we fail to sign the token
    if err != nil {
        return "", http.StatusNotAcceptable
    }

    return signedJWT, http.StatusAccepted
}

type authResponse struct {
    AccToken string `json:"access_token"`
}

type User struct {
    Email string `json:"email"`
    Password string `json:"password"`
    Firstname string `json:"first_name"`
    Lastname string `json:"last_name"`
}

type UserClaims struct {
    Email string `json:"email"`
    jwt.StandardClaims
}
