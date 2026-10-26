package printLabels

import (
	"bytes"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestDownloadTemplateServesEmbeddedTemplates(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	RegisterRoutes(router, NewService())

	for _, tc := range []struct {
		width int
		type_ string
	}{
		{width: 9, type_: "qrcode"},
		{width: 9, type_: "code128"},
		{width: 12, type_: "qrcode"},
		{width: 12, type_: "code128"},
		{width: 18, type_: "qrcode"},
		{width: 18, type_: "code128"},
	} {
		t.Run(fmt.Sprintf("%dmm_%s", tc.width, tc.type_), func(t *testing.T) {
			filename := fmt.Sprintf("%d_%s.lw1", tc.width, tc.type_)
			want, err := os.ReadFile(filepath.Join("templates", filename))
			if err != nil {
				t.Fatalf("read source template: %v", err)
			}

			req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/assets/print/templates?width=%d&type=%s", tc.width, tc.type_), nil)
			res := httptest.NewRecorder()
			router.ServeHTTP(res, req)

			if res.Code != http.StatusOK {
				t.Fatalf("status = %d, want %d; body = %s", res.Code, http.StatusOK, res.Body.String())
			}
			if got := res.Header().Get("Content-Type"); got != "application/octet-stream" {
				t.Errorf("Content-Type = %q, want %q", got, "application/octet-stream")
			}
			if got, wantHeader := res.Header().Get("Content-Disposition"), fmt.Sprintf("attachment; filename=%q", filename); got != wantHeader {
				t.Errorf("Content-Disposition = %q, want %q", got, wantHeader)
			}
			if !bytes.Equal(res.Body.Bytes(), want) {
				t.Error("response body does not match the embedded template")
			}
		})
	}
}

func TestDownloadTemplateRejectsUnsupportedTemplate(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	RegisterRoutes(router, NewService())

	for _, path := range []string{
		"/assets/print/templates?width=6&type=qrcode",
		"/assets/print/templates?width=9&type=datamatrix",
	} {
		t.Run(path, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, path, nil)
			res := httptest.NewRecorder()
			router.ServeHTTP(res, req)

			if res.Code != http.StatusBadRequest {
				t.Fatalf("status = %d, want %d; body = %s", res.Code, http.StatusBadRequest, res.Body.String())
			}
		})
	}
}
