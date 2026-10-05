# LIMS 備品管理システム

Ubuntu 24.04以降へDebianパッケージとして導入する備品管理システムです。通常運用ではDocker ComposeやMySQLを直接操作せず、`limsctl` を使用します。

## 導入

APTリポジトリ公開後の導入手順です。

```bash
sudo apt update
sudo apt install lims-system
sudo limsctl init
```

`init` は初回のみ、設定の作成、MySQLの初期化、backend/frontendの起動、OS起動時の自動起動を行います。初期化済みの場合は既存のデータを変更せず終了します。

管理コマンドは以下です。

```bash
sudo limsctl start
sudo limsctl stop
sudo limsctl restart
sudo limsctl status
sudo limsctl logs
```

パッケージの削除や更新では `/var/lib/lims/mysql` のMySQLデータを削除しません。

## ローカルでのパッケージ生成

Docker Engineを起動したLinux、WSL、またはDocker Desktopから実行します。

```bash
bash scripts/build-deb.sh
```

ビルド専用コンテナ内でGoバイナリと`.deb`を生成します。成果物は `dist/` に出力されます。詳細な検証手順は [docs/operations.md](docs/operations.md) を参照してください。

alpha版のGitHub Release手順は [docs/release.md](docs/release.md) を参照してください。

## ドキュメント

運用手順、リリース手順、設計資料、旧バージョンのDB仕様は [docs/README.md](docs/README.md) に集約しています。

## 構成

- `frontend/`: 静的フロントエンド
- `backend/`: Go/MySQL API
- `deploy/`: Docker Compose、nginx、初期設定
- `packaging/debian/`: Debianパッケージ定義
- `scripts/`: `limsctl` とビルド補助スクリプト
- `docs/`: 運用・パッケージ資料
