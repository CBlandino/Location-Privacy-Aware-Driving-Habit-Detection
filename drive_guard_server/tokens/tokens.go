package tokens


import (

	"net/http"
	"github.com/golang-jwt/jwt"
)


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
