package assets

import (
	"testing"
	"time"
)

func TestParseAssetSetFromCSVRowNormalizesUTC(t *testing.T) {
	col := map[string]int{
		"name":                   0,
		"management_category_id": 1,
		"genre_id":               2,
		"manufacturer":           3,
		"purchased_at":           4,
		"status_id":              5,
		"owner":                  6,
		"default_location":       7,
		"last_checked_at":        8,
	}
	rec := []string{
		"Sample",
		"1",
		"2",
		"Maker",
		"2026-05-07T09:00:00+09:00",
		"1",
		"HQ",
		"Rack-01",
		"2026-05-08T10:00:00+09:00",
	}

	got, err := parseAssetSetFromCSVRow(rec, col)
	if err != nil {
		t.Fatalf("parseAssetSetFromCSVRow returned error: %v", err)
	}

	if got.Asset.PurchasedAt.Location().String() != "UTC" {
		t.Fatalf("expected purchased_at in UTC, got %v", got.Asset.PurchasedAt.Location())
	}
	if got.Asset.PurchasedAt.Hour() != 0 {
		t.Fatalf("expected purchased_at converted to UTC midnight offset, got %v", got.Asset.PurchasedAt)
	}
	if got.Asset.LastCheckedAt == nil || got.Asset.LastCheckedAt.Location().String() != "UTC" {
		t.Fatalf("expected last_checked_at in UTC, got %v", got.Asset.LastCheckedAt)
	}
}

func TestNormalizeUpdateAssetRequestConvertsUTC(t *testing.T) {
	jst := time.FixedZone("JST", 9*60*60)
	purchasedAt := time.Date(2026, time.May, 7, 9, 0, 0, 0, jst)
	lastCheckedAt := time.Date(2026, time.May, 8, 18, 30, 0, 0, jst)

	got := normalizeUpdateAssetRequest(UpdateAssetRequest{
		PurchasedAt:   &purchasedAt,
		LastCheckedAt: &lastCheckedAt,
	})

	if got.PurchasedAt == nil || got.PurchasedAt.Location() != time.UTC {
		t.Fatalf("expected purchased_at UTC, got %v", got.PurchasedAt)
	}
	if got.LastCheckedAt == nil || got.LastCheckedAt.Location() != time.UTC {
		t.Fatalf("expected last_checked_at UTC, got %v", got.LastCheckedAt)
	}
}

func TestReplaceManagementNumberPrefixPreservesDateAndSequence(t *testing.T) {
	got, err := replaceManagementNumberPrefix("OFS-20261013-00042", "LAB")
	if err != nil {
		t.Fatalf("replaceManagementNumberPrefix returned error: %v", err)
	}
	if want := "LAB-20261013-00042"; got != want {
		t.Fatalf("management number = %q, want %q", got, want)
	}
}

func TestReplaceManagementNumberPrefixRejectsInvalidSource(t *testing.T) {
	if _, err := replaceManagementNumberPrefix("OFS", "LAB"); err == nil {
		t.Fatal("expected invalid management number error")
	}
}
