#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# 設定
# ============================================================

CONTAINER_NAME="lims-db"
DB_NAME="lims_v1"
DB_USER="root"
DB_PASSWORD="test1234"

BACKUP_DIR="/opt/db-backups"
RETENTION_DAYS=7

# gzip圧縮レベル
GZIP_LEVEL="6"

# ============================================================
# 表示用
# ============================================================

log() {
    echo "[$(date '+%F %T')] $1"
}

error_exit() {
    echo "[$(date '+%F %T')] ERROR: $1" >&2
    exit 1
}

# ============================================================
# 事前確認
# ============================================================

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        error_exit "必要なコマンドが見つかりません: $cmd"
    fi
}

require_command docker
require_command gzip
require_command find
require_command date

if ! docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
    error_exit "対象コンテナが起動していません: $CONTAINER_NAME"
fi

mkdir -p "$BACKUP_DIR"

# ============================================================
# バックアップ
# ============================================================

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
TMP_FILE="${BACKUP_DIR}/.${DB_NAME}_${TIMESTAMP}.sql.gz.tmp"
FINAL_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql.gz"

log "backup start: ${FINAL_FILE}"

if docker exec "$CONTAINER_NAME" sh -c \
    "exec mysqldump -u${DB_USER} -p${DB_PASSWORD} --single-transaction --quick --routines --triggers ${DB_NAME}" \
    | gzip -"${GZIP_LEVEL}" > "$TMP_FILE"
then
    mv "$TMP_FILE" "$FINAL_FILE"
    log "backup done: ${FINAL_FILE}"
else
    rm -f "$TMP_FILE"
    error_exit "mysqldump に失敗しました"
fi

# ============================================================
# 古いバックアップ削除
# ============================================================

log "cleanup start: deleting backups older than ${RETENTION_DAYS} days"

find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +"$RETENTION_DAYS" -print -delete

log "cleanup done"