
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
}

// HandleInsuranceLookup handles insurance lookup requests
func HandleInsuranceLookup(c *gin.Context, db *sql.DB) {
	// Handles insurance lookup requests
	policyNumber := c.Query("policyNumber") // Retrieve policy number from query parameters
	if policyNumber == "" {
		log.Println("HandleInsuranceLookup: Policy number is missing")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Policy number is required"})
		return
	}

	// Query insurance data for the specific policy number, excluding premium data for privacy
	query := `SELECT id, policy_name, description FROM insurance WHERE policy_name = $1`
	
	var id int
	var policyName, description string
	
	err := db.QueryRow(query, policyNumber).Scan(&id, &policyName, &description)
	
	if err == sql.ErrNoRows {
		log.Println("HandleInsuranceLookup: No insurance record found for policy number:", policyNumber)
		c.JSON(http.StatusNotFound, gin.H{"error": "No insurance record found for the provided policy number"})
		return
	} else if err != nil {
		log.Println("HandleInsuranceLookup: Error querying insurance data:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve insurance data"})
		return
	}

	// Return the insurance data (premium data is never included)
	insuranceData := Insurance{
		ID:          id,
		PolicyName:  policyName,
		Description: description,
	}
	c.JSON(http.StatusOK, insuranceData)
}

func SetupInsuranceRoutes(router *gin.Engine, db *sql.DB) {
	router.GET("/insurance", func(c *gin.Context) {
		HandleInsuranceLookup(c, db)
	})
}
