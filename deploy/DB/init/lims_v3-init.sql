-- LIMS v2 schema initialization
-- Derived from lims_v1-init.sql and extended with group/role authorization.

SET NAMES utf8mb4;
SET @OLD_TIME_ZONE = @@TIME_ZONE;
SET TIME_ZONE = '+00:00';
SET @OLD_UNIQUE_CHECKS = @@UNIQUE_CHECKS;
SET UNIQUE_CHECKS = 0;
SET @OLD_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS = 0;
SET @OLD_SQL_MODE = @@SQL_MODE;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';

CREATE DATABASE IF NOT EXISTS `lims_v2`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE `lims_v2`;

DROP TABLE IF EXISTS `auth_account_groups`;
DROP TABLE IF EXISTS `auth_account_roles`;
DROP TABLE IF EXISTS `auth_groups`;
DROP TABLE IF EXISTS `auth_roles`;
DROP TABLE IF EXISTS `computer_configurations`;
DROP TABLE IF EXISTS `computer_details`;
DROP TABLE IF EXISTS `computer_parts`;
DROP TABLE IF EXISTS `returns`;
DROP TABLE IF EXISTS `lends`;
DROP TABLE IF EXISTS `disposals`;
DROP TABLE IF EXISTS `assets`;
DROP TABLE IF EXISTS `assets_master`;
DROP TABLE IF EXISTS `part_types`;
DROP TABLE IF EXISTS `usage_status`;
DROP TABLE IF EXISTS `asset_statuses`;
DROP TABLE IF EXISTS `asset_genres`;
DROP TABLE IF EXISTS `management_categories`;
DROP TABLE IF EXISTS `auth_accounts`;

CREATE TABLE `asset_genres` (
  `genre_id` int unsigned NOT NULL AUTO_INCREMENT,
  `genre_name` varchar(32) NOT NULL,
  `genre_code` varchar(8) NOT NULL,
  `is_disabled` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`genre_id`),
  UNIQUE KEY `ux_genre_name` (`genre_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `asset_statuses` (
  `status_id` int unsigned NOT NULL AUTO_INCREMENT,
  `status_name` varchar(20) NOT NULL,
  `is_disabled` tinyint NOT NULL DEFAULT 0,
  PRIMARY KEY (`status_id`),
  UNIQUE KEY `ux_status_name` (`status_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `management_categories` (
  `management_category_id` int unsigned NOT NULL AUTO_INCREMENT,
  `category_name` varchar(20) NOT NULL,
  PRIMARY KEY (`management_category_id`),
  UNIQUE KEY `ux_mgmt_category_name` (`category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `part_types` (
  `part_type_id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `display_name` varchar(64) NOT NULL,
  `note` text,
  PRIMARY KEY (`part_type_id`),
  UNIQUE KEY `ux_part_type_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `usage_status` (
  `usage_status_id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `display_name` varchar(64) NOT NULL,
  `note` text,
  PRIMARY KEY (`usage_status_id`),
  UNIQUE KEY `ux_usage_status_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `assets_master` (
  `asset_master_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `management_number` varchar(32) NOT NULL,
  `name` varchar(256) NOT NULL,
  `management_category_id` int unsigned NOT NULL,
  `genre_id` int unsigned NOT NULL,
  `manufacturer` varchar(128) NOT NULL,
  `model` varchar(128) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`asset_master_id`),
  KEY `idx_am_category` (`management_category_id`),
  KEY `idx_am_genre` (`genre_id`),
  KEY `idx_am_created_at` (`created_at`),
  CONSTRAINT `assets_master_asset_genres_FK`
    FOREIGN KEY (`genre_id`) REFERENCES `asset_genres` (`genre_id`),
  CONSTRAINT `fk_am_category`
    FOREIGN KEY (`management_category_id`) REFERENCES `management_categories` (`management_category_id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `assets` (
  `asset_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `asset_master_id` bigint unsigned NOT NULL,
  `serial` varchar(64) DEFAULT NULL,
  `quantity` int unsigned NOT NULL DEFAULT 1,
  `purchased_at` date NOT NULL,
  `status_id` int unsigned NOT NULL,
  `owner` varchar(128) NOT NULL,
  `default_location` varchar(128) NOT NULL,
  `location` varchar(128) DEFAULT NULL,
  `last_checked_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `last_checked_by` varchar(64) DEFAULT NULL,
  `notes` text,
  PRIMARY KEY (`asset_id`),
  KEY `idx_assets_master_id` (`asset_master_id`),
  KEY `idx_assets_status_id` (`status_id`),
  KEY `idx_assets_location` (`location`),
  KEY `idx_assets_owner` (`owner`),
  KEY `idx_assets_purchased_at` (`purchased_at`),
  KEY `idx_assets_last_checked_at` (`last_checked_at`),
  CONSTRAINT `fk_assets_master`
    FOREIGN KEY (`asset_master_id`) REFERENCES `assets_master` (`asset_master_id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_assets_status`
    FOREIGN KEY (`status_id`) REFERENCES `asset_statuses` (`status_id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_assets_quantity_nonneg` CHECK (`quantity` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `auth_accounts` (
  `id` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` varchar(64) NOT NULL DEFAULT 'user',
  `is_disabled` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `auth_groups` (
  `group_id` int unsigned NOT NULL AUTO_INCREMENT,
  `group_code` varchar(64) NOT NULL,
  `group_name` varchar(128) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `is_disabled` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`group_id`),
  UNIQUE KEY `ux_auth_groups_code` (`group_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `auth_roles` (
  `role_id` int unsigned NOT NULL AUTO_INCREMENT,
  `role_code` varchar(64) NOT NULL,
  `role_name` varchar(128) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `is_disabled` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `ux_auth_roles_code` (`role_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `auth_account_groups` (
  `account_id` varchar(255) NOT NULL,
  `group_id` int unsigned NOT NULL,
  `assigned_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`account_id`, `group_id`),
  KEY `idx_aag_group_id` (`group_id`),
  KEY `idx_aag_assigned_at` (`assigned_at`),
  CONSTRAINT `fk_aag_account`
    FOREIGN KEY (`account_id`) REFERENCES `auth_accounts` (`id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_aag_group`
    FOREIGN KEY (`group_id`) REFERENCES `auth_groups` (`group_id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `auth_account_roles` (
  `account_id` varchar(255) NOT NULL,
  `role_id` int unsigned NOT NULL,
  `assigned_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`account_id`, `role_id`),
  KEY `idx_aar_role_id` (`role_id`),
  KEY `idx_aar_assigned_at` (`assigned_at`),
  CONSTRAINT `fk_aar_account`
    FOREIGN KEY (`account_id`) REFERENCES `auth_accounts` (`id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_aar_role`
    FOREIGN KEY (`role_id`) REFERENCES `auth_roles` (`role_id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `lends` (
  `lend_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `lend_ulid` char(26) NOT NULL,
  `asset_master_id` bigint unsigned NOT NULL,
  `management_number` varchar(32) DEFAULT NULL,
  `quantity` int unsigned NOT NULL,
  `borrower_id` varchar(64) NOT NULL,
  `due_on` date DEFAULT NULL,
  `lent_by_id` varchar(64) DEFAULT NULL,
  `lent_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `note` text,
  `returned` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`lend_id`),
  UNIQUE KEY `ux_lend_ulid` (`lend_ulid`),
  KEY `idx_lend_mngnum` (`management_number`),
  KEY `idx_lend_master` (`asset_master_id`),
  KEY `idx_lend_borrower` (`borrower_id`),
  KEY `idx_lend_due` (`due_on`),
  KEY `idx_lend_at` (`lent_at`),
  CONSTRAINT `fk_lends_asset_master`
    FOREIGN KEY (`asset_master_id`) REFERENCES `assets_master` (`asset_master_id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_lends_quantity_pos` CHECK (`quantity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `returns` (
  `return_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `return_ulid` char(26) NOT NULL,
  `lend_id` bigint unsigned NOT NULL,
  `quantity` int unsigned NOT NULL,
  `processed_by_id` varchar(64) DEFAULT NULL,
  `returned_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `note` text,
  PRIMARY KEY (`return_id`),
  UNIQUE KEY `ux_return_ulid` (`return_ulid`),
  KEY `idx_return_lend` (`lend_id`),
  CONSTRAINT `fk_returns_lend`
    FOREIGN KEY (`lend_id`) REFERENCES `lends` (`lend_id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_returns_quantity_pos` CHECK (`quantity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `disposals` (
  `disposal_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `disposal_ulid` char(26) NOT NULL,
  `management_number` varchar(32) NOT NULL,
  `quantity` int unsigned NOT NULL DEFAULT 1,
  `disposed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reason` text,
  `processed_by_id` varchar(20) NOT NULL,
  PRIMARY KEY (`disposal_id`),
  UNIQUE KEY `ux_disposal_ulid` (`disposal_ulid`),
  KEY `idx_management_number` (`management_number`),
  KEY `idx_disposed_at` (`disposed_at`),
  KEY `idx_processed_by` (`processed_by_id`),
  KEY `idx_mngnum_disposedat` (`management_number`, `disposed_at`),
  CONSTRAINT `chk_disposals_quantity_pos` CHECK (`quantity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `computer_details` (
  `computer_detail_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `asset_master_id` bigint unsigned NOT NULL,
  `hostname` varchar(255) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `mac_address` varchar(17) DEFAULT NULL,
  `os` varchar(128) DEFAULT NULL,
  `purpose` varchar(255) DEFAULT NULL,
  `login_user` varchar(128) DEFAULT NULL,
  `note` text,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`computer_detail_id`),
  UNIQUE KEY `ux_cd_asset_master_id` (`asset_master_id`),
  CONSTRAINT `fk_cd_asset_master`
    FOREIGN KEY (`asset_master_id`) REFERENCES `assets_master` (`asset_master_id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `computer_parts` (
  `computer_part_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `asset_master_id` bigint unsigned NOT NULL,
  `usage_status_id` int unsigned NOT NULL,
  `spec` text,
  `note` text,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`computer_part_id`),
  UNIQUE KEY `ux_cp_asset_master_id` (`asset_master_id`),
  KEY `idx_cp_usage_status_id` (`usage_status_id`),
  CONSTRAINT `fk_cp_asset_master`
    FOREIGN KEY (`asset_master_id`) REFERENCES `assets_master` (`asset_master_id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_cp_usage_status`
    FOREIGN KEY (`usage_status_id`) REFERENCES `usage_status` (`usage_status_id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `computer_configurations` (
  `computer_configuration_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `computer_asset_master_id` bigint unsigned NOT NULL,
  `part_asset_master_id` bigint unsigned NOT NULL,
  `part_type_id` int unsigned NOT NULL,
  `installed_at` date DEFAULT NULL,
  `removed_at` date DEFAULT NULL,
  `note` text,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`computer_configuration_id`),
  KEY `idx_cc_computer_asset_master_id` (`computer_asset_master_id`),
  KEY `idx_cc_part_asset_master_id` (`part_asset_master_id`),
  KEY `idx_cc_part_type_id` (`part_type_id`),
  KEY `idx_cc_active_part` (`part_asset_master_id`, `removed_at`),
  KEY `idx_cc_computer_part_type` (`computer_asset_master_id`, `part_type_id`, `removed_at`),
  CONSTRAINT `fk_cc_computer_asset_master`
    FOREIGN KEY (`computer_asset_master_id`) REFERENCES `assets_master` (`asset_master_id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_cc_part_asset_master`
    FOREIGN KEY (`part_asset_master_id`) REFERENCES `assets_master` (`asset_master_id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_cc_part_type`
    FOREIGN KEY (`part_type_id`) REFERENCES `part_types` (`part_type_id`)
    ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `asset_genres` (`genre_id`, `genre_name`, `genre_code`, `is_disabled`) VALUES
  (1, '個人', 'IND', 0),
  (2, '事務', 'OFS', 0),
  (3, 'ファシリティ', 'FAC', 0),
  (4, '組込みシステム', 'EMB', 0),
  (5, '高度情報演習', 'ADV', 0),
  (6, 'テスト', 'TST', 1),
  (7, 'テスト2', 'TST2', 1);

INSERT INTO `asset_statuses` (`status_id`, `status_name`, `is_disabled`) VALUES
  (1, '正常', 0),
  (2, '故障', 0),
  (3, '修理中', 0),
  (4, '貸出中', 0),
  (5, '廃棄済み', 0),
  (6, '紛失', 0);

INSERT INTO `management_categories` (`management_category_id`, `category_name`) VALUES
  (1, '個別管理'),
  (2, '全体管理');

INSERT INTO `part_types` (`part_type_id`, `name`, `display_name`, `note`) VALUES
  (1, 'motherboard', 'マザーボード', 'PC/サーバ本体の主基板'),
  (2, 'cpu', 'CPU', 'プロセッサ'),
  (3, 'memory', 'メモリ', 'DIMMやSO-DIMMなどのメモリモジュール'),
  (4, 'gpu', 'GPU', 'グラフィックカードやGPUモジュール'),
  (5, 'storage', 'ストレージ', 'HDD/SSD/NVMeなどの記憶装置'),
  (6, 'network_adapter', 'NIC', '有線/無線のネットワークアダプタ'),
  (7, 'other', 'その他', '上記に当てはまらない部品');

INSERT INTO `usage_status` (`usage_status_id`, `name`, `display_name`, `note`) VALUES
  (1, 'in_use', '使用中', NULL),
  (2, 'unused', '未使用', NULL),
  (3, 'spare', '予備', NULL);

INSERT INTO `auth_roles` (`role_id`, `role_code`, `role_name`, `description`, `is_disabled`, `created_at`) VALUES
  (1, 'user', 'User', 'Standard authenticated user', 0, '2026-06-29 00:00:00.000000'),
  (2, 'asset_admin', 'Asset Administrator', 'Asset management administrative privilege', 0, '2026-06-29 00:00:00.000000'),
  (3, 'computer_admin', 'Computer Administrator', 'Computer management administrative privilege', 0, '2026-06-29 00:00:00.000000'),
  (4, 'super_admin', 'Super Administrator', 'Administrative privilege for both asset and computer domains', 0, '2026-06-29 00:00:00.000000');

INSERT INTO `auth_accounts` (`id`, `password_hash`, `role`, `is_disabled`, `created_at`) VALUES
  ('sys-super-admin', '$2a$10$YxH1twPWT/SWpR/t99M18eqQ5SBuMeigDhubAeUKcStsWxnYPkynW', 'super_admin', 0, '2026-06-29 00:00:00.000000');

INSERT INTO `auth_account_roles` (`account_id`, `role_id`, `assigned_at`)
SELECT 'sys-super-admin', `role_id`, '2026-06-29 00:00:00.000000'
FROM `auth_roles`
WHERE `role_code` = 'super_admin';

SET TIME_ZONE = @OLD_TIME_ZONE;
SET SQL_MODE = @OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS = @OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS = @OLD_UNIQUE_CHECKS;
