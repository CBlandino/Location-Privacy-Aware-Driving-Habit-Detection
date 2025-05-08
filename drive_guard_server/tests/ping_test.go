package tests

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"drive_guard_server/AdminInfo"
)

func TestPingEndpoint(t *testing.T) {
	// Set up Gin router
	gin.SetMode(gin.TestMode)
	router := gin.Default()
	AdminInfo.SetupPingRoutes(router)

	// Test ping endpoint
	t.Run("Ping Response", func(t *testing.T) {
		// Create request and recorder
		req, _ := http.NewRequest("GET", "/ping", nil)
		resp := httptest.NewRecorder()
		
		// Serve the request
		router.ServeHTTP(resp, req)

		// Check if the status code is 200 OK
		assert.Equal(t, http.StatusOK, resp.Code)

		// Unmarshal response
		var response map[string]interface{}
		err := json.Unmarshal(resp.Body.Bytes(), &response)
		assert.NoError(t, err)

		// Check if message is "pong"
		assert.Equal(t, "pong", response["message"])
	})
}
