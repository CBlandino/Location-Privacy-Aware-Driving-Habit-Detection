package tests

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"drive_guard_server/AdminInfo"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
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
	AdminInfo.SetupInsuranceRoutes(router, db)

	// Test valid policy number
	t.Run("Valid Policy Number", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{"id", "policy_name", "description"}).
			AddRow(1, "ABC12345", "Full Coverage Insurance")

		mock.ExpectQuery(`SELECT id, policy_name, description FROM insurance WHERE policy_name = \$1`).
			WithArgs("ABC12345").
			WillReturnRows(rows)

		req, _ := http.NewRequest("GET", "/insurance?policyNumber=ABC12345", nil)
		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		assert.Equal(t, http.StatusOK, resp.Code)

		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)

		// Check all fields except premium (which should never be returned)
		assert.Equal(t, float64(1), response["id"])
		assert.Equal(t, "ABC12345", response["policy_name"])
		assert.Equal(t, "Full Coverage Insurance", response["description"])
		assert.Nil(t, response["premium"]) // Premium should never be present
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
