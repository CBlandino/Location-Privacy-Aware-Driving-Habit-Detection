package AdminInfo

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Insurance represents an insurance record
type Insurance struct {
	ID          int    `json:"id"`
	PolicyName  string `json:"policy_name"`
	Description string `json:"description"`
	Premium     string `json:"premium"`
}

// HandleInsuranceLookup handles insurance lookup requests
func HandleInsuranceLookup(c *gin.Context, db *sql.DB) {
	// Query the database for insurance data
	rows, err := db.Query("SELECT id, policy_name, description, premium FROM insurance")
	if err != nil {
		log.Println("Error querying insurance data:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve insurance data"})
		return
	}
	defer rows.Close()

	// Parse the results into a slice of Insurance
	var insurances []Insurance
	for rows.Next() {
		var insurance Insurance
		if err := rows.Scan(&insurance.ID, &insurance.PolicyName, &insurance.Description, &insurance.Premium); err != nil {
			log.Println("Error scanning insurance data:", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse insurance data"})
			return
		}
		insurances = append(insurances, insurance)
	}

	// Return the insurance data as JSON
	c.JSON(http.StatusOK, insurances)
}

func SetupInsuranceRoutes(router *gin.Engine, db *sql.DB) {
	// Original insurance endpoint
	router.GET("/insurance", func(c *gin.Context) {
		HandleInsuranceLookup(c, db)
	})

	// New test endpoint for insurance
	router.GET("/insurance-test", func(c *gin.Context) {
		// This endpoint doesn't access the database
		c.JSON(200, gin.H{
			"status":  "success",
			"message": "Insurance test endpoint is working"})
	})
}
