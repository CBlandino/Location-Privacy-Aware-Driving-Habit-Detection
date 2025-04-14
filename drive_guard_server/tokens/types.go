package tokens 

import (
	"github.com/golang-jwt/jwt"
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
