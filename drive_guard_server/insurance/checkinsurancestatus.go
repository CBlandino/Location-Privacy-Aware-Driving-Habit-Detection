package insurance

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
)

type InsuranceStatusResponse struct {
	Complete bool `json:"insurance_info_complete"`
}

// CheckInsuranceStatus returns whether the logged-in user has completed insurance info
func CheckInsuranceStatus(c *gin.Context, db *sql.DB) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}
	userID := userIDRaw.(int)

	var driverLicense, zipCode, city, state string
	err := db.QueryRow(`
		SELECT driver_license, zip_code, city, state FROM user_insurance WHERE user_id = $1
	`, userID).Scan(&driverLicense, &zipCode, &city, &state)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusOK, InsuranceStatusResponse{Complete: false})
		return
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	isComplete := driverLicense != "" && zipCode != "" && city != "" && state != ""
	c.JSON(http.StatusOK, InsuranceStatusResponse{Complete: isComplete})
}
