# 変更履歴

## 2026-10-13

- 初回セットアップ時に、MySQLの一時初期化サーバーを準備完了と誤認しないよう、`limsctl init` とComposeのヘルスチェックを認証付きTCP接続によるSQLクエリに変更した。
- Docker Desktopでのビルド時にも、Debianパッケージへ実行ファイル・設定・初期SQLが正しく同梱されるようにした。

## 2026-10-11

- `limsctl init` でランダムな一時パスワードを発行する初期管理者を作成し、`limsctl inituser <ユーザー名>` で管理者を復旧できるようにした。
- 現行の初期SQLを `lims_v3-init.sql` から `lims-init.sql` に改名し、Docker Compose、Debianパッケージ、運用資料の参照を統一した。
