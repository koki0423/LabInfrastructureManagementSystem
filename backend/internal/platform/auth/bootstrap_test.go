package auth

import (
	"context"
	"errors"
	"testing"

	"golang.org/x/crypto/bcrypt"
)

type bootstrapAdminStoreStub struct {
	id           string
	passwordHash string
	err          error
}

func (s *bootstrapAdminStoreStub) BootstrapSuperAdmin(_ context.Context, id, passwordHash string) error {
	s.id = id
	s.passwordHash = passwordHash
	return s.err
}

func TestBootstrapSuperAdminGeneratesAndHashesPassword(t *testing.T) {
	store := &bootstrapAdminStoreStub{}
	service := newBootstrapService(store)

	password, err := service.BootstrapSuperAdmin(context.Background(), "sys-super-admin")
	if err != nil {
		t.Fatalf("BootstrapSuperAdmin() error = %v", err)
	}
	if store.id != "sys-super-admin" {
		t.Fatalf("stored ID = %q, want sys-super-admin", store.id)
	}
	if len(password) != 32 {
		t.Fatalf("password length = %d, want 32", len(password))
	}
	if err := bcrypt.CompareHashAndPassword([]byte(store.passwordHash), []byte(password)); err != nil {
		t.Fatalf("generated password does not match stored bcrypt hash: %v", err)
	}
}

func TestBootstrapSuperAdminRejectsInvalidID(t *testing.T) {
	store := &bootstrapAdminStoreStub{}
	service := newBootstrapService(store)

	if _, err := service.BootstrapSuperAdmin(context.Background(), "invalid id"); err == nil {
		t.Fatal("BootstrapSuperAdmin() error = nil, want invalid ID error")
	}
	if store.id != "" {
		t.Fatalf("store was called for invalid ID: %q", store.id)
	}
}

func TestBootstrapSuperAdminDoesNotReturnPasswordOnStoreFailure(t *testing.T) {
	store := &bootstrapAdminStoreStub{err: errors.New("store failure")}
	service := newBootstrapService(store)

	password, err := service.BootstrapSuperAdmin(context.Background(), "sys-super-admin")
	if err == nil {
		t.Fatal("BootstrapSuperAdmin() error = nil, want store failure")
	}
	if password != "" {
		t.Fatal("BootstrapSuperAdmin() returned a password after store failure")
	}
}
