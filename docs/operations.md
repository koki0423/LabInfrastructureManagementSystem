# LIMS 運用・パッケージ検証

## 実行構成

`limsctl` は `/etc/lims/lims.env` を読み込み、`/usr/share/lims/docker-compose.yml` を通じて次のコンテナを管理します。

- `db`: MySQL 8.0。データはホストの `/var/lib/lims/mysql` に保持する。
- `backend`: パッケージ内の静的Goバイナリを実行するコンテナ。
- `frontend`: nginxで静的フロントエンドを配信し、`/api/` と `/swagger/` をbackendへ中継するコンテナ。

初期SQLは `lims-init.sql` を使用します。DB名は既存設定との互換性のため `lims_v2` を維持しています。SQLはMySQLのデータディレクトリが空の場合にのみ公式イメージにより実行されます。初期SQLは固定の初期管理者を投入せず、初期管理者は `limsctl init` が安全な乱数パスワードとbcryptハッシュを使って作成します。

`limsctl init` の最後に表示される初期管理者（`sys-super-admin`）の一時パスワードは、DB・設定ファイル・ログには保存されず、再表示できません。紛失時は、root権限で `sudo limsctl inituser <ユーザー名>` を実行します。確認入力後、指定アカウントを作成または有効化し、既存のグループ・ロールを維持したまま `super_admin` を追加して、新しい一時パスワードを一度だけ表示します。

`/etc/lims/lims.env` は引継ぎ要件により平文のパスワードを含みます。所有者を`root:lims`、権限を`0640`にし、不要な閲覧権限を与えないでください。

## ローカルビルド

Docker Engineが利用できる環境で、リポジトリ直下から実行します。

```bash
bash scripts/build-deb.sh
```

このスクリプトはGo 1.25とDebianパッケージツールを含むLinuxコンテナを作成し、コンテナ内で以下を行います。

1. Swaggerドキュメントを生成する。
2. Linux/amd64用の静的backendバイナリをビルドする。
3. backendのテストを実行する。
4. `lims-system_1.0.0_amd64.deb` を `dist/` に出力する。

## Ubuntu 24.04での検証

Ubuntu 24.04のクリーンな仮想マシンで、生成物をコピーして実施します。

```bash
sudo apt install ./lims-system_1.0.0_amd64.deb
sudo limsctl init
sudo limsctl status
```

ブラウザから `http://<server-address>/` にアクセスします。

更新とデータ保持は、同じホストで次のように確認します。

```bash
sudo apt install ./lims-system_1.0.0_amd64.deb
sudo limsctl restart
sudo apt remove lims-system
sudo test -d /var/lib/lims/mysql
```

`remove` と `purge` はMySQLデータディレクトリを削除しません。データを完全に消去する必要がある場合は、バックアップを確認した上で管理者が明示的に `/var/lib/lims/mysql` を削除します。

## 更新時の扱い

`postinst` はユーザー作成、ディレクトリ作成、案内表示だけを行い、コンテナ起動・DB初期化・migrationは実行しません。更新後は `sudo limsctl restart` を実行します。既存DBの初期管理者は更新で自動変更されないため、旧版から更新した環境では `sudo limsctl inituser sys-super-admin` を実行して初期管理者パスワードを再発行してください。別ユーザーの作成または復旧が必要な場合は、`sudo limsctl inituser <ユーザー名>` を実行します。v1.0.0には初回SQL以外のmigrationはないため、将来のスキーマ変更時は、データを破壊しない専用migrationを`limsctl`に追加します。
