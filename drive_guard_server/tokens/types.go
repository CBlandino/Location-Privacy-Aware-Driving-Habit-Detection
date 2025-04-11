package tokens 

import (
	"github.com/golang-jwt/jwt"
)

type User struct {
	Email     string `json:"email"`
	Password  string `json:"password"`
	Firstname string `json:"first_name"`
	Lastname  string `json:"last_name"`
}

// TODO frontend wants more info in here for displaying in menus. add first and last name here... ALSO user role should be here as well
type UserClaims struct {
	Email string `json:"email"`
	jwt.StandardClaims
}
