package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"strings"

	_ "IRIS-backend/docs"
	"IRIS-backend/internal/app/server"
	"IRIS-backend/internal/platform/auth"
	"IRIS-backend/internal/platform/db"
)

const (
	defaultConfigPath     = "config/config.yaml"
	bootstrapAdminCommand = "bootstrap-admin"
)

// @title           LIMS-back API
// @version         2.0
// @description     This is the API server for the LIMS backend.
// @termsOfService  http://swagger.io/terms/
//
// @contact.name   API Support
// @contact.url    http://www.swagger.io/support
// @contact.email  support@swagger.io
//
// @license.name  Apache 2.0
// @license.url   http://www.apache.org/licenses/LICENSE-2.0.html
//
// @host      localhost:8443
// @BasePath  /api/v2
//
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
//
// main はアプリケーションのエントリーポイントです。
// Swagger のドキュメンテーションを生成するために、`swag init -g cmd/server/main.go` を実行してください。
func main() {
	if len(os.Args) > 1 && os.Args[1] == bootstrapAdminCommand {
		if err := runBootstrapAdmin(os.Args[2:], os.Stdout); err != nil {
			log.Fatalf("[FATAL] %v", err)
		}
		return
	}

	configPath, err := parseConfigPath(os.Args[1:])
	if err != nil {
		log.Fatalf("[FATAL] failed to parse arguments: %v", err)
	}

	if err := server.Run(configPath); err != nil {
		log.Fatalf("[FATAL] %v", err)
	}
}

func runBootstrapAdmin(args []string, output io.Writer) error {
	configPath, userID, err := parseBootstrapAdminArgs(args)
	if err != nil {
		return fmt.Errorf("初期管理者の引数を解釈できません: %w", err)
	}

	cfg, err := db.LoadConfig(configPath)
	if err != nil {
		return fmt.Errorf("初期管理者用の設定を読み込めません: %w", err)
	}

	conn, err := db.Connect(cfg.DB)
	if err != nil {
		return fmt.Errorf("初期管理者用のDB接続に失敗しました: %w", err)
	}
	defer conn.Close()

	password, err := auth.NewBootstrapService(conn).BootstrapSuperAdmin(context.Background(), userID)
	if err != nil {
		return fmt.Errorf("初期管理者の作成または復旧に失敗しました: %w", err)
	}

	_, err = fmt.Fprintf(output, "[OK] 初期管理者を作成または復旧しました。\nユーザー名: %s\n一時パスワード: %s\nこのパスワードは再表示できません。安全な場所に記録してください。\n", userID, password)
	return err
}

func parseConfigPath(args []string) (string, error) {
	fs := flag.NewFlagSet("server", flag.ContinueOnError)
	fs.SetOutput(io.Discard)

	configPath := fs.String("config", defaultConfigPath, "path to config file")

	if err := fs.Parse(args); err != nil {
		return "", err
	}
	if fs.NArg() > 0 {
		return "", fmt.Errorf("unexpected positional arguments: %s", strings.Join(fs.Args(), " "))
	}

	return *configPath, nil
}

func parseBootstrapAdminArgs(args []string) (string, string, error) {
	fs := flag.NewFlagSet(bootstrapAdminCommand, flag.ContinueOnError)
	fs.SetOutput(io.Discard)

	configPath := fs.String("config", defaultConfigPath, "path to config file")
	userID := fs.String("username", "", "administrator username")

	if err := fs.Parse(args); err != nil {
		return "", "", err
	}
	if fs.NArg() > 0 {
		return "", "", fmt.Errorf("unexpected positional arguments: %s", strings.Join(fs.Args(), " "))
	}
	if *userID == "" {
		return "", "", fmt.Errorf("--username is required")
	}

	return *configPath, *userID, nil
}
