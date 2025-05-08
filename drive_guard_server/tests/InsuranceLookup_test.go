package tests

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"drive_guard_server/AdminInfo"
)

func TestInsuranceLookupEndpoint(t *testing.T) {
	// Mock database connection
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("An error '%s' was not expected when opening a stub database connection", err)
	}
	defer db.Close()

	// Set up Gin router
	gin.SetMode(gin.TestMode)
	router := gin.Default()
	
	// Add a middleware to simulate authentication for some tests
	authenticatedRouter := gin.New()
	authenticatedRouter.Use(func(c *gin.Context) {
		// Set user role to admin for testing
		c.Set("userRole", "admin")
		c.Next()
	})
	
	// Setup routes on both routers
	AdminInfo.SetupInsuranceRoutes(router, db) // Unauthenticated router
	AdminInfo.SetupInsuranceRoutes(authenticatedRouter, db) // Admin router

	// Test valid policy number as regular user (should NOT get premium info)
	t.Run("Valid Policy Number - Regular User", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{"id", "policy_name", "description", "premium"}).
			AddRow(1, "ABC12345", "Full Coverage Insurance", "$150/month")
		
		mock.ExpectQuery(`SELECT id, policy_name, description, premium FROM insurance WHERE policy_name = \$1`).
			WithArgs("ABC12345").
			WillReturnRows(rows)

		req, _ := http.NewRequest("GET", "/insurance?policyNumber=ABC12345", nil)
		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req) // Using unauthenticated router

		assert.Equal(t, http.StatusOK, resp.Code)

		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)
		
		// Regular user should see public fields but NOT premium
		assert.Equal(t, float64(1), response["id"])
		assert.Equal(t, "ABC12345", response["policy_name"])
		assert.Equal(t, "Full Coverage Insurance", response["description"])
		assert.Nil(t, response["premium"]) // Premium should not be present
	})
	
	// Test valid policy number as admin (should get premium info)
	t.Run("Valid Policy Number - Admin User", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{"id", "policy_name", "description", "premium"}).
			AddRow(1, "ABC12345", "Full Coverage Insurance", "$150/month")
		
		mock.ExpectQuery(`SELECT id, policy_name, description, premium FROM insurance WHERE policy_name = \$1`).
			WithArgs("ABC12345").
			WillReturnRows(rows)

		req, _ := http.NewRequest("GET", "/insurance?policyNumber=ABC12345", nil)
		resp := httptest.NewRecorder()
		authenticatedRouter.ServeHTTP(resp, req) // Using admin router

		assert.Equal(t, http.StatusOK, resp.Code)

		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)
		
		// Admin should see ALL fields including premium
		assert.Equal(t, float64(1), response["id"])
		assert.Equal(t, "ABC12345", response["policy_name"])
		assert.Equal(t, "Full Coverage Insurance", response["description"])
		assert.Equal(t, "$150/month", response["premium"])
	})

	// Test missing policy number
	t.Run("Missing Policy Number", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/insurance", nil)
		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		assert.Equal(t, http.StatusBadRequest, resp.Code)

		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, "Policy number is required", response["error"])
	})
}
