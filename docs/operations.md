# LIMS 運用・パッケージ検証

## 実行構成

`limsctl` は `/etc/lims/lims.env` を読み込み、`/usr/share/lims/docker-compose.yml` を通じて次のコンテナを管理します。

- `db`: MySQL 8.0。データはホストの `/var/lib/lims/mysql` に保持する。
- `backend`: パッケージ内の静的Goバイナリを実行するコンテナ。
- `frontend`: nginxで静的フロントエンドを配信し、`/api/` と `/swagger/` をbackendへ中継するコンテナ。

初期SQLは `lims-init.sql` を使用します。DB名は既存設定との互換性のため `lims_v2` を維持しています。SQLはMySQLのデータディレクトリが空の場合にのみ公式イメージにより実行されます。初期SQLはDBユーザーや固定の初期管理者を投入せず、初期管理者は `limsctl init` が安全な乱数パスワードとbcryptハッシュを使って作成します。

初回の `limsctl init` は、MySQL root用とバックエンド専用DBユーザー用の認証情報を設定します。対話実行では「自動生成（推奨）」または「手入力」を選択できます。設定方法を明示する場合は、`sudo limsctl init --db-credentials auto` または `sudo limsctl init --db-credentials manual` を指定します。手入力には対話可能な端末が必要です。手入力するDBパスワードは16〜128文字の英数字、ピリオド、アンダースコア、ハイフンを使用できます。アプリ用DBユーザー名は英字で始まる32文字以下の英数字またはアンダースコアを指定します。

`limsctl init` はスキーマ作成後、アプリ用DBユーザーに `lims_v2` の読み書き権限だけを付与します。MySQL rootは初期化・保守処理にのみ使用し、backendコンテナはアプリ用DBユーザーで接続します。設定済みの `/etc/lims/lims.env` がある場合、`init` は認証情報を再生成・上書きしません。初期化途中で失敗しても、同じ設定ファイルで `init` を再実行すれば、DBユーザー作成と権限付与を再試行できます。

`limsctl init` の最後に表示される初期管理者（`sys-super-admin`）の一時パスワードは、DB・設定ファイル・ログには保存されず、再表示できません。紛失時は、root権限で `sudo limsctl inituser <ユーザー名>` を実行します。確認入力後、指定アカウントを作成または有効化し、既存のグループ・ロールを維持したまま `super_admin` を追加して、新しい一時パスワードを一度だけ表示します。

`/etc/lims/lims.env` は引継ぎ要件により平文のパスワードを含みます。所有者を`root:lims`、権限を`0640`にし、不要な閲覧権限を与えないでください。DB認証情報は画面やログに出力しません。

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

`vX.Y.Z-alpha.N` タグをcheckoutした状態では、`build-deb.sh` がタグから `X.Y.Z~alpha.N` を自動設定し、`lims-system_X.Y.Z~alpha.N_amd64.deb` を出力します。`DEB_VERSION` を指定した場合はその値を優先します。タグ外で `DEB_VERSION` を指定しない場合は、`packaging/debian/changelog` の既定版番号を使用します。

## Ubuntu 24.04での検証

Ubuntu 24.04のクリーンな仮想マシンで、生成物をコピーして実施します。

```bash
sudo apt install ./lims-system_1.0.0_amd64.deb
sudo limsctl init --db-credentials auto
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

`postinst` はユーザー作成、ディレクトリ作成、案内表示だけを行い、コンテナ起動・DB初期化・migrationは実行しません。更新後は `sudo limsctl restart` を実行します。既存の `/etc/lims/lims.env` は更新で上書きせず、従来の `root` 接続設定も維持します。既存DBの初期管理者は更新で自動変更されないため、旧版から更新した環境では `sudo limsctl inituser sys-super-admin` を実行して初期管理者パスワードを再発行してください。別ユーザーの作成または復旧が必要な場合は、`sudo limsctl inituser <ユーザー名>` を実行します。v1.0.0には初回SQL以外のmigrationはないため、将来のスキーマ変更時は、データを破壊しない専用migrationを`limsctl`に追加します。
