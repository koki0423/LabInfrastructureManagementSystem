-- MySQL dump 10.13  Distrib 8.0.36, for Win64 (x86_64)
--
-- Host: 192.168.0.61    Database: lims_v1
-- ------------------------------------------------------
-- Server version	8.4.7

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `asset_genres`
--

CREATE DATABASE IF NOT EXISTS `lims_v1` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `lims_v1`;

DROP TABLE IF EXISTS `asset_genres`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `asset_genres` (
  `genre_id` int unsigned NOT NULL AUTO_INCREMENT,
  `genre_name` varchar(32) NOT NULL,
  `genre_code` varchar(8) NOT NULL,
  `is_disabled` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`genre_id`),
  UNIQUE KEY `ux_genre_name` (`genre_name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `asset_genres`
--

LOCK TABLES `asset_genres` WRITE;
/*!40000 ALTER TABLE `asset_genres` DISABLE KEYS */;
INSERT INTO `asset_genres` VALUES (1,'個人','IND',0),(2,'事務','OFS',0),(3,'ファシリティ','FAC',0),(4,'組込みシステム','EMB',0),(5,'高度情報演習','ADV',0),(6,'テスト','TST',1),(7,'テスト2','TST2',1);
/*!40000 ALTER TABLE `asset_genres` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `asset_statuses`
--

DROP TABLE IF EXISTS `asset_statuses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `asset_statuses` (
  `status_id` int unsigned NOT NULL AUTO_INCREMENT,
  `status_name` varchar(20) NOT NULL,
  `is_disabled` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`status_id`),
  UNIQUE KEY `ux_status_name` (`status_name`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `asset_statuses`
--

LOCK TABLES `asset_statuses` WRITE;
/*!40000 ALTER TABLE `asset_statuses` DISABLE KEYS */;
INSERT INTO `asset_statuses` VALUES (1,'正常',0),(2,'故障',0),(3,'修理中',0),(4,'貸出中',0),(5,'廃棄済み',0),(6,'紛失',0);
/*!40000 ALTER TABLE `asset_statuses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assets`
--

DROP TABLE IF EXISTS `assets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assets` (
  `asset_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `asset_master_id` bigint unsigned NOT NULL,
  `serial` varchar(64) DEFAULT NULL,
  `quantity` int unsigned NOT NULL DEFAULT '1',
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
  CONSTRAINT `fk_assets_master` FOREIGN KEY (`asset_master_id`) REFERENCES `assets_master` (`asset_master_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_assets_status` FOREIGN KEY (`status_id`) REFERENCES `asset_statuses` (`status_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_assets_quantity_nonneg` CHECK ((`quantity` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=145 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assets`
--

LOCK TABLES `assets` WRITE;
/*!40000 ALTER TABLE `assets` DISABLE KEYS */;
INSERT INTO `assets` VALUES (1,1,NULL,1,'2025-02-02',1,'Noa Ushio','実験室','','2025-02-02 18:00:00','noa','バッテリー劣化'),(2,4,'0372229',1,'2025-09-03',1,'NOC2','NOC2','AL21034','2026-01-12 03:46:03',NULL,NULL),(3,5,'ｇｒｓｒｇ',1,'2025-09-10',1,'NOC4','NOC4','','2025-09-13 06:31:20','',''),(5,7,'不明',1,'2025-09-03',3,'NOC4','NOC4','','2025-11-14 17:46:32',NULL,NULL),(6,8,'あうぇふぁえｆ',8,'2025-09-11',4,'NOC4','NOC4','学生','2025-11-14 21:24:22',NULL,NULL),(7,9,'037222965465',1,'2025-09-03',6,'','NOC4','','2025-09-11 04:20:19','',''),(8,10,'なし',1,'2025-09-04',6,'NOC4','NOC4','','2025-09-12 20:00:26','',''),(9,11,'324410976065',1,'2025-09-01',2,'NOC2','NOC2','','2025-11-14 06:42:12',NULL,NULL),(10,12,'96435102',1,'2025-09-16',1,'NOC1','NOC1','','2025-11-14 17:23:38','',''),(11,13,'不明',0,'2025-11-13',4,'NOC4','NOC4','学生','2025-11-14 21:52:12',NULL,NULL),(12,14,'JPN846409H',0,'2025-12-18',5,'AL21034','実験室','','2025-12-24 05:32:24','',NULL),(104,106,'SN-TD172-0001',1,'2025-11-30',1,'情報工学研究室','倉庫A-棚3','倉庫A-棚3','2026-01-02 04:17:03','AB12345','バッテリ2個、ケース付き'),(105,107,'SN-A8355-0001',1,'2025-11-19',1,'情報工学研究室','研究室-机上','','2026-01-02 04:17:03','','付属品: USB-Cケーブル'),(106,108,'SN-RPI5-0001',2,'2025-10-09',1,'情報工学研究室','倉庫B-棚1','倉庫B-棚1','2026-01-02 04:17:03','AB99999','予備含む'),(107,109,'SN-C2960L-0001',1,'2025-09-14',1,'情報工学研究室','サーバ室-ラック2','サーバ室-ラック2','2026-01-02 04:17:03','AB12345','管理VLAN設定済み'),(108,110,'SN-APN505-0001',1,'2025-07-31',1,'情報工学研究室','倉庫A-棚2','倉庫A-棚2','2026-01-02 04:17:03','','初期化済み'),(109,111,'SN-A4000-0001',1,'2025-06-30',1,'情報工学研究室','サーバ室-ラック1','サーバ室-ラック1','2026-01-02 04:17:03','AB77777','GPUパススルー検証用'),(110,112,'SN-HW1900-0001',1,'2025-10-31',1,'情報工学研究室','研究室-受付','研究室-受付','2026-01-02 04:17:04','AB12345','貸出受付用'),(111,113,'SN-QL800-0001',1,'2025-06-19',1,'情報工学研究室','研究室-棚1','研究室-棚1','2026-01-02 04:17:04','','テスト印刷OK'),(112,114,'SN-T7-0001',3,'2025-05-09',1,'情報工学研究室','倉庫B-棚2','倉庫B-棚2','2026-01-02 04:17:04','AB12345','バックアップ用途'),(113,115,'SN-TOOL-0001',1,'2025-02-28',1,'情報工学研究室','倉庫A-棚5','倉庫A-棚5','2026-01-02 04:17:04','','内容物は別紙参照'),(114,116,'SN-TD172-0001',1,'2025-11-30',1,'情報工学研究室','倉庫A-棚3','倉庫A-棚3','2026-01-02 04:22:56','AB12345','バッテリ2個、ケース付き'),(115,117,'SN-A8355-0001',1,'2025-11-19',1,'情報工学研究室','研究室-机上','','2026-01-02 04:22:56','','付属品: USB-Cケーブル'),(116,118,'SN-RPI5-0001',2,'2025-10-09',1,'情報工学研究室','倉庫B-棚1','倉庫B-棚1','2026-01-02 04:22:57','AB99999','予備含む'),(117,119,'SN-C2960L-0001',1,'2025-09-14',1,'情報工学研究室','サーバ室-ラック2','サーバ室-ラック2','2026-01-02 04:22:57','AB12345','管理VLAN設定済み'),(118,120,'SN-APN505-0001',1,'2025-07-31',2,'情報工学研究室','倉庫A-棚2','倉庫A-棚2','2026-01-02 04:22:57','','初期化済み'),(119,121,'SN-A4000-0001',1,'2025-06-30',1,'情報工学研究室','サーバ室-ラック1','サーバ室-ラック1','2026-01-02 04:22:57','AB77777','GPUパススルー検証用'),(120,122,'SN-HW1900-0001',1,'2025-10-31',1,'情報工学研究室','研究室-受付','研究室-受付','2026-01-02 04:22:57','AB12345','貸出受付用'),(121,123,'SN-QL800-0001',1,'2025-06-19',1,'情報工学研究室','研究室-棚1','研究室-棚1','2026-01-02 04:22:57','','テスト印刷OK'),(122,124,'SN-T7-0001',3,'2025-05-09',1,'情報工学研究室','倉庫B-棚2','倉庫B-棚2','2026-01-02 04:22:57','AB12345','バックアップ用途'),(123,125,'SN-TOOL-0001',1,'2025-02-28',1,'情報工学研究室','倉庫A-棚5','倉庫A-棚5','2026-01-02 04:22:57','','内容物は別紙参照'),(124,126,'SN-TD172-0001',1,'2025-11-30',1,'情報工学研究室','倉庫A-棚3','倉庫A-棚3','2026-01-02 04:24:01','AB12345','バッテリ2個、ケース付き'),(125,127,'SN-A8355-0001',1,'2025-11-19',1,'情報工学研究室','研究室-机上','','2026-01-02 04:24:01','','付属品: USB-Cケーブル'),(126,128,'SN-RPI5-0001',2,'2025-10-09',1,'情報工学研究室','倉庫B-棚1','倉庫B-棚1','2026-01-02 04:24:01','AB99999','予備含む'),(127,129,'SN-C2960L-0001',1,'2025-09-14',1,'情報工学研究室','サーバ室-ラック2','サーバ室-ラック2','2026-01-02 04:24:02','AB12345','管理VLAN設定済み'),(128,130,'SN-APN505-0001',1,'2025-07-31',1,'情報工学研究室','倉庫A-棚2','倉庫A-棚2','2026-01-02 04:24:02','','初期化済み'),(129,131,'SN-A4000-0001',1,'2025-06-30',1,'情報工学研究室','サーバ室-ラック1','サーバ室-ラック1','2026-01-02 04:24:02','AB77777','GPUパススルー検証用'),(130,132,'SN-HW1900-0001',1,'2025-10-31',1,'情報工学研究室','研究室-受付','研究室-受付','2026-01-02 04:24:02','AB12345','貸出受付用'),(131,133,'SN-QL800-0001',1,'2025-06-19',1,'情報工学研究室','研究室-棚1','研究室-棚1','2026-01-02 04:24:02','','テスト印刷OK'),(132,134,'SN-T7-0001',3,'2025-05-09',1,'情報工学研究室','倉庫B-棚2','倉庫B-棚2','2026-01-02 04:24:02','AB12345','バックアップ用途'),(133,135,'SN-TOOL-0001',1,'2025-02-28',1,'情報工学研究室','倉庫A-棚5','倉庫A-棚5','2026-01-02 04:24:02','','内容物は別紙参照'),(134,136,'SN-TD172-0001',1,'2025-11-30',2,'情報工学研究室','倉庫A-棚3','倉庫A-棚3','2026-01-02 04:26:27','AB12345','バッテリ2個、ケース付き'),(135,137,'SN-A8355-0001',1,'2025-11-19',1,'情報工学研究室','研究室-机上','','2026-01-02 04:26:27','','付属品: USB-Cケーブル'),(136,138,'SN-RPI5-0001',2,'2025-10-09',1,'情報工学研究室','倉庫B-棚1','倉庫B-棚1','2026-01-02 04:26:27','AB99999','予備含む'),(137,139,'SN-C2960L-0001',1,'2025-09-14',1,'情報工学研究室','サーバ室-ラック2','サーバ室-ラック2','2026-01-02 04:26:27','AB12345','管理VLAN設定済み'),(138,140,'SN-APN505-0001',1,'2025-07-31',1,'情報工学研究室','倉庫A-棚2','倉庫A-棚2','2026-01-02 04:26:27','','初期化済み'),(139,141,'SN-A4000-0001',1,'2025-06-30',1,'情報工学研究室','サーバ室-ラック1','サーバ室-ラック1','2026-01-02 04:26:27','AB77777','GPUパススルー検証用'),(140,142,'SN-HW1900-0001',1,'2025-10-31',1,'情報工学研究室','研究室-受付','研究室-受付','2026-01-02 04:26:27','AB12345','貸出受付用'),(141,143,'SN-QL800-0001',1,'2025-06-19',1,'情報工学研究室','研究室-棚1','研究室-棚1','2026-01-02 04:26:28','','テスト印刷OK'),(142,144,'SN-T7-0001',3,'2025-05-09',1,'情報工学研究室','倉庫B-棚2','倉庫B-棚2','2026-01-02 04:26:28','AB12345','バックアップ用途'),(143,145,'SN-TOOL-0001',1,'2025-02-28',1,'情報工学研究室','倉庫A-棚5','倉庫A-棚5','2026-01-02 04:26:28','','内容物は別紙参照'),(144,146,'aojfopjef',1,'2026-01-17',1,'AL21034','実験室','','2026-01-05 06:37:53','',NULL);
/*!40000 ALTER TABLE `assets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assets_master`
--

DROP TABLE IF EXISTS `assets_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
  CONSTRAINT `assets_master_asset_genres_FK` FOREIGN KEY (`genre_id`) REFERENCES `asset_genres` (`genre_id`),
  CONSTRAINT `fk_am_category` FOREIGN KEY (`management_category_id`) REFERENCES `management_categories` (`management_category_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=147 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assets_master`
--

LOCK TABLES `assets_master` WRITE;
/*!40000 ALTER TABLE `assets_master` DISABLE KEYS */;
INSERT INTO `assets_master` VALUES (1,'IND-20250907-00001','ノートPC',1,1,'Lenovo','ThinkPad X13 Gen6','2025-09-07 03:45:19'),(4,'IND-20250910-00004','DL360 Gen10-NEC',1,1,'HPE','RC-S300','2025-09-10 14:10:16'),(5,'FAC-20250910-00005','DL360 Gen10-NEC',1,3,'HPE','RC-S300','2025-09-10 14:13:41'),(7,'IND-20250910-00007','DL360 Gen10-NEC',1,1,'HPE','RC-S300','2025-09-10 14:37:31'),(8,'IND-20250910-00008','DL360 Gen10-NEC',1,1,'HPE','RC-S300','2025-09-10 14:39:19'),(9,'IND-20250910-00009','iLO',1,1,'Nvidia','RC-S300','2025-09-10 14:43:22'),(10,'IND-20250910-00010','DL360 Gen10-NEC',1,1,'HPE','RC-S300','2025-09-10 14:54:22'),(11,'IND-20250911-00011','DL360 Gen10-NEC',1,1,'HPE','laknkale','2025-09-11 12:00:48'),(12,'FAC-20250930-00012','RDP',1,3,'Microsoft','RC-S300','2025-09-30 05:32:28'),(13,'IND-20251115-00013','DL360 Gen10-NEC',1,1,'HPE','DL360 Gen10','2025-11-15 02:47:53'),(14,'IND-20251224-00014','サーバー',1,1,'HPE','cable manager','2025-12-24 14:32:23'),(106,'IND-20260102-00106','マキタ インパクトドライバー',1,1,'Makita','TD172DRGX','2026-01-02 13:17:03'),(107,'IND-20260102-00107','Anker USB-C Hub',1,1,'Anker','A8355','2026-01-02 13:17:03'),(108,'IND-20260102-00108','Raspberry Pi 5',1,1,'Raspberry Pi',NULL,'2026-01-02 13:17:03'),(109,'IND-20260102-00109','Cisco Catalyst 2960L',1,1,'Cisco','C2960L-24TS','2026-01-02 13:17:03'),(110,'IND-20260102-00110','FS.com AP-N505',1,1,'FS.com','AP-N505','2026-01-02 13:17:03'),(111,'IND-20260102-00111','NVIDIA RTX A4000',1,1,'NVIDIA','RTX A4000','2026-01-02 13:17:03'),(112,'IND-20260102-00112','USBバーコードリーダー',1,1,'Honeywell','1900G','2026-01-02 13:17:04'),(113,'IND-20260102-00113','ラベルプリンタ',1,1,'Brother','QL-800','2026-01-02 13:17:04'),(114,'IND-20260102-00114','外付けSSD 1TB',1,1,'Samsung','T7 Shield','2026-01-02 13:17:04'),(115,'IND-20260102-00115','工具セット',1,1,'BOSCH',NULL,'2026-01-02 13:17:04'),(116,'IND-20260102-00116','マキタ インパクトドライバー',1,1,'Makita','TD172DRGX','2026-01-02 13:22:56'),(117,'IND-20260102-00117','Anker USB-C Hub',1,1,'Anker','A8355','2026-01-02 13:22:56'),(118,'IND-20260102-00118','Raspberry Pi 5',1,1,'Raspberry Pi',NULL,'2026-01-02 13:22:56'),(119,'IND-20260102-00119','Cisco Catalyst 2960L',1,1,'Cisco','C2960L-24TS','2026-01-02 13:22:57'),(120,'IND-20260102-00120','FS.com AP-N505',1,1,'FS.com','AP-N505','2026-01-02 13:22:57'),(121,'IND-20260102-00121','NVIDIA RTX A4000',1,1,'NVIDIA','RTX A4000','2026-01-02 13:22:57'),(122,'IND-20260102-00122','USBバーコードリーダー',1,1,'Honeywell','1900G','2026-01-02 13:22:57'),(123,'IND-20260102-00123','ラベルプリンタ',1,1,'Brother','QL-800','2026-01-02 13:22:57'),(124,'IND-20260102-00124','外付けSSD 1TB',1,1,'Samsung','T7 Shield','2026-01-02 13:22:57'),(125,'IND-20260102-00125','工具セット',1,1,'BOSCH',NULL,'2026-01-02 13:22:57'),(126,'IND-20260102-00126','マキタ インパクトドライバー',1,1,'Makita','TD172DRGX','2026-01-02 13:24:01'),(127,'IND-20260102-00127','Anker USB-C Hub',1,1,'Anker','A8355','2026-01-02 13:24:01'),(128,'IND-20260102-00128','Raspberry Pi 5',1,1,'Raspberry Pi',NULL,'2026-01-02 13:24:01'),(129,'IND-20260102-00129','Cisco Catalyst 2960L',1,1,'Cisco','C2960L-24TS','2026-01-02 13:24:02'),(130,'IND-20260102-00130','FS.com AP-N505',1,1,'FS.com','AP-N505','2026-01-02 13:24:02'),(131,'IND-20260102-00131','NVIDIA RTX A4000',1,1,'NVIDIA','RTX A4000','2026-01-02 13:24:02'),(132,'IND-20260102-00132','USBバーコードリーダー',1,1,'Honeywell','1900G','2026-01-02 13:24:02'),(133,'IND-20260102-00133','ラベルプリンタ',1,1,'Brother','QL-800','2026-01-02 13:24:02'),(134,'IND-20260102-00134','外付けSSD 1TB',1,1,'Samsung','T7 Shield','2026-01-02 13:24:02'),(135,'IND-20260102-00135','工具セット',1,1,'BOSCH',NULL,'2026-01-02 13:24:02'),(136,'IND-20260102-00136','マキタ インパクトドライバー',1,1,'Makita','TD172DRGX','2026-01-02 13:26:27'),(137,'IND-20260102-00137','Anker USB-C Hub',1,1,'Anker','A8355','2026-01-02 13:26:27'),(138,'IND-20260102-00138','Raspberry Pi 5',1,1,'Raspberry Pi',NULL,'2026-01-02 13:26:27'),(139,'IND-20260102-00139','Cisco Catalyst 2960L',1,1,'Cisco','C2960L-24TS','2026-01-02 13:26:27'),(140,'IND-20260102-00140','FS.com AP-N505',1,1,'FS.com','AP-N505','2026-01-02 13:26:27'),(141,'IND-20260102-00141','NVIDIA RTX A4000',1,1,'NVIDIA','RTX A4000','2026-01-02 13:26:27'),(142,'IND-20260102-00142','USBバーコードリーダー',1,1,'Honeywell','1900G','2026-01-02 13:26:27'),(143,'IND-20260102-00143','ラベルプリンタ',1,1,'Brother','QL-800','2026-01-02 13:26:28'),(144,'IND-20260102-00144','外付けSSD 1TB',1,1,'Samsung','T7 Shield','2026-01-02 13:26:28'),(145,'IND-20260102-00145','工具セット',1,1,'BOSCH',NULL,'2026-01-02 13:26:28'),(146,'TST-20260106-00146','テスト',1,6,'テスト','epria;oghj','2026-01-05 15:37:53');
/*!40000 ALTER TABLE `assets_master` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_accounts`
--

DROP TABLE IF EXISTS `auth_accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_accounts` (
  `id` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` varchar(64) NOT NULL DEFAULT 'user',
  `is_disabled` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_accounts`
--

LOCK TABLES `auth_accounts` WRITE;
/*!40000 ALTER TABLE `auth_accounts` DISABLE KEYS */;
INSERT INTO `auth_accounts` VALUES ('test','$2a$10$GZxTtaLhZ6aCLNRGEfsMUezoXB6kcPHfBCZpbD.1W0RJVyKIzfYKG','admin',0,'2026-01-06 18:23:19.308950');
/*!40000 ALTER TABLE `auth_accounts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `disposals`
--

DROP TABLE IF EXISTS `disposals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `disposals` (
  `disposal_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `disposal_ulid` char(26) NOT NULL,
  `management_number` varchar(32) NOT NULL,
  `quantity` int unsigned NOT NULL DEFAULT '1',
  `disposed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reason` text,
  `processed_by_id` varchar(20) NOT NULL,
  PRIMARY KEY (`disposal_id`),
  UNIQUE KEY `ux_disposal_ulid` (`disposal_ulid`),
  KEY `idx_management_number` (`management_number`),
  KEY `idx_disposed_at` (`disposed_at`),
  KEY `idx_processed_by` (`processed_by_id`),
  KEY `idx_mngnum_disposedat` (`management_number`,`disposed_at`),
  CONSTRAINT `chk_disposals_quantity_pos` CHECK ((`quantity` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `disposals`
--

LOCK TABLES `disposals` WRITE;
/*!40000 ALTER TABLE `disposals` DISABLE KEYS */;
INSERT INTO `disposals` VALUES (4,'01K4WETE0AH2PY8M9RCD572NHP','IND-20250910-00008',1,'2025-09-11 13:18:23','内部故障','ma10126'),(8,'01K537J0ESS2RZF5VHG2FS4TR5','IND-20250907-00001',1,'2025-09-14 04:25:59','テスト','AL21034'),(9,'01K537ZR8XT0N0EB5R5QS30NKS','IND-20250907-00001',1,'2025-09-14 04:33:30','test2','AL21034'),(10,'01K5382DG086ZGERN32D2FMDSW','IND-20250907-00001',1,'2025-09-14 04:34:57','test','AL21034'),(11,'01KD8E2ST9JFXFRW48XEXG2TJN','IND-20251224-00014',1,'2025-12-24 15:01:52','落下による筐体破損','AL21034'),(12,'01KD8GZZ23YB4YWN9RKHVPRDPF','IND-20250910-00008',1,'2025-12-24 15:52:44','落下による筐体破損','AL21034');
/*!40000 ALTER TABLE `disposals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lends`
--

DROP TABLE IF EXISTS `lends`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lends` (
  `lend_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `lend_ulid` char(26) NOT NULL,
  `asset_master_id` bigint unsigned NOT NULL,
  `management_number` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `quantity` int unsigned NOT NULL,
  `borrower_id` varchar(64) NOT NULL,
  `due_on` date DEFAULT NULL,
  `lent_by_id` varchar(64) DEFAULT NULL,
  `lent_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `note` text,
  `returned` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`lend_id`),
  UNIQUE KEY `ux_lend_ulid` (`lend_ulid`),
  KEY `idx_lend_mngnum` (`management_number`),
  KEY `idx_lend_master` (`asset_master_id`),
  KEY `idx_lend_borrower` (`borrower_id`),
  KEY `idx_lend_due` (`due_on`),
  KEY `idx_lend_at` (`lent_at`),
  CONSTRAINT `fk_lends_asset_master` FOREIGN KEY (`asset_master_id`) REFERENCES `assets_master` (`asset_master_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_lends_quantity_pos` CHECK ((`quantity` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=62 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lends`
--

LOCK TABLES `lends` WRITE;
/*!40000 ALTER TABLE `lends` DISABLE KEYS */;
INSERT INTO `lends` VALUES (58,'01KHDX0FZB6RWQ3J07HWC175TN',1,'IND-20250907-00001',1,'AL21034',NULL,'AL21034','2026-02-14 02:01:40',NULL,1),(59,'01KHDXC2W81JB91DQPKJWWER65',1,'IND-20250907-00001',1,'AL21034',NULL,'AL21034','2026-02-14 02:08:00',NULL,1),(60,'01KHDXVKPPF2Y5BFK8W2XW3EDV',1,'IND-20250907-00001',1,'AL21034',NULL,'AL21034','2026-02-14 02:16:29',NULL,1),(61,'01KHDXXS6G91TW12WRAYKD9QGA',1,'IND-20250907-00001',1,'IND-20250907-00001',NULL,'AL21034','2026-02-14 02:17:40',NULL,1);
/*!40000 ALTER TABLE `lends` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `management_categories`
--

DROP TABLE IF EXISTS `management_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `management_categories` (
  `management_category_id` int unsigned NOT NULL AUTO_INCREMENT,
  `category_name` varchar(20) NOT NULL,
  PRIMARY KEY (`management_category_id`),
  UNIQUE KEY `ux_mgmt_category_name` (`category_name`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `management_categories`
--

LOCK TABLES `management_categories` WRITE;
/*!40000 ALTER TABLE `management_categories` DISABLE KEYS */;
INSERT INTO `management_categories` VALUES (1,'個別管理'),(2,'全体管理');
/*!40000 ALTER TABLE `management_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `returns`
--

DROP TABLE IF EXISTS `returns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
  CONSTRAINT `fk_returns_lend` FOREIGN KEY (`lend_id`) REFERENCES `lends` (`lend_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_returns_quantity_pos` CHECK ((`quantity` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `returns`
--

LOCK TABLES `returns` WRITE;
/*!40000 ALTER TABLE `returns` DISABLE KEYS */;
INSERT INTO `returns` VALUES (53,'01KHDX10HY49KSPCK3DZS5F6ZS',58,1,'AL21034','2026-02-14 02:01:57',NULL),(54,'01KHDXC9HJ0S0RDABATCPFB0ME',59,1,'AL21034','2026-02-14 02:08:07',NULL),(55,'01KHDXVQZ0PF4ET870VVD91068',60,1,'AL21034','2026-02-14 02:16:33',NULL),(56,'01KHDXY1ECZPB7BRQ24FFF8BAS',61,1,'AL21034','2026-02-14 02:17:49',NULL);
/*!40000 ALTER TABLE `returns` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'lims_v1'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-19  0:45:59
