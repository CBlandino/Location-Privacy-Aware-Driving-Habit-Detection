package util


import (

	"net/http"
	"github.com/golang-jwt/jwt"
	"errors"
	"log"
	"strings"
)

type User struct {
	Email     string `json:"email"`
	Password  string `json:"password"`
	Firstname string `json:"first_name"`
	Lastname  string `json:"last_name"`
	Role 	  string `json:"role"`
}

type UserClaims struct {
	Firstname string `json:"first_name"`
	Lastname string `json:"last_name"`
	Email string `json:"email"`
	Role string `json:"role"`
	jwt.StandardClaims
}


// this will be updated eventually
// use crypto/rand
var signingKey = []byte("SUPERSECRETSIGNINGKEY")

func NewJWT(user User) (string, int) {

	// create user claims... this can all be expanded upon based on user class
	// different inputs etc.
	// for now its just email
	claims := &UserClaims{
		// add more claims later (adjust parameters)
		user.Firstname,
		user.Lastname, 
		user.Email, 
		user.Role,
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

func GetClaims(tokenStr string) (*UserClaims, error) {
	// split "Bearer" off the header string
	splt := strings.Split(tokenStr, " ")
	if len(splt) != 2 && splt[0] != "Bearer" {
		return nil, errors.New("Invalid Authorization header format")
	}

	tokenStr = splt[1]
	claims := new(UserClaims)
	claims.Email = "test"
	// verify the integrity of the JWT and parse its claims into the claims struct (UserClaims type from auth.go)
	tok, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (any, error) {
		return signingKey, nil
	})
	if err != nil {
		log.Println("error parsing claims in JWT", err)
		return nil, err
	}

	log.Println(tok)

	return claims, nil
}
