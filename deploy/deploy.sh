#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# 設定
# ============================================================

REPO2_URL="https://github.com/koki0423/lims-front-v3.git"
REPO3_URL="https://github.com/koki0423/LIMS-back.git"

REPO2_DIR_NAME=""
REPO3_DIR_NAME=""

SCRIPT_VERSION="deploy.sh v2026-04-15-final"

BACKEND_BINARY_NAME="server"
SERVICE_NAME="lims-backend"

BACKUP_SOURCE_RELATIVE_PATH="./scripts/mysql_backup.sh"
BACKUP_DEST_PATH="/opt/scripts/mysql_backup.sh"
BACKUP_CRON_LINE='0 0 * * * /opt/scripts/mysql_backup.sh >> /var/log/mysql_backup.log 2>&1'

# ============================================================
# 表示用
# ============================================================

write_step() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

write_info() {
    echo "[INFO] $1"
}

write_warn() {
    echo "[WARN] $1"
}

write_success() {
    echo "[ OK ] $1"
}

write_error() {
    echo "[ERR ] $1" >&2
}

# ============================================================
# 共通処理
# ============================================================

get_repo_name_from_url() {
    local url="$1"
    local name

    name="$(basename "$url")"
    if [[ "$name" == *.git ]]; then
        name="${name%.git}"
    fi

    echo "$name"
}

run_checked() {
    local workdir="$1"
    shift

    (
        cd "$workdir"
        "$@"
    )
}

ensure_sudo() {
    if ! command -v sudo >/dev/null 2>&1; then
        write_error "sudo が見つかりません。sudo をインストールしてください。"
        exit 1
    fi
}

ensure_snap_path_for_current_shell() {
    if command -v go >/dev/null 2>&1; then
        return
    fi

    if [[ -x "/snap/bin/go" ]]; then
        export PATH="/snap/bin:$PATH"
    fi
}

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        write_error "必要なコマンドが見つかりません: $cmd"
        exit 1
    fi
}

# ============================================================
# Docker
# ============================================================

install_docker_if_needed() {
    if command -v docker >/dev/null 2>&1; then
        write_info "Docker は既にインストール済みです。"
        return
    fi

    write_step "[Docker] Docker を apt でインストールしています"

    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg

    sudo install -m 0755 -d /etc/apt/keyrings

    if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
            | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
    fi

    local arch
    local codename
    arch="$(dpkg --print-architecture)"
    codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"

    echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    write_success "Docker のインストールが完了しました。"
}

setup_docker_group() {
    write_step "[Docker] sudo なしで docker を使えるように設定しています"

    if ! getent group docker >/dev/null 2>&1; then
        sudo groupadd docker
        write_info "docker グループを作成しました。"
    fi

    if id -nG "$USER" | grep -qw docker; then
        write_info "現在のユーザーは既に docker グループに所属しています。"
    else
        sudo usermod -aG docker "$USER"
        write_warn "現在のユーザーを docker グループへ追加しました。"
        write_warn "この反映には、再ログインまたは newgrp docker が必要です。"
    fi
}

verify_docker_compose_available() {
    if docker compose version >/dev/null 2>&1; then
        write_info "docker compose は利用可能です。"
        return
    fi

    write_warn "現在のシェルでは sudo なしの docker 実行がまだ反映されていない可能性があります。"
    write_warn "再ログイン後または newgrp docker 実行後に、再度 deploy.sh を実行してください。"
    exit 1
}

# ============================================================
# Go / 基本パッケージ
# ============================================================

install_base_packages_if_needed() {
    write_step "[準備] 必要なパッケージを確認しています"

    sudo apt-get update
    sudo apt-get install -y git curl snapd

    if command -v go >/dev/null 2>&1; then
        write_info "Go は既にインストール済みです。"
        return
    fi

    write_step "[Go] Go を snap でインストールしています"
    sudo snap install go --classic
    ensure_snap_path_for_current_shell

    if ! command -v go >/dev/null 2>&1; then
        write_error "Go のインストール後も go コマンドが見つかりません。再ログイン後に再実行してください。"
        exit 1
    fi

    write_success "Go のインストールが完了しました。"
}

# ============================================================
# リポジトリ
# ============================================================

clone_if_missing() {
    local parent_dir="$1"
    local repo_url="$2"
    local dir_name="$3"
    local label="$4"

    local target_path="${parent_dir}/${dir_name}"

    if [[ -d "$target_path" ]]; then
        write_info "${label} は既に存在するため、clone をスキップします。"
        return
    fi

    write_warn "${label} が見つからないため、clone します。"
    run_checked "$parent_dir" git clone "$repo_url" "$dir_name"
    write_success "${label} の clone が完了しました。"
}

# ============================================================
# systemd
# ============================================================

create_or_update_systemd_service() {
    local backend_path="$1"
    local binary_path="$2"
    local service_path="/etc/systemd/system/${SERVICE_NAME}.service"

    write_step "[systemd] バックエンド常駐サービスを設定しています"

    if [[ -f "$service_path" ]]; then
        write_info "既存の systemd service を更新します: $service_path"
    else
        write_info "新しく systemd service を作成します: $service_path"
    fi

    sudo tee "$service_path" >/dev/null <<EOF
[Unit]
Description=LIMS Backend Service
After=network.target docker.service
Wants=docker.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$backend_path
ExecStart=$binary_path
Restart=always
RestartSec=5
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable "${SERVICE_NAME}.service" >/dev/null 2>&1 || true
    sudo systemctl restart "${SERVICE_NAME}.service"

    write_success "systemd service の設定と再起動が完了しました。"
}

# ============================================================
# バックアップ
# ============================================================

install_backup_script() {
    local script_dir="$1"
    local backup_source_path

    backup_source_path="${script_dir}/${BACKUP_SOURCE_RELATIVE_PATH#./}"

    write_step "[バックアップ] バックアップスクリプトを配置しています"

    if [[ ! -f "$backup_source_path" ]]; then
        write_error "バックアップスクリプトが見つかりません: $backup_source_path"
        exit 1
    fi

    sudo mkdir -p /opt/scripts
    sudo cp "$backup_source_path" "$BACKUP_DEST_PATH"
    sudo chmod +x "$BACKUP_DEST_PATH"

    write_success "バックアップスクリプトを配置しました: $BACKUP_DEST_PATH"
}

register_backup_cron() {
    write_step "[バックアップ] crontab に定期実行を登録しています"

    local current_cron
    current_cron=""

    if crontab -l >/dev/null 2>&1; then
        current_cron="$(crontab -l)"
    fi

    if printf '%s\n' "$current_cron" | grep -Fqx "$BACKUP_CRON_LINE"; then
        write_info "バックアップ用 cron は既に登録済みです。"
        return
    fi

    if [[ -n "$current_cron" ]]; then
        {
            printf '%s\n' "$current_cron"
            printf '%s\n' "$BACKUP_CRON_LINE"
        } | crontab -
    else
        printf '%s\n' "$BACKUP_CRON_LINE" | crontab -
    fi

    write_success "バックアップ用 cron を登録しました。"
}

# ============================================================
# メイン処理
# ============================================================

main() {
    echo "実行スクリプト: $0"
    echo "バージョン: $SCRIPT_VERSION"

    ensure_sudo

    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"

    if [[ -z "$REPO2_DIR_NAME" ]]; then
        REPO2_DIR_NAME="$(get_repo_name_from_url "$REPO2_URL")"
    fi

    if [[ -z "$REPO3_DIR_NAME" ]]; then
        REPO3_DIR_NAME="$(get_repo_name_from_url "$REPO3_URL")"
    fi

    local env_repo_path
    local frontend_path
    local backend_base_path
    local repo2_path
    local repo3_path
    local backend_binary_path
    local docs_go_path
    local compose_path

    env_repo_path="$script_dir"
    frontend_path="${env_repo_path}/frontend"
    backend_base_path="${env_repo_path}/backend"
    repo2_path="${frontend_path}/${REPO2_DIR_NAME}"
    repo3_path="${backend_base_path}/${REPO3_DIR_NAME}"
    backend_binary_path="${repo3_path}/${BACKEND_BINARY_NAME}"
    docs_go_path="${repo3_path}/docs/docs.go"
    compose_path="${env_repo_path}/docker-compose.yml"

    write_step "[1/9] 事前準備をしています"
    install_docker_if_needed
    setup_docker_group
    install_base_packages_if_needed
    ensure_snap_path_for_current_shell

    require_command git
    require_command go
    require_command docker
    verify_docker_compose_available

    write_step "[2/9] ディレクトリ構成を確認しています"

    if [[ ! -d "$frontend_path" ]]; then
        write_error "frontend フォルダが見つかりません: $frontend_path"
        exit 1
    fi

    if [[ ! -d "$backend_base_path" ]]; then
        mkdir -p "$backend_base_path"
        write_info "backend フォルダを新規作成しました。"
    fi

    if [[ ! -f "$compose_path" ]]; then
        write_error "docker-compose.yml が見つかりません: $compose_path"
        exit 1
    fi

    write_step "[3/9] 必要なリポジトリを確認しています"
    clone_if_missing "$frontend_path" "$REPO2_URL" "$REPO2_DIR_NAME" "フロントエンド"
    clone_if_missing "$backend_base_path" "$REPO3_URL" "$REPO3_DIR_NAME" "バックエンド"

    if [[ ! -d "$repo3_path" ]]; then
        write_error "バックエンドフォルダが見つかりません: $repo3_path"
        exit 1
    fi

    write_step "[4/9] Swagger ドキュメントを生成しています"
    run_checked "$repo3_path" go run github.com/swaggo/swag/cmd/swag@latest init -g main.go -o docs

    if [[ ! -f "$docs_go_path" ]]; then
        write_error "Swagger ドキュメントの生成に失敗しました: $docs_go_path"
        exit 1
    fi

    write_success "Swagger ドキュメントの生成が完了しました。"

    write_step "[5/9] バックエンドをビルドしています"
    run_checked "$repo3_path" go mod tidy
    run_checked "$repo3_path" go build -o "$BACKEND_BINARY_NAME" .

    if [[ ! -f "$backend_binary_path" ]]; then
        write_error "バックエンドバイナリの作成に失敗しました: $backend_binary_path"
        exit 1
    fi

    write_success "バックエンドのビルドが完了しました。"

    write_step "[6/9] Docker コンテナを起動しています"
    run_checked "$env_repo_path" docker compose up -d
    write_success "Docker コンテナの起動が完了しました。"

    write_step "[7/9] systemd を設定しています"
    create_or_update_systemd_service "$repo3_path" "$backend_binary_path"

    write_step "[8/9] バックアップスクリプトを配置しています"
    install_backup_script "$script_dir"

    write_step "[9/9] バックアップ cron を設定しています"
    register_backup_cron

    echo
    write_success "セットアップが完了しました。"
    write_info "フロントエンド: http://localhost"
    write_info "systemd 状態確認: systemctl status ${SERVICE_NAME}"
    write_info "systemd ログ確認: journalctl -u ${SERVICE_NAME} -n 100 --no-pager"
    write_info "cron 確認: crontab -l"
    write_info "Docker 確認: docker compose ps"
}

main "$@"