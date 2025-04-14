package tokens


import (
	"errors"
	"log"
	"strings"
	"github.com/golang-jwt/jwt"
)

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
		log.Fatal(err)
		return nil, err
	}

	log.Println(tok)

	return claims, nil
}
