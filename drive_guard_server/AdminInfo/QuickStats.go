// QuickStats.go
package AdminInfo

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Stats represents the quick statistics about the system
type Stats struct {
	TotalUsers     int `json:"total_users"`
	TotalAdmins    int `json:"total_admins"`
	TotalInsurance int `json:"total_insurance"`
}

// HandleQuickStats fetches quick statistics about user accounts
func HandleQuickStats(c *gin.Context, db *sql.DB) {
	log.Println("HandleQuickStats: Function called")

	// Initialize stats struct
	var stats Stats

	// Query total number of users with role "user"
	userQuery := "SELECT COUNT(*) FROM users WHERE class = 'user'"
	err := db.QueryRow(userQuery).Scan(&stats.TotalUsers)
	if err != nil {
		log.Println("HandleQuickStats: Error counting users:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve user statistics"})
		return
	}

	// Query total number of admins
	adminQuery := "SELECT COUNT(*) FROM users WHERE class = 'admin'"
	err = db.QueryRow(adminQuery).Scan(&stats.TotalAdmins)
	if err != nil {
		log.Println("HandleQuickStats: Error counting admins:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve admin statistics"})
		return
	}

	// Query total number of insurance companies
	insuranceQuery := "SELECT COUNT(*) FROM users WHERE class = 'insurance'"
	err = db.QueryRow(insuranceQuery).Scan(&stats.TotalInsurance)
	if err != nil {
		log.Println("HandleQuickStats: Error counting insurance accounts:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve insurance statistics"})
		return
	}

	log.Println("HandleQuickStats: Statistics retrieved successfully")
	c.JSON(http.StatusOK, stats)
}

// SetupStatsRoutes registers the statistics routes with Gin
func SetupStatsRoutes(router *gin.Engine, db *sql.DB) {
	log.Println("SetupStatsRoutes: Registering routes")
	
	// Quick stats endpoint
	router.GET("/admin/stats", func(c *gin.Context) {
		log.Println("SetupStatsRoutes: /admin/stats route triggered")
		HandleQuickStats(c, db)
	})
	
	// Test endpoint that doesn't require database access
	router.GET("/stats-test", func(c *gin.Context) {
		log.Println("SetupStatsRoutes: /stats-test route triggered")
		c.JSON(http.StatusOK, gin.H{
			"status": "success",
			"message": "Stats test endpoint is working"})
	})
}
