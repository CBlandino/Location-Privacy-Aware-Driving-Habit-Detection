package tests

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"drive_guard_server/AdminInfo"
)

func TestGenerateIDEndpoint(t *testing.T) {
	// Mock database connection
	db, mock, _ := sqlmock.New()
	defer db.Close()

	// Set up Gin router
	router := gin.Default()
	AdminInfo.SetupIDRoutes(router, db)

	// Test valid user creation
	t.Run("Valid User Creation", func(t *testing.T) {
		newUser := map[string]string{
			"firstname": "John",
			"lastname":  "Doe",
			"email":     "john.doe@example.com",
			"password":  "securepassword",
			"role":      "user",
		}
		body, _ := json.Marshal(newUser)

		// Mock database behavior
		mock.ExpectQuery("INSERT INTO users").
			WithArgs("John", "Doe", "john.doe@example.com", "user", sqlmock.AnyArg(), sqlmock.AnyArg(), 1.0, 1.0, 1.0).
			WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(1))

		req, _ := http.NewRequest("POST", "/generate-id", bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")

		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		assert.Equal(t, http.StatusCreated, resp.Code)
		var response map[string]interface{}
		json.Unmarshal(resp.Body.Bytes(), &response)
		assert.Contains(t, response, "account_id")
	})

	// Test missing fields
	t.Run("Missing Fields", func(t *testing.T) {
		newUser := map[string]string{
			"firstname": "John",
			"lastname":  "Doe",
		}
		body, _ := json.Marshal(newUser)

		req, _ := http.NewRequest("POST", "/generate-id", bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")

		resp := httptest.NewRecorder()
		router.ServeHTTP(resp, req)

		assert.Equal(t, http.StatusBadRequest, resp.Code)
	})
}

