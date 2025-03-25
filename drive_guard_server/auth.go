package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt"
)

// this will be updated eventually
// use crypto/rand
var signingKey = []byte("SUPERSECRETSIGNINGKEY")
var Users []User = make([]User, 0)

func signupUser(c *gin.Context) {
	log.Println("POST: signup user")
	var newUser User
	err := c.BindJSON(&newUser)
	if err != nil {
		log.Fatal(err)
	}

	jwt, status := newJWT([]string{newUser.Email})
	if status != http.StatusAccepted {
		c.Status(status)
		return
	}

	log.Println("USER CREATED:", newUser.Email, "fname:", newUser.Firstname, "lname:", newUser.Lastname)
	Users = append(Users, newUser)

	log.Println("USER JWT:", jwt)
	c.IndentedJSON(http.StatusCreated, &authResponse{jwt})
	log.Println("RESPONSE:", http.StatusCreated)
}

func loginUser(c *gin.Context) {
	log.Println("POST: login user")
	var loggedUser User
	err := c.BindJSON(&loggedUser)
	if err != nil {
		log.Fatal(err)
	}

	for _, user := range Users {
		if user.Email == loggedUser.Email && user.Password == loggedUser.Password {
			log.Println("USER FOUND: EMAIL:", user.Email)
			jwt, status := newJWT([]string{user.Email})
			if status != http.StatusAccepted {
				log.Println("USER:", user.Email, "NOT ACCEPTED")
				c.Status(status)
			}
			c.IndentedJSON(http.StatusAccepted, &authResponse{jwt})
			return
		}
	}

	c.Status(http.StatusNotAcceptable)
	log.Println("USER NOT FOUND. STATUS:", http.StatusNotAcceptable)
}

// make id added to that
// make an experation date for session token
// 2 tokens, one is shorter that will log out user after 2 hours, the other is longer and will continually refresh the shorter

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
	Email     string `json:"email"`
	Password  string `json:"password"`
	Firstname string `json:"first_name"`
	Lastname  string `json:"last_name"`
}

type UserClaims struct {
	Email string `json:"email"`
	jwt.StandardClaims
}
