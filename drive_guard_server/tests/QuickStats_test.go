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

func TestQuickStatsEndpoint(t *testing.T) {
	// Mock database connection
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("An error '%s' was not expected when opening a stub database connection", err)
	}
	defer db.Close()

	// Set up Gin router
	gin.SetMode(gin.TestMode)
	router := gin.Default()
	AdminInfo.SetupStatsRoutes(router, db)

	// Test successful stats retrieval
	t.Run("Get Statistics", func(t *testing.T) {
		// Set up expectations for each of the three queries
		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM users WHERE class = 'user'`).
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(150))

		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM users WHERE class = 'admin'`).
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(10))

		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM users WHERE class = 'insurance'`).
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(25))

		// Create request and recorder
		req, _ := http.NewRequest("GET", "/admin/stats", nil)
		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		// Check if the status code is as expected
		assert.Equal(t, http.StatusOK, resp.Code)

		// Unmarshal response
		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)

		// Check statistics values
		assert.Equal(t, float64(150), response["total_users"])
		assert.Equal(t, float64(10), response["total_admins"])
		assert.Equal(t, float64(25), response["total_insurance"])

		// Verify that all expectations were met
		if err := mock.ExpectationsWereMet(); err != nil {
			t.Errorf("there were unfulfilled expectations: %s", err)
		}
	})

	// Test database error in users count
	t.Run("Database Error - Users Count", func(t *testing.T) {
		// Set up an error for the first query
		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM users WHERE class = 'user'`).
			WillReturnError(sqlmock.ErrCancelled)

		// Create request and recorder
		req, _ := http.NewRequest("GET", "/admin/stats", nil)
		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		// Check if the status code is as expected
		assert.Equal(t, http.StatusInternalServerError, resp.Code)

		// Unmarshal response
		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)

		// Check error message
		assert.Equal(t, "Failed to retrieve user statistics", response["error"])
	})

	// Test database error in admins count
	t.Run("Database Error - Admins Count", func(t *testing.T) {
		// Set up success for the first query and error for the second
		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM users WHERE class = 'user'`).
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(150))

		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM users WHERE class = 'admin'`).
			WillReturnError(sqlmock.ErrCancelled)

		// Create request and recorder
		req, _ := http.NewRequest("GET", "/admin/stats", nil)
		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		// Check if the status code is as expected
		assert.Equal(t, http.StatusInternalServerError, resp.Code)

		// Unmarshal response
		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)

		// Check error message
		assert.Equal(t, "Failed to retrieve admin statistics", response["error"])
	})

	// Test database error in insurance count
	t.Run("Database Error - Insurance Count", func(t *testing.T) {
		// Set up success for the first two queries and error for the third
		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM users WHERE class = 'user'`).
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(150))

		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM users WHERE class = 'admin'`).
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(10))

		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM users WHERE class = 'insurance'`).
			WillReturnError(sqlmock.ErrCancelled)

		// Create request and recorder
		req, _ := http.NewRequest("GET", "/admin/stats", nil)
		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		// Check if the status code is as expected
		assert.Equal(t, http.StatusInternalServerError, resp.Code)

		// Unmarshal response
		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)

		// Check error message
		assert.Equal(t, "Failed to retrieve insurance statistics", response["error"])
	})

	// Test stats-test endpoint
	t.Run("Stats Test Endpoint", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/stats-test", nil)
		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		assert.Equal(t, http.StatusOK, resp.Code)

		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)
		
		// Check test endpoint response
		assert.Equal(t, "success", response["status"])
		assert.Equal(t, "Stats test endpoint is working", response["message"])
	})
}
