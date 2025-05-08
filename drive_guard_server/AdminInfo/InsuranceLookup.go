
package AdminInfo

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Insurance represents an insurance record with full details
type Insurance struct {
	ID          int    `json:"id"`
	PolicyName  string `json:"policy_name"`
	Description string `json:"description"`
	Premium     string `json:"premium,omitempty"` // omitempty will skip this field if it's empty
}

// PublicInsurance represents an insurance record with restricted information
// for public or non-admin access
type PublicInsurance struct {
	ID          int    `json:"id"`
	PolicyName  string `json:"policy_name"`
	Description string `json:"description"`
}

// HandleInsuranceLookup handles insurance lookup requests with role-based access control
func HandleInsuranceLookup(c *gin.Context, db *sql.DB) {
	// Handles insurance lookup requests
	policyNumber := c.Query("policyNumber") // Retrieve policy number from query parameters
	if policyNumber == "" {
		log.Println("HandleInsuranceLookup: Policy number is missing")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Policy number is required"})
		return
	}

	// Get user role from context (this assumes your authentication middleware
	// adds the user role to the context - adjust as needed for your actual setup)
	userRole, exists := c.Get("userRole")
	
	// Query insurance data for the specific policy number
	query := `SELECT id, policy_name, description, premium FROM insurance WHERE policy_name = $1`
	
	var id int
	var policyName, description, premium string
	
	err := db.QueryRow(query, policyNumber).Scan(&id, &policyName, &description, &premium)
	
	if err == sql.ErrNoRows {
		log.Println("HandleInsuranceLookup: No insurance record found for policy number:", policyNumber)
		c.JSON(http.StatusNotFound, gin.H{"error": "No insurance record found for the provided policy number"})
		return
	} else if err != nil {
		log.Println("HandleInsuranceLookup: Error querying insurance data:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve insurance data"})
		return
	}

	// Return appropriate data based on user role
	if exists && (userRole == "admin" || userRole == "insurance") {
		// Admin and insurance providers can see all details including premium
		fullData := Insurance{
			ID:          id,
			PolicyName:  policyName,
			Description: description,
			Premium:     premium,
		}
		c.JSON(http.StatusOK, fullData)
	} else {
		// Regular users and unauthenticated requests get limited data
		publicData := PublicInsurance{
			ID:          id,
			PolicyName:  policyName,
			Description: description,
		}
		c.JSON(http.StatusOK, publicData)
	}
}

func SetupInsuranceRoutes(router *gin.Engine, db *sql.DB) {
	router.GET("/insurance", func(c *gin.Context) {
		HandleInsuranceLookup(c, db)
	})

	router.GET("/insurance-test", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "success",
			"message": "Insurance test endpoint is working",
		})
	})
}
