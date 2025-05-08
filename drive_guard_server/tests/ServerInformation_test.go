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

func TestServerInfoEndpoint(t *testing.T) {
	// Mock database connection
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("An error '%s' was not expected when opening a stub database connection", err)
	}
	defer db.Close()

	// Set up Gin router
	gin.SetMode(gin.TestMode)
	router := gin.Default()
	AdminInfo.SetupServerRoutes(router, db)

	// Test with specific server ID
	t.Run("Valid Server ID", func(t *testing.T) {
		// Set up expected query with server ID = 1
		rows := sqlmock.NewRows([]string{"id", "base_url", "port", "api_key"}).
			AddRow(1, "https://api.example.com", "8080", "test-api-key-123")
		
		mock.ExpectQuery(`SELECT id, base_url, port, api_key FROM server_information WHERE id = \$1`).
			WithArgs("1").
			WillReturnRows(rows)

		req, _ := http.NewRequest("GET", "/server-info?server_id=1", nil)
		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		assert.Equal(t, http.StatusOK, resp.Code)

		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)
		
		// Check server info fields
		assert.Equal(t, float64(1), response["id"])
		assert.Equal(t, "https://api.example.com", response["base_url"])
		assert.Equal(t, "8080", response["port"])
		assert.Equal(t, "test-api-key-123", response["api_key"])
	})

	// Test with no server ID (should use default)
	t.Run("Default Server ID", func(t *testing.T) {
		// Set up expected query with default server ID = 1
		rows := sqlmock.NewRows([]string{"id", "base_url", "port", "api_key"}).
			AddRow(1, "https://api.example.com", "8080", "test-api-key-123")
		
		mock.ExpectQuery(`SELECT id, base_url, port, api_key FROM server_information WHERE id = \$1`).
			WithArgs("1").
			WillReturnRows(rows)

		req, _ := http.NewRequest("GET", "/server-info", nil)
		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		assert.Equal(t, http.StatusOK, resp.Code)

		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)
		
		// Check server info fields
		assert.Equal(t, float64(1), response["id"])
		assert.Equal(t, "https://api.example.com", response["base_url"])
		assert.Equal(t, "8080", response["port"])
		assert.Equal(t, "test-api-key-123", response["api_key"])
	})

	// Test server not found
	t.Run("Server Not Found", func(t *testing.T) {
		// Mock the "no rows" scenario
		mock.ExpectQuery(`SELECT id, base_url, port, api_key FROM server_information WHERE id = \$1`).
			WithArgs("999").
			WillReturnRows(sqlmock.NewRows([]string{"id", "base_url", "port", "api_key"})) // Empty result set

		req, _ := http.NewRequest("GET", "/server-info?server_id=999", nil)
		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		assert.Equal(t, http.StatusNotFound, resp.Code)

		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)
		
		// Check error message
		assert.Equal(t, "Server not found", response["error"])
	})

	// Test database error
	t.Run("Database Error", func(t *testing.T) {
		// Set up expected query with database error
		mock.ExpectQuery(`SELECT id, base_url, port, api_key FROM server_information WHERE id = \$1`).
			WithArgs("1").
			WillReturnError(sqlmock.ErrCancelled)

		req, _ := http.NewRequest("GET", "/server-info?server_id=1", nil)
		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		assert.Equal(t, http.StatusInternalServerError, resp.Code)

		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)
		
		// Check error message
		assert.Equal(t, "Failed to retrieve server information", response["error"])
	})

	// Test server-test endpoint
	t.Run("Server Test Endpoint", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/server-test", nil)
		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		assert.Equal(t, http.StatusOK, resp.Code)

		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)
		
		// Check test endpoint response
		assert.Equal(t, "success", response["status"])
		assert.Equal(t, "Server info test endpoint is working", response["message"])
	})
}
