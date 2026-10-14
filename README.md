# LIMS 備品管理システム

Ubuntu 24.04以降へDebianパッケージとして導入する備品管理システムです。通常運用ではDocker ComposeやMySQLを直接操作せず、`limsctl` を使用します。

## 導入

APTリポジトリ公開後の導入手順です。

```bash
sudo apt update
sudo apt install lims-system
sudo limsctl init
```

`init` は初回のみ、設定の作成、MySQLの初期化、初期管理者の発行、backend/frontendの起動、OS起動時の自動起動を行います。最初にMySQL root用とアプリ用DBユーザーの認証情報を「自動生成」または「手入力」から選択します。自動生成を明示する場合は `sudo limsctl init --db-credentials auto`、手入力する場合は `sudo limsctl init --db-credentials manual` を実行してください。

初期化の最後に表示される初期管理者の一時パスワードは再表示できないため、安全な場所に記録してください。DB認証情報は `/etc/lims/lims.env` にだけ保存され、画面やログには表示しません。初期化済みの場合は既存の設定・認証情報・データを変更せず終了します。

管理コマンドは以下です。

```bash
sudo limsctl start
sudo limsctl stop
sudo limsctl restart
sudo limsctl status
sudo limsctl logs
sudo limsctl inituser <ユーザー名>
```

`inituser` は、初期パスワードを失った場合などにroot権限の運用者が管理者を復旧するためのコマンドです。指定ユーザーを作成または有効化し、`super_admin` 権限と新しい一時パスワードを付与します。同名アカウントがある場合は既存のグループ・ロールを保持したままパスワードを再発行します。

旧版から更新した環境では、`sudo limsctl inituser sys-super-admin` を実行して既存の初期管理者パスワードを再発行してください。

パッケージの削除や更新では `/var/lib/lims/mysql` のMySQLデータを削除しません。

## 管理者による備品マスタ編集

`assets.admin` 権限を持つ管理者は、管理者メニューの「マスタ編集」から備品名、個体のシリアル番号、備品ジャンルを編集できます。ジャンルを変更すると、管理番号の先頭コードだけが新ジャンルのコードへ置き換わり、登録日・採番部分は維持されます。

管理番号が変わった備品では、現物に貼り付けた旧ラベルを使用できません。更新後にラベルを再発行してください。貸出・廃棄の履歴には、処理当時の管理番号が保持されます。

## ローカルでのパッケージ生成

Docker Engineを起動したLinux、WSL、またはDocker Desktopから実行します。

```bash
bash scripts/build-deb.sh
```

ビルド専用コンテナ内でGoバイナリと`.deb`を生成します。成果物は `dist/` に出力されます。詳細な検証手順は [docs/operations.md](docs/operations.md) を参照してください。

`vX.Y.Z-alpha.N` タグをcheckoutした状態で実行すると、タグから `X.Y.Z~alpha.N` を自動設定してパッケージ名へ反映します。タグ外でのビルドは changelog の既定版番号を使用します。任意のalpha版番号を明示する場合は、`DEB_VERSION=1.2.3~alpha.4 bash scripts/build-deb.sh` のように指定できます。

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
