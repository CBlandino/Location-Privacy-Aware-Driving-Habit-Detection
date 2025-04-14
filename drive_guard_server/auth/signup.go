package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"log"
	"net/http"
	"errors"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"

	"drive_guard_server/tokens"
)


func SignupUser(c *gin.Context, db *sql.DB) {
    log.Println("POST: signup user")
    var newUser tokens.User 
    err := c.BindJSON(&newUser)
    if err != nil {
        log.Fatal(err)
    }

    result, err := insertUser(newUser, db)
    if err != nil {
        // if an error occurs during db insert reject the signup
        c.JSON(http.StatusNotAcceptable, err)
        return
    }

    log.Println("RESULT:", result)

    // instead of passing the users email in the JWT, u can isntead pass their users table ID
    jwt, status := tokens.NewJWT(newUser)
    if status != http.StatusAccepted {
        // if token creation fails send back bad response
        c.Status(status)
        return
    }

    log.Println("USER CREATED:", newUser.Email, "fname:", newUser.Firstname, "lname:", newUser.Lastname)
    log.Println("USER JWT:", jwt)
    c.IndentedJSON(http.StatusCreated, &authResponse{jwt})
    log.Println("RESPONSE:", http.StatusCreated)
}

func insertUser(newUser tokens.User, db *sql.DB) (sql.Result, error) {
    salt := make([]byte, 50) 
    rand.Read(salt)

    pass_hash := sha256.Sum256(append([]byte(newUser.Password), salt...))
	role, err := checkRole(newUser.Role)
	if err != nil {
		return nil, err
	}
	// $1 = first name 
	// $2 = last name 
	// $3 = user email 
	// $4 = user class
	// $5 = password hash 
	// $6 = password salt
    insertStmnt := "INSERT INTO users VALUES (DEFAULT, $1, $2, $3, $4, $5, $6)"
    result, err := db.Exec(insertStmnt, newUser.Firstname, newUser.Lastname, newUser.Email, role, pass_hash[:], salt) 
    // TODO: check for duplicate email
    if err != nil {
        log.Println(err)
        return result, err
    }

    return result, nil
}


func checkRole(input string) (string, error) {
	if input == "User" {
		return "user", nil
	} else if input == "Admin" {
		return "admin", nil
	} else if input == "Insurance" {
		return "insurance", nil
	} 

	return "", errors.New("invalid user class provided!")
}
