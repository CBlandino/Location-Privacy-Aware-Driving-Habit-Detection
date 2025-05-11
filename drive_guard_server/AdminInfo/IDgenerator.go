package AdminInfo

import (
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)



func HandleIDGeneration(c *gin.Context, db *sql.DB) { //id generation is dealt with creates an account for the user
	log.Println("HandleIDGeneration: Function called")

	var newUser struct { //user is parsed
		Firstname string `json:"firstname"`
		Lastname  string `json:"lastname"`
		Email     string `json:"email"`
		Password  string `json:"password"`
		Role      string `json:"role"`
	}
	if err := c.BindJSON(&newUser); err != nil {
		log.Println("HandleIDGeneration: There was an error parsing user details:", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}
	log.Println("HandleIDGeneration: The user details were parsed successfully")

	if newUser.Firstname == "" || newUser.Lastname == "" || newUser.Email == "" || newUser.Password == "" || newUser.Role == "" {
		log.Println("HandleIDGeneration:Required fields are missing ")
		c.JSON(http.StatusBadRequest, gin.H{"error": "All fields are required"})
		return
	}
	log.Println("HandleIDGeneration: Input validation passed")

	// salt and hash
	salt := make([]byte, 50)
	_, err := rand.Read(salt)
	if err != nil {
		log.Println("HandleIDGeneration: There was an error generating salt:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process password"})
		return
	}
	passHash := sha256.Sum256(append([]byte(newUser.Password), salt...))
	log.Println("HandleIDGeneration:The password hashed successfully")

	role := newUser.Role //role is validated
	if role != "user" && role != "admin" && role != "insurance" {
		log.Println("HandleIDGeneration: Invalid role provided:", role)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user role provided"})
		return
	}
	log.Println("HandleIDGeneration: Role validated:", role)

	// Insert user into the database and let the database auto-generate the ID
	insertStmt := `
        INSERT INTO users (first_name, last_name, email, class, password_hash, salt, brake_score, accel_score, score)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id
    `
	var generatedID int
	err = db.QueryRow(insertStmt, newUser.Firstname, newUser.Lastname, newUser.Email, role, passHash[:], salt, 1.0, 1.0, 1.0).Scan(&generatedID)
	if err != nil {
		log.Println("HandleIDGeneration: Error inserting user into database:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create account", "details": err.Error()})
		return
	}

	log.Println("HandleIDGeneration: User inserted into database successfully with ID:", generatedID)

	// Respond with success and the generated ID
	c.JSON(http.StatusCreated, gin.H{"message": "Account created successfully", "account_id": generatedID})
}
