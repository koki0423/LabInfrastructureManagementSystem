-- 資産状態マスタの status_id = 1 の表示名を「正常」から「利用可」へ変更する。
-- 実行前に、status_id = 1 以外で「利用可」が登録されていないことを確認すること。

START TRANSACTION;

UPDATE asset_statuses
SET status_name = '利用可'
WHERE status_id = 1
  AND status_name = '正常';

COMMIT;
