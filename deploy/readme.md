# lims-deploy-env について

このリポジトリは、LIMS のデプロイ用環境一式をまとめたものです。  
主な用途は、Ubuntu 環境上で以下をまとめてセットアップ・起動することです。

- MySQL コンテナの起動
- フロントエンドの配置
- バックエンドの取得・Swagger 生成・ビルド
- バックエンドの systemd 常駐化
- データベースバックアップスクリプトの配置
- cron へのバックアップ定期実行設定

---

# 構成概要

本環境では、以下の構成を想定しています。

- DB: Docker 上の MySQL 8.0
- Frontend: Docker 上の nginx
- Backend: ホスト OS 上で Go アプリとしてビルドし、systemd で常駐化
- Backup: ホスト OS 上の shell script + cron

---

# 実行方法

## Ubuntu の場合

### 前提
- Ubuntu 上で実行すること
- `sudo` が使用できること
- インターネット接続があること

### 実行手順

1. リポジトリを配置します。
2. `deploy.sh` に実行権限を付与します。
3. `deploy.sh` を実行します。

``` bash
chmod +x ./deploy.sh
./deploy.sh
```
### 初回実行時の注意
`deploy.sh` は Docker をインストールした後、現在のユーザーを `docker` グループへ追加します。
そのため、初回実行直後は `docker` グループの反映がまだ済んでおらず、`docker compose` が sudo なしで実行できない場合があります。
その場合は、以下のいずれかを行った後、再度 `deploy.sh` を実行してください。

``` bash
newgrp docker
./deploy.sh
```

または、一度ログアウトして再ログインしてから再実行してください。

### deploy.sh で実施される内容

`deploy.sh` は主に以下を行います。
- Docker のインストール
- docker グループ設定
- Go のインストール（snap）
- frontend / backend リポジトリの clone
- Swagger ドキュメント生成
- バックエンドのビルド
- `docker compose up -d`
- systemd service の作成または更新
- バックアップスクリプトの配置
- cron へのバックアップ登録

### 実行後の確認
#### フロントエンド確認
```
http://localhost
```
#### systemd 状態確認
```
systemctl status lims-backend
```
#### バックエンドログ確認
```
journalctl -u lims-backend -n 100 --no-pager
```
#### Docker コンテナ確認
```
docker compose ps
```
#### cron 確認
```
crontab -l
```
## Windows の場合

Windows では、管理者として起動した PowerShell から `deploy.ps1` を実行します。Docker Desktop、Git、Go がインストール済みで、Docker Desktop が起動していることを確認してください。

```powershell
.\deploy.ps1
```

`deploy.ps1` は `deploy.sh` と同様に、リポジトリの取得、Swagger 生成、バックエンドのビルド、`docker compose up -d`、バックエンドの自動起動設定、バックアップの定期実行設定を行います。

Windows では systemd と cron の代わりに Windows タスク スケジューラを使用します。バックエンドはログオン時に自動起動し、MySQL バックアップは毎日 0:00 に実行されます。バックアップとログは `%LOCALAPPDATA%\LIMS\` 以下に保存されます。

# データベースのバックアップについて
## 概要

DB コンテナに対して mysqldump を実行し、バックアップファイルをホスト OS 側へ保存します。
バックアップファイルは gzip 圧縮され、古いバックアップは自動削除されます。

## 対象 DB
コンテナ名: `lims-db`
DB 名: `lims_v1`
## バックアップスクリプトの取り扱い
### 配置先
```
/opt/scripts/mysql_backup.sh
```
### 実行権限付与
```
chmod +x /opt/scripts/mysql_backup.sh
```
### 手動実行
```
/opt/scripts/mysql_backup.sh
```
### バックアップ保存先
```
/opt/db-backups
```
### 定期実行設定

`deploy.sh` 実行時に、以下の cron が自動登録されます。
```
0 0 * * * /opt/scripts/mysql_backup.sh >> /var/log/mysql_backup.log 2>&1
```
これは毎日 24:00 にバックアップを実行し、標準出力と標準エラー出力をログへ追記する設定です。

Windows では、`deploy.ps1` 実行時に `LIMS MySQL Backup` タスクが自動登録されます。毎日 0:00 に実行され、バックアップは `%LOCALAPPDATA%\LIMS\db-backups\`、ログは `%LOCALAPPDATA%\LIMS\logs\mysql_backup.log` に保存されます。手動実行する場合は、以下を実行してください。

```powershell
& "$env:LOCALAPPDATA\LIMS\scripts\mysql_backup.ps1"
```

### 保持期間

バックアップファイルは 7 日より古いものを自動削除します。

### 復元方法
```
gunzip -c /opt/db-backups/＜バックアップファイル名＞.sql.gz | \
docker exec -i lims-db mysql -uroot -p＜パスワード＞ lims_v1
```

# その他メモ
## コンテナ起動・初期化
```
docker compose up -d --build
```

## コンテナの停止
```
docker compose down
```

## コンテナ・ボリュームを含めてリセットする場合
```
docker compose down -v
```

## バックエンドの手動ビルド・起動
```
go build -o server .
./server
```

## systemd の再起動
```
sudo systemctl restart lims-backend
```
## systemd の自動起動設定確認
```
systemctl is-enabled lims-backend
```
## 配布ディレクトリ例
```
project-root/
  deploy.sh
  docker-compose.yml
  scripts/
    mysql_backup.sh
  frontend/
  backend/
  nginx/
  DB/
```
# 備考
`deploy.sh` は同名の `systemd service lims-backend `を更新して再起動します。
再実行しても、同名 service が複数作成されることはありません。
バックアップ用 cron も、同じ行がすでに存在する場合は重複登録しません。
