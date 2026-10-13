package auth

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/base64"
	"fmt"
	"regexp"

	"golang.org/x/crypto/bcrypt"
)

const (
	bootstrapPasswordBytes = 24
	bootstrapAdminIDMaxLen = 64
)

var bootstrapAdminIDPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._-]*$`)

type BootstrapAdminStore interface {
	BootstrapSuperAdmin(ctx context.Context, id, passwordHash string) error
}

// BootstrapService creates or recovers a super administrator without retaining
// the generated plaintext password after the caller receives it.
type BootstrapService struct {
	store BootstrapAdminStore
}

func NewBootstrapService(db *sql.DB) *BootstrapService {
	return newBootstrapService(&Store{db: db})
}

func newBootstrapService(store BootstrapAdminStore) *BootstrapService {
	return &BootstrapService{store: store}
}

func (s *BootstrapService) BootstrapSuperAdmin(ctx context.Context, id string) (string, error) {
	if err := validateBootstrapAdminID(id); err != nil {
		return "", err
	}

	password, err := generateBootstrapPassword()
	if err != nil {
		return "", fmt.Errorf("初期管理者パスワードの生成に失敗しました: %w", err)
	}

	passwordHash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", fmt.Errorf("初期管理者パスワードのハッシュ化に失敗しました: %w", err)
	}

	if err := s.store.BootstrapSuperAdmin(ctx, id, string(passwordHash)); err != nil {
		return "", err
	}

	return password, nil
}

func validateBootstrapAdminID(id string) error {
	if len(id) == 0 || len(id) > bootstrapAdminIDMaxLen || !bootstrapAdminIDPattern.MatchString(id) {
		return fmt.Errorf("管理者IDは英数字で始まる%d文字以下の英数字、ハイフン、アンダースコア、ピリオドで指定してください", bootstrapAdminIDMaxLen)
	}
	return nil
}

func generateBootstrapPassword() (string, error) {
	randomBytes := make([]byte, bootstrapPasswordBytes)
	if _, err := rand.Read(randomBytes); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(randomBytes), nil
}
