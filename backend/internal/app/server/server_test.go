package server

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"

	"IRIS-backend/internal/platform/db"
)

func TestPrintTemplateRouteIsRegistered(t *testing.T) {
	cfg := &db.Config{Mode: modeRelease}
	router := newRouter(modeRelease, nil, cfg, nil)

	for _, route := range router.Routes() {
		if route.Method == "GET" && route.Path == "/api/v2/assets/print/templates" {
			return
		}
	}

	t.Fatal("expected print template route to be registered")
}

func TestAdminMasterEditRouteRequiresAuthentication(t *testing.T) {
	cfg := &db.Config{Mode: modeRelease}
	router := newRouter(modeRelease, nil, cfg, nil)

	req := httptest.NewRequest(http.MethodPut, "/api/v2/admin/assets/1/master-edit", bytes.NewBufferString(`{}`))
	req.Header.Set("Content-Type", "application/json")
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want %d", res.Code, http.StatusUnauthorized)
	}
}

func TestPublicAssetUpdateRejectsSerialNumber(t *testing.T) {
	cfg := &db.Config{Mode: modeRelease}
	router := newRouter(modeRelease, nil, cfg, nil)

	req := httptest.NewRequest(http.MethodPut, "/api/v2/assets/1", bytes.NewBufferString(`{"serial":"ABC-123"}`))
	req.Header.Set("Content-Type", "application/json")
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want %d", res.Code, http.StatusForbidden)
	}
}
