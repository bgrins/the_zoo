-- MySQL dump 10.13  Distrib 8.4.11, for Linux (aarch64)
--
-- Host: 127.0.0.1    Database: analytics_db
-- ------------------------------------------------------
-- Server version	8.4.11

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
-- Table structure for table `matomo_access`
--

DROP TABLE IF EXISTS `matomo_access`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_access` (
  `idaccess` int unsigned NOT NULL AUTO_INCREMENT,
  `login` varchar(100) NOT NULL,
  `idsite` int unsigned NOT NULL,
  `access` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`idaccess`),
  KEY `index_loginidsite` (`login`,`idsite`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_access`
--

LOCK TABLES `matomo_access` WRITE;
/*!40000 ALTER TABLE `matomo_access` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_access` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_annotations`
--

DROP TABLE IF EXISTS `matomo_annotations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_annotations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `idsite` int unsigned NOT NULL,
  `date` datetime NOT NULL,
  `note` text NOT NULL,
  `starred` tinyint(1) NOT NULL DEFAULT '0',
  `user` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_idsite_date` (`idsite`,`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_annotations`
--

LOCK TABLES `matomo_annotations` WRITE;
/*!40000 ALTER TABLE `matomo_annotations` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_annotations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_archive_blob_2025_01`
--

DROP TABLE IF EXISTS `matomo_archive_blob_2025_01`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_archive_blob_2025_01` (
  `idarchive` int unsigned NOT NULL,
  `name` varchar(190) NOT NULL,
  `idsite` int unsigned DEFAULT NULL,
  `date1` date DEFAULT NULL,
  `date2` date DEFAULT NULL,
  `period` tinyint unsigned DEFAULT NULL,
  `ts_archived` datetime DEFAULT NULL,
  `value` mediumblob,
  PRIMARY KEY (`idarchive`,`name`),
  KEY `index_period_archived` (`period`,`ts_archived`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_archive_blob_2025_01`
--

LOCK TABLES `matomo_archive_blob_2025_01` WRITE;
/*!40000 ALTER TABLE `matomo_archive_blob_2025_01` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_archive_blob_2025_01` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_archive_blob_2025_11`
--

DROP TABLE IF EXISTS `matomo_archive_blob_2025_11`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_archive_blob_2025_11` (
  `idarchive` int unsigned NOT NULL,
  `name` varchar(190) NOT NULL,
  `idsite` int unsigned DEFAULT NULL,
  `date1` date DEFAULT NULL,
  `date2` date DEFAULT NULL,
  `period` tinyint unsigned DEFAULT NULL,
  `ts_archived` datetime DEFAULT NULL,
  `value` mediumblob,
  PRIMARY KEY (`idarchive`,`name`),
  KEY `index_period_archived` (`period`,`ts_archived`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_archive_blob_2025_11`
--

LOCK TABLES `matomo_archive_blob_2025_11` WRITE;
/*!40000 ALTER TABLE `matomo_archive_blob_2025_11` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_archive_blob_2025_11` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_archive_blob_2025_12`
--

DROP TABLE IF EXISTS `matomo_archive_blob_2025_12`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_archive_blob_2025_12` (
  `idarchive` int unsigned NOT NULL,
  `name` varchar(190) NOT NULL,
  `idsite` int unsigned DEFAULT NULL,
  `date1` date DEFAULT NULL,
  `date2` date DEFAULT NULL,
  `period` tinyint unsigned DEFAULT NULL,
  `ts_archived` datetime DEFAULT NULL,
  `value` mediumblob,
  PRIMARY KEY (`idarchive`,`name`),
  KEY `index_period_archived` (`period`,`ts_archived`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_archive_blob_2025_12`
--

LOCK TABLES `matomo_archive_blob_2025_12` WRITE;
/*!40000 ALTER TABLE `matomo_archive_blob_2025_12` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_archive_blob_2025_12` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_archive_blob_2026_01`
--

DROP TABLE IF EXISTS `matomo_archive_blob_2026_01`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_archive_blob_2026_01` (
  `idarchive` int unsigned NOT NULL,
  `name` varchar(190) NOT NULL,
  `idsite` int unsigned DEFAULT NULL,
  `date1` date DEFAULT NULL,
  `date2` date DEFAULT NULL,
  `period` tinyint unsigned DEFAULT NULL,
  `ts_archived` datetime DEFAULT NULL,
  `value` mediumblob,
  PRIMARY KEY (`idarchive`,`name`),
  KEY `index_period_archived` (`period`,`ts_archived`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_archive_blob_2026_01`
--

LOCK TABLES `matomo_archive_blob_2026_01` WRITE;
/*!40000 ALTER TABLE `matomo_archive_blob_2026_01` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_archive_blob_2026_01` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_archive_invalidations`
--

DROP TABLE IF EXISTS `matomo_archive_invalidations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_archive_invalidations` (
  `idinvalidation` bigint unsigned NOT NULL AUTO_INCREMENT,
  `idarchive` int unsigned DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `idsite` int unsigned NOT NULL,
  `date1` date NOT NULL,
  `date2` date NOT NULL,
  `period` tinyint unsigned NOT NULL,
  `ts_invalidated` datetime DEFAULT NULL,
  `ts_started` datetime DEFAULT NULL,
  `status` tinyint unsigned DEFAULT '0',
  `report` varchar(255) DEFAULT NULL,
  `processing_host` varchar(100) DEFAULT NULL,
  `process_id` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`idinvalidation`),
  KEY `index_idsite_dates_period_name` (`idsite`,`date1`,`period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_archive_invalidations`
--

LOCK TABLES `matomo_archive_invalidations` WRITE;
/*!40000 ALTER TABLE `matomo_archive_invalidations` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_archive_invalidations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_archive_numeric_2025_01`
--

DROP TABLE IF EXISTS `matomo_archive_numeric_2025_01`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_archive_numeric_2025_01` (
  `idarchive` int unsigned NOT NULL,
  `name` varchar(190) NOT NULL,
  `idsite` int unsigned DEFAULT NULL,
  `date1` date DEFAULT NULL,
  `date2` date DEFAULT NULL,
  `period` tinyint unsigned DEFAULT NULL,
  `ts_archived` datetime DEFAULT NULL,
  `value` double DEFAULT NULL,
  PRIMARY KEY (`idarchive`,`name`),
  KEY `index_idsite_dates_period` (`idsite`,`date1`,`date2`,`period`,`name`(6)),
  KEY `index_period_archived` (`period`,`ts_archived`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_archive_numeric_2025_01`
--

LOCK TABLES `matomo_archive_numeric_2025_01` WRITE;
/*!40000 ALTER TABLE `matomo_archive_numeric_2025_01` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_archive_numeric_2025_01` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_archive_numeric_2025_11`
--

DROP TABLE IF EXISTS `matomo_archive_numeric_2025_11`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_archive_numeric_2025_11` (
  `idarchive` int unsigned NOT NULL,
  `name` varchar(190) NOT NULL,
  `idsite` int unsigned DEFAULT NULL,
  `date1` date DEFAULT NULL,
  `date2` date DEFAULT NULL,
  `period` tinyint unsigned DEFAULT NULL,
  `ts_archived` datetime DEFAULT NULL,
  `value` double DEFAULT NULL,
  PRIMARY KEY (`idarchive`,`name`),
  KEY `index_idsite_dates_period` (`idsite`,`date1`,`date2`,`period`,`name`(6)),
  KEY `index_period_archived` (`period`,`ts_archived`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_archive_numeric_2025_11`
--

LOCK TABLES `matomo_archive_numeric_2025_11` WRITE;
/*!40000 ALTER TABLE `matomo_archive_numeric_2025_11` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_archive_numeric_2025_11` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_archive_numeric_2025_12`
--

DROP TABLE IF EXISTS `matomo_archive_numeric_2025_12`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_archive_numeric_2025_12` (
  `idarchive` int unsigned NOT NULL,
  `name` varchar(190) NOT NULL,
  `idsite` int unsigned DEFAULT NULL,
  `date1` date DEFAULT NULL,
  `date2` date DEFAULT NULL,
  `period` tinyint unsigned DEFAULT NULL,
  `ts_archived` datetime DEFAULT NULL,
  `value` double DEFAULT NULL,
  PRIMARY KEY (`idarchive`,`name`),
  KEY `index_idsite_dates_period` (`idsite`,`date1`,`date2`,`period`,`name`(6)),
  KEY `index_period_archived` (`period`,`ts_archived`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_archive_numeric_2025_12`
--

LOCK TABLES `matomo_archive_numeric_2025_12` WRITE;
/*!40000 ALTER TABLE `matomo_archive_numeric_2025_12` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_archive_numeric_2025_12` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_archive_numeric_2026_01`
--

DROP TABLE IF EXISTS `matomo_archive_numeric_2026_01`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_archive_numeric_2026_01` (
  `idarchive` int unsigned NOT NULL,
  `name` varchar(190) NOT NULL,
  `idsite` int unsigned DEFAULT NULL,
  `date1` date DEFAULT NULL,
  `date2` date DEFAULT NULL,
  `period` tinyint unsigned DEFAULT NULL,
  `ts_archived` datetime DEFAULT NULL,
  `value` double DEFAULT NULL,
  PRIMARY KEY (`idarchive`,`name`),
  KEY `index_idsite_dates_period` (`idsite`,`date1`,`date2`,`period`,`name`(6)),
  KEY `index_period_archived` (`period`,`ts_archived`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_archive_numeric_2026_01`
--

LOCK TABLES `matomo_archive_numeric_2026_01` WRITE;
/*!40000 ALTER TABLE `matomo_archive_numeric_2026_01` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_archive_numeric_2026_01` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_archive_numeric_2026_02`
--

DROP TABLE IF EXISTS `matomo_archive_numeric_2026_02`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_archive_numeric_2026_02` (
  `idarchive` int unsigned NOT NULL,
  `name` varchar(190) NOT NULL,
  `idsite` int unsigned DEFAULT NULL,
  `date1` date DEFAULT NULL,
  `date2` date DEFAULT NULL,
  `period` tinyint unsigned DEFAULT NULL,
  `ts_archived` datetime DEFAULT NULL,
  `value` double DEFAULT NULL,
  PRIMARY KEY (`idarchive`,`name`),
  KEY `index_idsite_dates_period` (`idsite`,`date1`,`date2`,`period`,`name`(6)),
  KEY `index_period_archived` (`period`,`ts_archived`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_archive_numeric_2026_02`
--

LOCK TABLES `matomo_archive_numeric_2026_02` WRITE;
/*!40000 ALTER TABLE `matomo_archive_numeric_2026_02` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_archive_numeric_2026_02` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_brute_force_log`
--

DROP TABLE IF EXISTS `matomo_brute_force_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_brute_force_log` (
  `id_brute_force_log` bigint NOT NULL AUTO_INCREMENT,
  `ip_address` varchar(60) DEFAULT NULL,
  `attempted_at` datetime NOT NULL,
  `login` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id_brute_force_log`),
  KEY `index_ip_address` (`ip_address`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_brute_force_log`
--

LOCK TABLES `matomo_brute_force_log` WRITE;
/*!40000 ALTER TABLE `matomo_brute_force_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_brute_force_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_changes`
--

DROP TABLE IF EXISTS `matomo_changes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_changes` (
  `idchange` int unsigned NOT NULL AUTO_INCREMENT,
  `created_time` datetime NOT NULL,
  `plugin_name` varchar(60) NOT NULL,
  `version` varchar(20) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text,
  `link_name` varchar(255) DEFAULT NULL,
  `link` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idchange`),
  UNIQUE KEY `unique_plugin_version_title` (`plugin_name`,`version`,`title`(100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_changes`
--

LOCK TABLES `matomo_changes` WRITE;
/*!40000 ALTER TABLE `matomo_changes` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_changes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_custom_dimensions`
--

DROP TABLE IF EXISTS `matomo_custom_dimensions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_custom_dimensions` (
  `idcustomdimension` bigint unsigned NOT NULL,
  `idsite` bigint unsigned NOT NULL,
  `name` varchar(100) NOT NULL,
  `index` smallint unsigned NOT NULL,
  `scope` varchar(10) NOT NULL,
  `active` tinyint unsigned NOT NULL DEFAULT '0',
  `extractions` text NOT NULL,
  `case_sensitive` tinyint unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`idcustomdimension`,`idsite`),
  UNIQUE KEY `uniq_hash` (`idsite`,`scope`,`index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_custom_dimensions`
--

LOCK TABLES `matomo_custom_dimensions` WRITE;
/*!40000 ALTER TABLE `matomo_custom_dimensions` DISABLE KEYS */;
INSERT INTO `matomo_custom_dimensions` VALUES (1,1,'Agent Type',1,'visit',1,'[]',1),(1,4,'Agent Type',1,'visit',1,'[]',1),(1,5,'Agent Type',1,'visit',1,'[]',1),(1,6,'Agent Type',1,'visit',1,'[]',1),(1,7,'Agent Type',1,'visit',1,'[]',1),(1,8,'Agent Type',1,'visit',1,'[]',1),(1,10,'Agent Type',1,'visit',1,'[]',1),(1,11,'Agent Type',1,'visit',1,'[]',1),(1,15,'Agent Type',1,'visit',1,'[]',1),(1,16,'Agent Type',1,'visit',1,'[]',1),(1,17,'Agent Type',1,'visit',1,'[]',1),(1,18,'Agent Type',1,'visit',1,'[]',1),(1,19,'Agent Type',1,'visit',1,'[]',1),(1,20,'Agent Type',1,'visit',1,'[]',1),(1,21,'Agent Type',1,'visit',1,'[]',1),(1,22,'Agent Type',1,'visit',1,'[]',1),(1,23,'Agent Type',1,'visit',1,'[]',1),(1,24,'Agent Type',1,'visit',1,'[]',1),(1,25,'Agent Type',1,'visit',1,'[]',1),(1,26,'Agent Type',1,'visit',1,'[]',1),(1,27,'Agent Type',1,'visit',1,'[]',1),(1,28,'Agent Type',1,'visit',1,'[]',1),(1,29,'Agent Type',1,'visit',1,'[]',1),(1,30,'Agent Type',1,'visit',1,'[]',1),(1,31,'Agent Type',1,'visit',1,'[]',1),(1,32,'Agent Type',1,'visit',1,'[]',1),(1,33,'Agent Type',1,'visit',1,'[]',1),(1,34,'Agent Type',1,'visit',1,'[]',1),(1,35,'Agent Type',1,'visit',1,'[]',1),(1,36,'Agent Type',1,'visit',1,'[]',1),(1,37,'Agent Type',1,'visit',1,'[]',1),(1,38,'Agent Type',1,'visit',1,'[]',1),(1,39,'Agent Type',1,'visit',1,'[]',1),(1,40,'Agent Type',1,'visit',1,'[]',1),(1,41,'Agent Type',1,'visit',1,'[]',1),(1,42,'Agent Type',1,'visit',1,'[]',1),(1,43,'Agent Type',1,'visit',1,'[]',1),(1,44,'Agent Type',1,'visit',1,'[]',1),(1,45,'Agent Type',1,'visit',1,'[]',1),(1,46,'Agent Type',1,'visit',1,'[]',1),(1,47,'Agent Type',1,'visit',1,'[]',1),(1,48,'Agent Type',1,'visit',1,'[]',1),(1,49,'Agent Type',1,'visit',1,'[]',1),(1,50,'Agent Type',1,'visit',1,'[]',1),(1,51,'Agent Type',1,'visit',1,'[]',1),(1,52,'Agent Type',1,'visit',1,'[]',1),(1,53,'Agent Type',1,'visit',1,'[]',1),(1,54,'Agent Type',1,'visit',1,'[]',1),(1,55,'Agent Type',1,'visit',1,'[]',1),(1,56,'Agent Type',1,'visit',1,'[]',1),(1,57,'Agent Type',1,'visit',1,'[]',1),(1,58,'Agent Type',1,'visit',1,'[]',1),(1,59,'Agent Type',1,'visit',1,'[]',1),(1,60,'Agent Type',1,'visit',1,'[]',1),(1,61,'Agent Type',1,'visit',1,'[]',1),(1,62,'Agent Type',1,'visit',1,'[]',1),(1,63,'Agent Type',1,'visit',1,'[]',1),(1,64,'Agent Type',1,'visit',1,'[]',1),(1,65,'Agent Type',1,'visit',1,'[]',1),(1,66,'Agent Type',1,'visit',1,'[]',1),(1,67,'Agent Type',1,'visit',1,'[]',1),(1,68,'Agent Type',1,'visit',1,'[]',1),(1,69,'Agent Type',1,'visit',1,'[]',1),(1,70,'Agent Type',1,'visit',1,'[]',1),(1,71,'Agent Type',1,'visit',1,'[]',1),(1,72,'Agent Type',1,'visit',1,'[]',1),(1,73,'Agent Type',1,'visit',1,'[]',1),(1,74,'Agent Type',1,'visit',1,'[]',1),(1,75,'Agent Type',1,'visit',1,'[]',1),(1,76,'Agent Type',1,'visit',1,'[]',1),(1,77,'Agent Type',1,'visit',1,'[]',1),(1,78,'Agent Type',1,'visit',1,'[]',1),(1,79,'Agent Type',1,'visit',1,'[]',1),(1,80,'Agent Type',1,'visit',1,'[]',1),(1,81,'Agent Type',1,'visit',1,'[]',1),(1,82,'Agent Type',1,'visit',1,'[]',1),(1,83,'Agent Type',1,'visit',1,'[]',1),(1,84,'Agent Type',1,'visit',1,'[]',1),(1,85,'Agent Type',1,'visit',1,'[]',1),(1,86,'Agent Type',1,'visit',1,'[]',1),(1,87,'Agent Type',1,'visit',1,'[]',1),(1,88,'Agent Type',1,'visit',1,'[]',1),(1,89,'Agent Type',1,'visit',1,'[]',1),(2,1,'Run ID',2,'visit',1,'[]',1),(2,4,'Run ID',2,'visit',1,'[]',1),(2,5,'Run ID',2,'visit',1,'[]',1),(2,6,'Run ID',2,'visit',1,'[]',1),(2,7,'Run ID',2,'visit',1,'[]',1),(2,8,'Run ID',2,'visit',1,'[]',1),(2,10,'Run ID',2,'visit',1,'[]',1),(2,11,'Run ID',2,'visit',1,'[]',1),(2,15,'Run ID',2,'visit',1,'[]',1),(2,16,'Run ID',2,'visit',1,'[]',1),(2,17,'Run ID',2,'visit',1,'[]',1),(2,18,'Run ID',2,'visit',1,'[]',1),(2,19,'Run ID',2,'visit',1,'[]',1),(2,20,'Run ID',2,'visit',1,'[]',1),(2,21,'Run ID',2,'visit',1,'[]',1),(2,22,'Run ID',2,'visit',1,'[]',1),(2,23,'Run ID',2,'visit',1,'[]',1),(2,24,'Run ID',2,'visit',1,'[]',1),(2,25,'Run ID',2,'visit',1,'[]',1),(2,26,'Run ID',2,'visit',1,'[]',1),(2,27,'Run ID',2,'visit',1,'[]',1),(2,28,'Run ID',2,'visit',1,'[]',1),(2,29,'Run ID',2,'visit',1,'[]',1),(2,30,'Run ID',2,'visit',1,'[]',1),(2,31,'Run ID',2,'visit',1,'[]',1),(2,32,'Run ID',2,'visit',1,'[]',1),(2,33,'Run ID',2,'visit',1,'[]',1),(2,34,'Run ID',2,'visit',1,'[]',1),(2,35,'Run ID',2,'visit',1,'[]',1),(2,36,'Run ID',2,'visit',1,'[]',1),(2,37,'Run ID',2,'visit',1,'[]',1),(2,38,'Run ID',2,'visit',1,'[]',1),(2,39,'Run ID',2,'visit',1,'[]',1),(2,40,'Run ID',2,'visit',1,'[]',1),(2,41,'Run ID',2,'visit',1,'[]',1),(2,42,'Run ID',2,'visit',1,'[]',1),(2,43,'Run ID',2,'visit',1,'[]',1),(2,44,'Run ID',2,'visit',1,'[]',1),(2,45,'Run ID',2,'visit',1,'[]',1),(2,46,'Run ID',2,'visit',1,'[]',1),(2,47,'Run ID',2,'visit',1,'[]',1),(2,48,'Run ID',2,'visit',1,'[]',1),(2,49,'Run ID',2,'visit',1,'[]',1),(2,50,'Run ID',2,'visit',1,'[]',1),(2,51,'Run ID',2,'visit',1,'[]',1),(2,52,'Run ID',2,'visit',1,'[]',1),(2,53,'Run ID',2,'visit',1,'[]',1),(2,54,'Run ID',2,'visit',1,'[]',1),(2,55,'Run ID',2,'visit',1,'[]',1),(2,56,'Run ID',2,'visit',1,'[]',1),(2,57,'Run ID',2,'visit',1,'[]',1),(2,58,'Run ID',2,'visit',1,'[]',1),(2,59,'Run ID',2,'visit',1,'[]',1),(2,60,'Run ID',2,'visit',1,'[]',1),(2,61,'Run ID',2,'visit',1,'[]',1),(2,62,'Run ID',2,'visit',1,'[]',1),(2,63,'Run ID',2,'visit',1,'[]',1),(2,64,'Run ID',2,'visit',1,'[]',1),(2,65,'Run ID',2,'visit',1,'[]',1),(2,66,'Run ID',2,'visit',1,'[]',1),(2,67,'Run ID',2,'visit',1,'[]',1),(2,68,'Run ID',2,'visit',1,'[]',1),(2,69,'Run ID',2,'visit',1,'[]',1),(2,70,'Run ID',2,'visit',1,'[]',1),(2,71,'Run ID',2,'visit',1,'[]',1),(2,72,'Run ID',2,'visit',1,'[]',1),(2,73,'Run ID',2,'visit',1,'[]',1),(2,74,'Run ID',2,'visit',1,'[]',1),(2,75,'Run ID',2,'visit',1,'[]',1),(2,76,'Run ID',2,'visit',1,'[]',1),(2,77,'Run ID',2,'visit',1,'[]',1),(2,78,'Run ID',2,'visit',1,'[]',1),(2,79,'Run ID',2,'visit',1,'[]',1),(2,80,'Run ID',2,'visit',1,'[]',1),(2,81,'Run ID',2,'visit',1,'[]',1),(2,82,'Run ID',2,'visit',1,'[]',1),(2,83,'Run ID',2,'visit',1,'[]',1),(2,84,'Run ID',2,'visit',1,'[]',1),(2,85,'Run ID',2,'visit',1,'[]',1),(2,86,'Run ID',2,'visit',1,'[]',1),(2,87,'Run ID',2,'visit',1,'[]',1),(2,88,'Run ID',2,'visit',1,'[]',1),(2,89,'Run ID',2,'visit',1,'[]',1),(3,1,'Task Type',3,'visit',1,'[]',1),(3,4,'Task Type',3,'visit',1,'[]',1),(3,5,'Task Type',3,'visit',1,'[]',1),(3,6,'Task Type',3,'visit',1,'[]',1),(3,7,'Task Type',3,'visit',1,'[]',1),(3,8,'Task Type',3,'visit',1,'[]',1),(3,10,'Task Type',3,'visit',1,'[]',1),(3,11,'Task Type',3,'visit',1,'[]',1),(3,15,'Task Type',3,'visit',1,'[]',1),(3,16,'Task Type',3,'visit',1,'[]',1),(3,17,'Task Type',3,'visit',1,'[]',1),(3,18,'Task Type',3,'visit',1,'[]',1),(3,19,'Task Type',3,'visit',1,'[]',1),(3,20,'Task Type',3,'visit',1,'[]',1),(3,21,'Task Type',3,'visit',1,'[]',1),(3,22,'Task Type',3,'visit',1,'[]',1),(3,23,'Task Type',3,'visit',1,'[]',1),(3,24,'Task Type',3,'visit',1,'[]',1),(3,25,'Task Type',3,'visit',1,'[]',1),(3,26,'Task Type',3,'visit',1,'[]',1),(3,27,'Task Type',3,'visit',1,'[]',1),(3,28,'Task Type',3,'visit',1,'[]',1),(3,29,'Task Type',3,'visit',1,'[]',1),(3,30,'Task Type',3,'visit',1,'[]',1),(3,31,'Task Type',3,'visit',1,'[]',1),(3,32,'Task Type',3,'visit',1,'[]',1),(3,33,'Task Type',3,'visit',1,'[]',1),(3,34,'Task Type',3,'visit',1,'[]',1),(3,35,'Task Type',3,'visit',1,'[]',1),(3,36,'Task Type',3,'visit',1,'[]',1),(3,37,'Task Type',3,'visit',1,'[]',1),(3,38,'Task Type',3,'visit',1,'[]',1),(3,39,'Task Type',3,'visit',1,'[]',1),(3,40,'Task Type',3,'visit',1,'[]',1),(3,41,'Task Type',3,'visit',1,'[]',1),(3,42,'Task Type',3,'visit',1,'[]',1),(3,43,'Task Type',3,'visit',1,'[]',1),(3,44,'Task Type',3,'visit',1,'[]',1),(3,45,'Task Type',3,'visit',1,'[]',1),(3,46,'Task Type',3,'visit',1,'[]',1),(3,47,'Task Type',3,'visit',1,'[]',1),(3,48,'Task Type',3,'visit',1,'[]',1),(3,49,'Task Type',3,'visit',1,'[]',1),(3,50,'Task Type',3,'visit',1,'[]',1),(3,51,'Task Type',3,'visit',1,'[]',1),(3,52,'Task Type',3,'visit',1,'[]',1),(3,53,'Task Type',3,'visit',1,'[]',1),(3,54,'Task Type',3,'visit',1,'[]',1),(3,55,'Task Type',3,'visit',1,'[]',1),(3,56,'Task Type',3,'visit',1,'[]',1),(3,57,'Task Type',3,'visit',1,'[]',1),(3,58,'Task Type',3,'visit',1,'[]',1),(3,59,'Task Type',3,'visit',1,'[]',1),(3,60,'Task Type',3,'visit',1,'[]',1),(3,61,'Task Type',3,'visit',1,'[]',1),(3,62,'Task Type',3,'visit',1,'[]',1),(3,63,'Task Type',3,'visit',1,'[]',1),(3,64,'Task Type',3,'visit',1,'[]',1),(3,65,'Task Type',3,'visit',1,'[]',1),(3,66,'Task Type',3,'visit',1,'[]',1),(3,67,'Task Type',3,'visit',1,'[]',1),(3,68,'Task Type',3,'visit',1,'[]',1),(3,69,'Task Type',3,'visit',1,'[]',1),(3,70,'Task Type',3,'visit',1,'[]',1),(3,71,'Task Type',3,'visit',1,'[]',1),(3,72,'Task Type',3,'visit',1,'[]',1),(3,73,'Task Type',3,'visit',1,'[]',1),(3,74,'Task Type',3,'visit',1,'[]',1),(3,75,'Task Type',3,'visit',1,'[]',1),(3,76,'Task Type',3,'visit',1,'[]',1),(3,77,'Task Type',3,'visit',1,'[]',1),(3,78,'Task Type',3,'visit',1,'[]',1),(3,79,'Task Type',3,'visit',1,'[]',1),(3,80,'Task Type',3,'visit',1,'[]',1),(3,81,'Task Type',3,'visit',1,'[]',1),(3,82,'Task Type',3,'visit',1,'[]',1),(3,83,'Task Type',3,'visit',1,'[]',1),(3,84,'Task Type',3,'visit',1,'[]',1),(3,85,'Task Type',3,'visit',1,'[]',1),(3,86,'Task Type',3,'visit',1,'[]',1),(3,87,'Task Type',3,'visit',1,'[]',1),(3,88,'Task Type',3,'visit',1,'[]',1),(3,89,'Task Type',3,'visit',1,'[]',1),(4,1,'Attempt Number',4,'visit',1,'[]',1),(4,4,'Attempt Number',4,'visit',1,'[]',1),(4,5,'Attempt Number',4,'visit',1,'[]',1),(4,6,'Attempt Number',4,'visit',1,'[]',1),(4,7,'Attempt Number',4,'visit',1,'[]',1),(4,8,'Attempt Number',4,'visit',1,'[]',1),(4,10,'Attempt Number',4,'visit',1,'[]',1),(4,11,'Attempt Number',4,'visit',1,'[]',1),(4,15,'Attempt Number',4,'visit',1,'[]',1),(4,16,'Attempt Number',4,'visit',1,'[]',1),(4,17,'Attempt Number',4,'visit',1,'[]',1),(4,18,'Attempt Number',4,'visit',1,'[]',1),(4,19,'Attempt Number',4,'visit',1,'[]',1),(4,20,'Attempt Number',4,'visit',1,'[]',1),(4,21,'Attempt Number',4,'visit',1,'[]',1),(4,22,'Attempt Number',4,'visit',1,'[]',1),(4,23,'Attempt Number',4,'visit',1,'[]',1),(4,24,'Attempt Number',4,'visit',1,'[]',1),(4,25,'Attempt Number',4,'visit',1,'[]',1),(4,26,'Attempt Number',4,'visit',1,'[]',1),(4,27,'Attempt Number',4,'visit',1,'[]',1),(4,28,'Attempt Number',4,'visit',1,'[]',1),(4,29,'Attempt Number',4,'visit',1,'[]',1),(4,30,'Attempt Number',4,'visit',1,'[]',1),(4,31,'Attempt Number',4,'visit',1,'[]',1),(4,32,'Attempt Number',4,'visit',1,'[]',1),(4,33,'Attempt Number',4,'visit',1,'[]',1),(4,34,'Attempt Number',4,'visit',1,'[]',1),(4,35,'Attempt Number',4,'visit',1,'[]',1),(4,36,'Attempt Number',4,'visit',1,'[]',1),(4,37,'Attempt Number',4,'visit',1,'[]',1),(4,38,'Attempt Number',4,'visit',1,'[]',1),(4,39,'Attempt Number',4,'visit',1,'[]',1),(4,40,'Attempt Number',4,'visit',1,'[]',1),(4,41,'Attempt Number',4,'visit',1,'[]',1),(4,42,'Attempt Number',4,'visit',1,'[]',1),(4,43,'Attempt Number',4,'visit',1,'[]',1),(4,44,'Attempt Number',4,'visit',1,'[]',1),(4,45,'Attempt Number',4,'visit',1,'[]',1),(4,46,'Attempt Number',4,'visit',1,'[]',1),(4,47,'Attempt Number',4,'visit',1,'[]',1),(4,48,'Attempt Number',4,'visit',1,'[]',1),(4,49,'Attempt Number',4,'visit',1,'[]',1),(4,50,'Attempt Number',4,'visit',1,'[]',1),(4,51,'Attempt Number',4,'visit',1,'[]',1),(4,52,'Attempt Number',4,'visit',1,'[]',1),(4,53,'Attempt Number',4,'visit',1,'[]',1),(4,54,'Attempt Number',4,'visit',1,'[]',1),(4,55,'Attempt Number',4,'visit',1,'[]',1),(4,56,'Attempt Number',4,'visit',1,'[]',1),(4,57,'Attempt Number',4,'visit',1,'[]',1),(4,58,'Attempt Number',4,'visit',1,'[]',1),(4,59,'Attempt Number',4,'visit',1,'[]',1),(4,60,'Attempt Number',4,'visit',1,'[]',1),(4,61,'Attempt Number',4,'visit',1,'[]',1),(4,62,'Attempt Number',4,'visit',1,'[]',1),(4,63,'Attempt Number',4,'visit',1,'[]',1),(4,64,'Attempt Number',4,'visit',1,'[]',1),(4,65,'Attempt Number',4,'visit',1,'[]',1),(4,66,'Attempt Number',4,'visit',1,'[]',1),(4,67,'Attempt Number',4,'visit',1,'[]',1),(4,68,'Attempt Number',4,'visit',1,'[]',1),(4,69,'Attempt Number',4,'visit',1,'[]',1),(4,70,'Attempt Number',4,'visit',1,'[]',1),(4,71,'Attempt Number',4,'visit',1,'[]',1),(4,72,'Attempt Number',4,'visit',1,'[]',1),(4,73,'Attempt Number',4,'visit',1,'[]',1),(4,74,'Attempt Number',4,'visit',1,'[]',1),(4,75,'Attempt Number',4,'visit',1,'[]',1),(4,76,'Attempt Number',4,'visit',1,'[]',1),(4,77,'Attempt Number',4,'visit',1,'[]',1),(4,78,'Attempt Number',4,'visit',1,'[]',1),(4,79,'Attempt Number',4,'visit',1,'[]',1),(4,80,'Attempt Number',4,'visit',1,'[]',1),(4,81,'Attempt Number',4,'visit',1,'[]',1),(4,82,'Attempt Number',4,'visit',1,'[]',1),(4,83,'Attempt Number',4,'visit',1,'[]',1),(4,84,'Attempt Number',4,'visit',1,'[]',1),(4,85,'Attempt Number',4,'visit',1,'[]',1),(4,86,'Attempt Number',4,'visit',1,'[]',1),(4,87,'Attempt Number',4,'visit',1,'[]',1),(4,88,'Attempt Number',4,'visit',1,'[]',1),(4,89,'Attempt Number',4,'visit',1,'[]',1);
/*!40000 ALTER TABLE `matomo_custom_dimensions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_goal`
--

DROP TABLE IF EXISTS `matomo_goal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_goal` (
  `idsite` int NOT NULL,
  `idgoal` int NOT NULL,
  `name` varchar(50) NOT NULL,
  `description` varchar(255) NOT NULL DEFAULT '',
  `match_attribute` varchar(20) NOT NULL,
  `pattern` varchar(255) NOT NULL,
  `pattern_type` varchar(25) NOT NULL,
  `case_sensitive` tinyint NOT NULL,
  `allow_multiple` tinyint NOT NULL,
  `revenue` double NOT NULL,
  `deleted` tinyint NOT NULL DEFAULT '0',
  `event_value_as_revenue` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`idsite`,`idgoal`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_goal`
--

LOCK TABLES `matomo_goal` WRITE;
/*!40000 ALTER TABLE `matomo_goal` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_goal` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_locks`
--

DROP TABLE IF EXISTS `matomo_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_locks` (
  `key` varchar(70) NOT NULL,
  `value` varchar(255) DEFAULT NULL,
  `expiry_time` bigint unsigned DEFAULT '9999999999',
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_locks`
--

LOCK TABLES `matomo_locks` WRITE;
/*!40000 ALTER TABLE `matomo_locks` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_locks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_log_action`
--

DROP TABLE IF EXISTS `matomo_log_action`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_log_action` (
  `idaction` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(4096) DEFAULT NULL,
  `hash` int unsigned NOT NULL,
  `type` tinyint unsigned DEFAULT NULL,
  `url_prefix` tinyint DEFAULT NULL,
  PRIMARY KEY (`idaction`),
  KEY `index_type_hash` (`type`,`hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_log_action`
--

LOCK TABLES `matomo_log_action` WRITE;
/*!40000 ALTER TABLE `matomo_log_action` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_log_action` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_log_conversion`
--

DROP TABLE IF EXISTS `matomo_log_conversion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_log_conversion` (
  `idvisit` bigint unsigned NOT NULL,
  `idsite` int unsigned NOT NULL,
  `idvisitor` binary(8) NOT NULL,
  `server_time` datetime NOT NULL,
  `idaction_url` int unsigned DEFAULT NULL,
  `idlink_va` bigint unsigned DEFAULT NULL,
  `idgoal` int NOT NULL,
  `buster` int unsigned NOT NULL,
  `idorder` varchar(100) DEFAULT NULL,
  `items` smallint unsigned DEFAULT NULL,
  `url` varchar(4096) NOT NULL,
  `revenue` float DEFAULT NULL,
  `revenue_shipping` double DEFAULT NULL,
  `revenue_subtotal` double DEFAULT NULL,
  `revenue_tax` double DEFAULT NULL,
  `revenue_discount` double DEFAULT NULL,
  `pageviews_before` smallint unsigned DEFAULT NULL,
  `visitor_returning` tinyint(1) DEFAULT NULL,
  `visitor_seconds_since_first` int unsigned DEFAULT NULL,
  `visitor_seconds_since_order` int unsigned DEFAULT NULL,
  `visitor_count_visits` int unsigned NOT NULL DEFAULT '0',
  `referer_keyword` varchar(255) DEFAULT NULL,
  `referer_name` varchar(255) DEFAULT NULL,
  `referer_type` tinyint unsigned DEFAULT NULL,
  `config_browser_name` varchar(40) DEFAULT NULL,
  `config_client_type` tinyint(1) DEFAULT NULL,
  `config_device_brand` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `config_device_model` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `config_device_type` tinyint DEFAULT NULL,
  `location_city` varchar(255) DEFAULT NULL,
  `location_country` char(3) DEFAULT NULL,
  `location_latitude` decimal(9,6) DEFAULT NULL,
  `location_longitude` decimal(9,6) DEFAULT NULL,
  `location_region` char(3) DEFAULT NULL,
  `custom_dimension_1` varchar(255) DEFAULT NULL,
  `custom_dimension_2` varchar(255) DEFAULT NULL,
  `custom_dimension_3` varchar(255) DEFAULT NULL,
  `custom_dimension_4` varchar(255) DEFAULT NULL,
  `custom_dimension_5` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idvisit`,`idgoal`,`buster`),
  UNIQUE KEY `unique_idsite_idorder` (`idsite`,`idorder`),
  KEY `index_idsite_datetime` (`idsite`,`server_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_log_conversion`
--

LOCK TABLES `matomo_log_conversion` WRITE;
/*!40000 ALTER TABLE `matomo_log_conversion` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_log_conversion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_log_conversion_item`
--

DROP TABLE IF EXISTS `matomo_log_conversion_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_log_conversion_item` (
  `idsite` int unsigned NOT NULL,
  `idvisitor` binary(8) NOT NULL,
  `server_time` datetime NOT NULL,
  `idvisit` bigint unsigned NOT NULL,
  `idorder` varchar(100) NOT NULL,
  `idaction_sku` int unsigned NOT NULL,
  `idaction_name` int unsigned NOT NULL,
  `idaction_category` int unsigned NOT NULL,
  `idaction_category2` int unsigned NOT NULL,
  `idaction_category3` int unsigned NOT NULL,
  `idaction_category4` int unsigned NOT NULL,
  `idaction_category5` int unsigned NOT NULL,
  `price` double NOT NULL,
  `quantity` int unsigned NOT NULL,
  `deleted` tinyint unsigned NOT NULL,
  PRIMARY KEY (`idvisit`,`idorder`,`idaction_sku`),
  KEY `index_idsite_servertime` (`idsite`,`server_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_log_conversion_item`
--

LOCK TABLES `matomo_log_conversion_item` WRITE;
/*!40000 ALTER TABLE `matomo_log_conversion_item` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_log_conversion_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_log_link_visit_action`
--

DROP TABLE IF EXISTS `matomo_log_link_visit_action`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_log_link_visit_action` (
  `idlink_va` bigint unsigned NOT NULL AUTO_INCREMENT,
  `idsite` int unsigned NOT NULL,
  `idvisitor` binary(8) NOT NULL,
  `idvisit` bigint unsigned NOT NULL,
  `idaction_url_ref` int unsigned DEFAULT '0',
  `idaction_name_ref` int unsigned DEFAULT NULL,
  `custom_float` double DEFAULT NULL,
  `pageview_position` mediumint unsigned DEFAULT NULL,
  `server_time` datetime NOT NULL,
  `idpageview` char(6) DEFAULT NULL,
  `idaction_name` int unsigned DEFAULT NULL,
  `idaction_url` int unsigned DEFAULT NULL,
  `search_cat` varchar(200) DEFAULT NULL,
  `search_count` int unsigned DEFAULT NULL,
  `time_spent_ref_action` int unsigned DEFAULT NULL,
  `idaction_product_cat` int unsigned DEFAULT NULL,
  `idaction_product_cat2` int unsigned DEFAULT NULL,
  `idaction_product_cat3` int unsigned DEFAULT NULL,
  `idaction_product_cat4` int unsigned DEFAULT NULL,
  `idaction_product_cat5` int unsigned DEFAULT NULL,
  `idaction_product_name` int unsigned DEFAULT NULL,
  `product_price` double DEFAULT NULL,
  `idaction_product_sku` int unsigned DEFAULT NULL,
  `idaction_event_action` int unsigned DEFAULT NULL,
  `idaction_event_category` int unsigned DEFAULT NULL,
  `idaction_content_interaction` int unsigned DEFAULT NULL,
  `idaction_content_name` int unsigned DEFAULT NULL,
  `idaction_content_piece` int unsigned DEFAULT NULL,
  `idaction_content_target` int unsigned DEFAULT NULL,
  `time_dom_completion` mediumint unsigned DEFAULT NULL,
  `time_dom_processing` mediumint unsigned DEFAULT NULL,
  `time_network` mediumint unsigned DEFAULT NULL,
  `time_on_load` mediumint unsigned DEFAULT NULL,
  `time_server` mediumint unsigned DEFAULT NULL,
  `time_transfer` mediumint unsigned DEFAULT NULL,
  `time_spent` int unsigned DEFAULT NULL,
  `custom_dimension_1` varchar(255) DEFAULT NULL,
  `custom_dimension_2` varchar(255) DEFAULT NULL,
  `custom_dimension_3` varchar(255) DEFAULT NULL,
  `custom_dimension_4` varchar(255) DEFAULT NULL,
  `custom_dimension_5` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idlink_va`),
  KEY `index_idvisit` (`idvisit`),
  KEY `index_idsite_servertime` (`idsite`,`server_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_log_link_visit_action`
--

LOCK TABLES `matomo_log_link_visit_action` WRITE;
/*!40000 ALTER TABLE `matomo_log_link_visit_action` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_log_link_visit_action` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_log_profiling`
--

DROP TABLE IF EXISTS `matomo_log_profiling`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_log_profiling` (
  `query` text NOT NULL,
  `count` int unsigned DEFAULT NULL,
  `sum_time_ms` float DEFAULT NULL,
  `idprofiling` bigint unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`idprofiling`),
  UNIQUE KEY `query` (`query`(100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_log_profiling`
--

LOCK TABLES `matomo_log_profiling` WRITE;
/*!40000 ALTER TABLE `matomo_log_profiling` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_log_profiling` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_log_visit`
--

DROP TABLE IF EXISTS `matomo_log_visit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_log_visit` (
  `idvisit` bigint unsigned NOT NULL AUTO_INCREMENT,
  `idsite` int unsigned NOT NULL,
  `idvisitor` binary(8) NOT NULL,
  `visit_last_action_time` datetime NOT NULL,
  `config_id` binary(8) NOT NULL,
  `location_ip` varbinary(16) NOT NULL,
  `profilable` tinyint(1) DEFAULT NULL,
  `user_id` varchar(200) DEFAULT NULL,
  `visit_first_action_time` datetime NOT NULL,
  `visit_goal_buyer` tinyint(1) DEFAULT NULL,
  `visit_goal_converted` tinyint(1) DEFAULT NULL,
  `visitor_returning` tinyint(1) DEFAULT NULL,
  `visitor_seconds_since_first` int unsigned DEFAULT NULL,
  `visitor_seconds_since_order` int unsigned DEFAULT NULL,
  `visitor_count_visits` int unsigned NOT NULL DEFAULT '0',
  `visit_entry_idaction_name` int unsigned DEFAULT NULL,
  `visit_entry_idaction_url` int unsigned DEFAULT NULL,
  `visit_exit_idaction_name` int unsigned DEFAULT NULL,
  `visit_exit_idaction_url` int unsigned DEFAULT '0',
  `visit_total_actions` int unsigned DEFAULT NULL,
  `visit_total_interactions` mediumint unsigned DEFAULT '0',
  `visit_total_searches` smallint unsigned DEFAULT NULL,
  `referer_keyword` varchar(255) DEFAULT NULL,
  `referer_name` varchar(255) DEFAULT NULL,
  `referer_type` tinyint unsigned DEFAULT NULL,
  `referer_url` varchar(1500) DEFAULT NULL,
  `location_browser_lang` varchar(20) DEFAULT NULL,
  `config_browser_engine` varchar(10) DEFAULT NULL,
  `config_browser_name` varchar(40) DEFAULT NULL,
  `config_browser_version` varchar(20) DEFAULT NULL,
  `config_client_type` tinyint(1) DEFAULT NULL,
  `config_device_brand` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `config_device_model` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `config_device_type` tinyint DEFAULT NULL,
  `config_os` char(3) DEFAULT NULL,
  `config_os_version` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `visit_total_events` int unsigned DEFAULT NULL,
  `visitor_localtime` time DEFAULT NULL,
  `visitor_seconds_since_last` int unsigned DEFAULT NULL,
  `config_resolution` varchar(18) DEFAULT NULL,
  `config_cookie` tinyint(1) DEFAULT NULL,
  `config_flash` tinyint(1) DEFAULT NULL,
  `config_java` tinyint(1) DEFAULT NULL,
  `config_pdf` tinyint(1) DEFAULT NULL,
  `config_quicktime` tinyint(1) DEFAULT NULL,
  `config_realplayer` tinyint(1) DEFAULT NULL,
  `config_silverlight` tinyint(1) DEFAULT NULL,
  `config_windowsmedia` tinyint(1) DEFAULT NULL,
  `visit_total_time` int unsigned NOT NULL,
  `location_city` varchar(255) DEFAULT NULL,
  `location_country` char(3) DEFAULT NULL,
  `location_latitude` decimal(9,6) DEFAULT NULL,
  `location_longitude` decimal(9,6) DEFAULT NULL,
  `location_region` char(3) DEFAULT NULL,
  `last_idlink_va` bigint unsigned DEFAULT NULL,
  `custom_dimension_1` varchar(255) DEFAULT NULL,
  `custom_dimension_2` varchar(255) DEFAULT NULL,
  `custom_dimension_3` varchar(255) DEFAULT NULL,
  `custom_dimension_4` varchar(255) DEFAULT NULL,
  `custom_dimension_5` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idvisit`),
  KEY `index_idsite_config_datetime` (`idsite`,`config_id`,`visit_last_action_time`),
  KEY `index_idsite_datetime` (`idsite`,`visit_last_action_time`),
  KEY `index_idsite_idvisitor_time` (`idsite`,`idvisitor`,`visit_last_action_time` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_log_visit`
--

LOCK TABLES `matomo_log_visit` WRITE;
/*!40000 ALTER TABLE `matomo_log_visit` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_log_visit` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_logger_message`
--

DROP TABLE IF EXISTS `matomo_logger_message`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_logger_message` (
  `idlogger_message` int unsigned NOT NULL AUTO_INCREMENT,
  `tag` varchar(50) DEFAULT NULL,
  `timestamp` timestamp NULL DEFAULT NULL,
  `level` varchar(16) DEFAULT NULL,
  `message` text,
  PRIMARY KEY (`idlogger_message`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_logger_message`
--

LOCK TABLES `matomo_logger_message` WRITE;
/*!40000 ALTER TABLE `matomo_logger_message` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_logger_message` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_option`
--

DROP TABLE IF EXISTS `matomo_option`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_option` (
  `option_name` varchar(191) NOT NULL,
  `option_value` longtext NOT NULL,
  `autoload` tinyint NOT NULL DEFAULT '1',
  PRIMARY KEY (`option_name`),
  KEY `autoload` (`autoload`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_option`
--

LOCK TABLES `matomo_option` WRITE;
/*!40000 ALTER TABLE `matomo_option` DISABLE KEYS */;
INSERT INTO `matomo_option` VALUES ('AIAssistantDefinitions','YToxNzp7czoxNToieWl5YW4uYmFpZHUuY29tIjtzOjg6IkJhaWR1IEFJIjtzOjEyOiJhaS5iYWlkdS5jb20iO3M6ODoiQmFpZHUgQUkiO3M6MTE6ImNoYXRncHQuY29tIjtzOjc6IkNoYXRHUFQiO3M6MTU6ImNoYXQub3BlbmFpLmNvbSI7czo3OiJDaGF0R1BUIjtzOjE1OiJsYWJzLm9wZW5haS5jb20iO3M6NzoiQ2hhdEdQVCI7czo5OiJjbGF1ZGUuYWkiO3M6NjoiQ2xhdWRlIjtzOjIxOiJjb3BpbG90Lm1pY3Jvc29mdC5jb20iO3M6NzoiQ29waWxvdCI7czoxMDoiY2hhdGdsbS5jbiI7czo3OiJDaGF0R0xNIjtzOjE3OiJjaGF0LmRlZXBzZWVrLmNvbSI7czo4OiJEZWVwc2VlayI7czoxNzoiZ2VtaW5pLmdvb2dsZS5jb20iO3M6NjoiR2VtaW5pIjtzOjE1OiJiYXJkLmdvb2dsZS5jb20iO3M6NjoiR2VtaW5pIjtzOjg6Imdyb2suY29tIjtzOjQ6Ikdyb2siO3M6NzoiaWFzay5haSI7czo0OiJpQXNrIjtzOjE1OiJjaGF0Lm1pc3RyYWwuYWkiO3M6NzoiTGUgQ2hhdCI7czo3OiJtZXRhLmFpIjtzOjc6Ik1ldGEgQUkiO3M6MTM6InBlcnBsZXhpdHkuYWkiO3M6MTA6IlBlcnBsZXhpdHkiO3M6NzoieW91LmNvbSI7czozOiJZb3UiO30=',0),('analytics_user_defaultReport','1',0),('Feedback.nextFeedbackReminder.analytics_user','2026-05-10',0),('geoip2.autosetup','1',0),('geoip2.loc_db_url','https://download.db-ip.com/free/dbip-city-lite-2025-11.mmdb.gz',0),('geoip2.updater_last_run_time','1762732800',0),('geoip2.updater_period','month',0),('install_mail_sent','1',0),('install_version','5.5.1',0),('lastTrackerCronRun','1765315634',0),('MatomoUpdateHistory','5.5.1,',0),('MobileMessaging_DelegatedManagement','false',0),('piwikUrl','https://analytics.zoo/',1),('PrivacyManager.ipAnonymizerEnabled','1',0),('SitesManager_DefaultTimezone','America/Los_Angeles',0),('SocialDefinitions','YToyMTA6e3M6OToiYmFkb28uY29tIjtzOjU6IkJhZG9vIjtzOjg6ImJlYm8uY29tIjtzOjQ6IkJlYm8iO3M6MTI6ImJpbGliaWxpLmNvbSI7czo4OiJiaWxpYmlsaSI7czoxNToiYmxhY2twbGFuZXQuY29tIjtzOjExOiJCbGFja1BsYW5ldCI7czo4OiJic2t5LmFwcCI7czo3OiJCbHVlc2t5IjtzOjExOiJza3lmZWVkLmFwcCI7czo3OiJCbHVlc2t5IjtzOjExOiJidXp6bmV0LmNvbSI7czo3OiJCdXp6bmV0IjtzOjE0OiJjbGFzc21hdGVzLmNvbSI7czoxNDoiQ2xhc3NtYXRlcy5jb20iO3M6MTg6Imdsb2JhbC5jeXdvcmxkLmNvbSI7czo3OiJDeXdvcmxkIjtzOjEwOiJkb3V5aW4uY29tIjtzOjY6IkRvdXlpbiI7czo5OiJkb3V5dS5jb20iO3M6NToiRG91eXUiO3M6MTQ6ImdhaWFvbmxpbmUuY29tIjtzOjExOiJHYWlhIE9ubGluZSI7czo4OiJnZW5pLmNvbSI7czo4OiJHZW5pLmNvbSI7czoxMDoiZ2l0aHViLmNvbSI7czo2OiJHaXRIdWIiO3M6MTU6InBsdXMuZ29vZ2xlLmNvbSI7czo5OiJHb29nbGUlMkIiO3M6MTQ6InVybC5nb29nbGUuY29tIjtzOjk6Ikdvb2dsZSUyQiI7czoyODoiY29tLmdvb2dsZS5hbmRyb2lkLmFwcHMucGx1cyI7czo5OiJHb29nbGUlMkIiO3M6MTA6ImRvdWJhbi5jb20iO3M6NjoiRG91YmFuIjtzOjEyOiJkcmliYmJsZS5jb20iO3M6ODoiRHJpYmJibGUiO3M6MTI6ImZhY2Vib29rLmNvbSI7czo4OiJGYWNlYm9vayI7czo1OiJmYi5tZSI7czo4OiJGYWNlYm9vayI7czoxNDoibS5mYWNlYm9vay5jb20iO3M6ODoiRmFjZWJvb2siO3M6MTQ6ImwuZmFjZWJvb2suY29tIjtzOjg6IkZhY2Vib29rIjtzOjExOiJmZXRsaWZlLmNvbSI7czo3OiJGZXRsaWZlIjtzOjEwOiJmbGlja3IuY29tIjtzOjY6IkZsaWNrciI7czoxMjoiZmxpeHN0ZXIuY29tIjtzOjg6IkZsaXhzdGVyIjtzOjExOiJmb3RvbG9nLmNvbSI7czo3OiJGb3RvbG9nIjtzOjE0OiJmb3Vyc3F1YXJlLmNvbSI7czoxMDoiRm91cnNxdWFyZSI7czoxOToiZnJpZW5kc3JldW5pdGVkLmNvbSI7czoxNjoiRnJpZW5kcyBSZXVuaXRlZCI7czoxNDoiZnJpZW5kc3Rlci5jb20iO3M6MTA6IkZyaWVuZHN0ZXIiO3M6NzoiZ3JlZS5qcCI7czo0OiJncmVlIjtzOjk6ImhhYmJvLmNvbSI7czo1OiJIYWJvbyI7czoyMDoibmV3cy55Y29tYmluYXRvci5jb20iO3M6MTE6IkhhY2tlciBOZXdzIjtzOjc6ImhpNS5jb20iO3M6MzoiaGk1IjtzOjg6Imh1eWEuY29tIjtzOjQ6Ikh1eWEiO3M6ODoiaHl2ZXMubmwiO3M6NToiSHl2ZXMiO3M6OToiaWRlbnRpLmNhIjtzOjk6ImlkZW50aS5jYSI7czoxMzoiaW5zdGFncmFtLmNvbSI7czo5OiJJbnN0YWdyYW0iO3M6MTU6ImwuaW5zdGFncmFtLmNvbSI7czo5OiJJbnN0YWdyYW0iO3M6MTA6ImxhbmctOC5jb20iO3M6NjoibGFuZy04IjtzOjc6Imxhc3QuZm0iO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0ucnUiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uZGUiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uZXMiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uZnIiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uaXQiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uanAiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0ucGwiO3M6NzoiTGFzdC5mbSI7czoxMzoibGFzdGZtLmNvbS5iciI7czo3OiJMYXN0LmZtIjtzOjk6Imxhc3RmbS5zZSI7czo3OiJMYXN0LmZtIjtzOjEzOiJsYXN0Zm0uY29tLnRyIjtzOjc6Ikxhc3QuZm0iO3M6MTI6ImxpbmtlZGluLmNvbSI7czo4OiJMaW5rZWRJbiI7czo3OiJsbmtkLmluIjtzOjg6IkxpbmtlZEluIjtzOjE2OiJsaW5rZWRpbi5hbmRyb2lkIjtzOjg6IkxpbmtlZEluIjtzOjE0OiJsaXZlam91cm5hbC5ydSI7czoxMToiTGl2ZUpvdXJuYWwiO3M6MTU6ImxpdmVqb3VybmFsLmNvbSI7czoxMToiTGl2ZUpvdXJuYWwiO3M6MTU6Im1hc3RvZG9uLnNvY2lhbCI7czo4OiJNYXN0b2RvbiI7czoxNDoibWFzdG9kb24uY2xvdWQiO3M6ODoiTWFzdG9kb24iO3M6MTk6Im1hc3RvZG9uLnRlY2hub2xvZ3kiO3M6ODoiTWFzdG9kb24iO3M6MTI6Im1hc3RvZG9uLnh5eiI7czo4OiJNYXN0b2RvbiI7czoxMToibWFzdG9kb24uYXQiO3M6ODoiTWFzdG9kb24iO3M6MTI6Im1hc3RvZG9uLmFydCI7czo4OiJNYXN0b2RvbiI7czo4OiJtYW1vdC5mciI7czo4OiJNYXN0b2RvbiI7czo5OiJwYXdvby5uZXQiO3M6ODoiTWFzdG9kb24iO3M6ODoibXN0ZG4uaW8iO3M6ODoiTWFzdG9kb24iO3M6ODoibXN0ZG4uanAiO3M6ODoiTWFzdG9kb24iO3M6MTI6ImZyaWVuZHMubmljbyI7czo4OiJNYXN0b2RvbiI7czoxOToicm8tbWFzdG9kb24ucHV5by5qcCI7czo4OiJNYXN0b2RvbiI7czo4OiJxdWV5Lm9yZyI7czo4OiJNYXN0b2RvbiI7czoxMjoiYm90c2luLnNwYWNlIjtzOjg6Ik1hc3RvZG9uIjtzOjE2OiJzb2NpYWwudGNobmNzLmRlIjtzOjg6Ik1hc3RvZG9uIjtzOjc6ImtuemsubWUiO3M6ODoiTWFzdG9kb24iO3M6MTM6Im1hc3RvZG9udC5jYXQiO3M6ODoiTWFzdG9kb24iO3M6MTg6ImJpdGNvaW5oYWNrZXJzLm9yZyI7czo4OiJNYXN0b2RvbiI7czoxMzoiZm9zc3RvZG9uLm9yZyI7czo4OiJNYXN0b2RvbiI7czoxMjoiY2hhb3Muc29jaWFsIjtzOjg6Ik1hc3RvZG9uIjtzOjExOiJjeWJyZS5zcGFjZSI7czo4OiJNYXN0b2RvbiI7czoxMDoidmlzLnNvY2lhbCI7czo4OiJNYXN0b2RvbiI7czoxMToidHlwby5zb2NpYWwiO3M6ODoiTWFzdG9kb24iO3M6MTY6ImZyb250LWVuZC5zb2NpYWwiO3M6ODoiTWFzdG9kb24iO3M6MTI6ImhhY2h5ZGVybS5pbyI7czo4OiJNYXN0b2RvbiI7czoxNToibWFzdG9kb24ub25saW5lIjtzOjg6Ik1hc3RvZG9uIjtzOjEzOiJuZXdzaWUuc29jaWFsIjtzOjg6Ik1hc3RvZG9uIjtzOjEyOiJtc3Rkbi5zb2NpYWwiO3M6ODoiTWFzdG9kb24iO3M6MTU6ImluZGlld2ViLnNvY2lhbCI7czo4OiJNYXN0b2RvbiI7czoxMToic2ZiYS5zb2NpYWwiO3M6ODoiTWFzdG9kb24iO3M6NjoibWFzLnRvIjtzOjg6Ik1hc3RvZG9uIjtzOjExOiJtc3Rkbi5wYXJ0eSI7czo4OiJNYXN0b2RvbiI7czo0OiJjLmltIjtzOjg6Ik1hc3RvZG9uIjtzOjE0OiJtYXN0b2RvbmFwcC51ayI7czo4OiJNYXN0b2RvbiI7czoxNjoidW5pdmVyc2VvZG9uLmNvbSI7czo4OiJNYXN0b2RvbiI7czoxODoic29jaWFsLnZpdmFsZGkubmV0IjtzOjg6Ik1hc3RvZG9uIjtzOjExOiJvaGFpLnNvY2lhbCI7czo4OiJNYXN0b2RvbiI7czoxNDoidG9vdC5jb21tdW5pdHkiO3M6ODoiTWFzdG9kb24iO3M6ODoibWFzdG8uYWkiO3M6ODoiTWFzdG9kb24iO3M6MTM6Im1hc3RvZG9uLnNjb3QiO3M6ODoiTWFzdG9kb24iO3M6MTQ6Im1hc3RvZG9uLndvcmxkIjtzOjg6Ik1hc3RvZG9uIjtzOjExOiJtYXN0b2Rvbi5ueiI7czo4OiJNYXN0b2RvbiI7czoxNToiZ3JhcGhpY3Muc29jaWFsIjtzOjg6Ik1hc3RvZG9uIjtzOjI0OiJvcmcuam9pbm1hc3RvZG9uLmFuZHJvaWQiO3M6ODoiTWFzdG9kb24iO3M6MTI6Im1hc3RvZG9uLmV1cyI7czo4OiJNYXN0b2RvbiI7czoxODoibWFzdG9kb24uamFsZ2kuZXVzIjtzOjg6Ik1hc3RvZG9uIjtzOjc6InRrbS5ldXMiO3M6ODoiTWFzdG9kb24iO3M6MTA6Im1laW52ei5uZXQiO3M6NjoiTWVpblZaIjtzOjEyOiJtaXNzZXZhbi5jb20iO3M6ODoiTWlzc0V2YW4iO3M6NzoibWl4aS5qcCI7czo0OiJNaXhpIjtzOjEwOiJtb2lrcnVnLnJ1IjtzOjEwOiJNb2lLcnVnLnJ1IjtzOjEyOiJtdWx0aXBseS5jb20iO3M6ODoiTXVsdGlwbHkiO3M6MTA6Im15Lm1haWwucnUiO3M6MTA6Im15Lm1haWwucnUiO3M6MTQ6Im15aGVyaXRhZ2UuY29tIjtzOjEwOiJNeUhlcml0YWdlIjtzOjk6Im15bGlmZS5ydSI7czo2OiJNeUxpZmUiO3M6MTE6Im15c3BhY2UuY29tIjtzOjc6Ik15c3BhY2UiO3M6MTQ6Im15eWVhcmJvb2suY29tIjtzOjEwOiJteVllYXJib29rIjtzOjU6Im5rLnBsIjtzOjE0OiJOYXN6YS1rbGFzYS5wbCI7czoxMDoibmV0bG9nLmNvbSI7czo2OiJOZXRsb2ciO3M6MTI6Im5pY292aWRlby5qcCI7czo4OiJOaWNvbmljbyI7czoxNjoib2Rub2tsYXNzbmlraS5ydSI7czoxMzoiT2Rub2tsYXNzbmlraSI7czo5OiJvcmt1dC5jb20iO3M6NToiT3JrdXQiO3M6MTI6InF6b25lLnFxLmNvbSI7czo1OiJPem9uZSI7czoxMToicGVlcGV0aC5jb20iO3M6NzoiUGVlcGV0aCI7czoxMzoicGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5jYSI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5jaCI7czo5OiJQaW50ZXJlc3QiO3M6MTU6InBpbnRlcmVzdC5jby51ayI7czo5OiJQaW50ZXJlc3QiO3M6MTY6InBpbnRlcmVzdC5jb20uYXUiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuZGUiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuZGsiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuZXMiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuZnIiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuaWUiO3M6OToiUGludGVyZXN0IjtzOjE0OiJwaW50ZXJlc3QuaW5mbyI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5qcCI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5ueiI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5wdCI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5zZSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6ImF0LnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJjaC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoiY2wucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6ImNvLnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJkay5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoiZXMucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6Imh1LnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJpZC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoiaWUucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6ImluLnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJpdC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoia3IucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6Im14LnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJubC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoibnoucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6InBoLnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJwdC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoicnUucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6InNlLnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE1OiJwaXhlbGZlZC5zb2NpYWwiO3M6ODoiUGl4ZWxmZWQiO3M6MTE6InBpeGVsZmVkLmRlIjtzOjg6IlBpeGVsZmVkIjtzOjk6InB4bG1vLmNvbSI7czo4OiJQaXhlbGZlZCI7czoxMjoibWV0YXBpeGwuY29tIjtzOjg6IlBpeGVsZmVkIjtzOjE0OiJwaXgudG9vdC53YWxlcyI7czo4OiJQaXhlbGZlZCI7czoxMjoicGl4ZWxmZWQudW5vIjtzOjg6IlBpeGVsZmVkIjtzOjk6InBpeGV5Lm9yZyI7czo4OiJQaXhlbGZlZCI7czo5OiJwbGF4by5jb20iO3M6NToiUGxheG8iO3M6MTA6InJlZGRpdC5jb20iO3M6NjoicmVkZGl0IjtzOjEzOiJucC5yZWRkaXQuY29tIjtzOjY6InJlZGRpdCI7czoxNDoicGF5LnJlZGRpdC5jb20iO3M6NjoicmVkZGl0IjtzOjIwOiJjb20ucmVkZGl0LmZyb250cGFnZSI7czo2OiJyZWRkaXQiO3M6MTA6InJlbnJlbi5jb20iO3M6NjoiUmVucmVuIjtzOjExOiJza3lyb2NrLmNvbSI7czo3OiJTa3lyb2NrIjtzOjEyOiJzbmFwY2hhdC5jb20iO3M6ODoiU25hcGNoYXQiO3M6MTA6InNvbmljby5jb20iO3M6MTA6IlNvbmljby5jb20iO3M6MTQ6InNvdW5kY2xvdWQuY29tIjtzOjEwOiJTb3VuZENsb3VkIjtzOjc6ImdhdGUuc2MiO3M6MTA6IlNvdW5kQ2xvdWQiO3M6MTc6InN0YWNrb3ZlcmZsb3cuY29tIjtzOjEzOiJTdGFja092ZXJmbG93IjtzOjExOiJzdHVkaXZ6Lm5ldCI7czo3OiJTdHVkaVZaIjtzOjE2OiJsb2dpbi50YWdnZWQuY29tIjtzOjY6IlRhZ2dlZCI7czoxMToidGFyaW5nYS5uZXQiO3M6ODoiVGFyaW5nYSEiO3M6MTY6IndlYi50ZWxlZ3JhbS5vcmciO3M6ODoiVGVsZWdyYW0iO3M6MjI6Im9yZy50ZWxlZ3JhbS5tZXNzZW5nZXIiO3M6ODoiVGVsZWdyYW0iO3M6MTE6InRocmVhZHMubmV0IjtzOjc6IlRocmVhZHMiO3M6MTM6ImwudGhyZWFkcy5uZXQiO3M6NzoiVGhyZWFkcyI7czoxMToidGhyZWFkcy5jb20iO3M6NzoiVGhyZWFkcyI7czoxMzoibC50aHJlYWRzLmNvbSI7czo3OiJUaHJlYWRzIjtzOjEwOiJ0aWt0b2suY29tIjtzOjY6IlRpa1RvayI7czoxMDoidHVlbnRpLmNvbSI7czo2OiJUdWVudGkiO3M6MTA6InR1bWJsci5jb20iO3M6NjoidHVtYmxyIjtzOjExOiJ0LnVtYmxyLmNvbSI7czo2OiJ0dW1ibHIiO3M6MTQ6InR3aXRjYXN0aW5nLnR2IjtzOjg6IlR3aXRjYXN0IjtzOjExOiJ0d2l0dGVyLmNvbSI7czo3OiJUd2l0dGVyIjtzOjQ6InQuY28iO3M6NzoiVHdpdHRlciI7czo1OiJ4LmNvbSI7czo3OiJUd2l0dGVyIjtzOjE1OiJzb3VyY2Vmb3JnZS5uZXQiO3M6MTE6IlNvdXJjZWZvcmdlIjtzOjE1OiJzdHVtYmxldXBvbi5jb20iO3M6MTE6IlN0dW1ibGVVcG9uIjtzOjY6InZrLmNvbSI7czo5OiJWa29udGFrdGUiO3M6MTI6InZrb250YWt0ZS5ydSI7czo5OiJWa29udGFrdGUiO3M6MTE6InlvdXR1YmUuY29tIjtzOjc6IllvdVR1YmUiO3M6ODoieW91dHUuYmUiO3M6NzoiWW91VHViZSI7czo4OiJ2MmV4LmNvbSI7czo0OiJWMkVYIjtzOjEwOiJ2aWFkZW8uY29tIjtzOjY6IlZpYWRlbyI7czo5OiJ2aW1lby5jb20iO3M6NToiVmltZW8iO3M6MTU6InZrcnVndWRydXplaS5ydSI7czoxNToidmtydWd1ZHJ1emVpLnJ1IjtzOjg6IndheW4uY29tIjtzOjQ6IldBWU4iO3M6OToid2VpYm8uY29tIjtzOjU6IldlaWJvIjtzOjQ6InQuY24iO3M6NToiV2VpYm8iO3M6MTI6IndlZXdvcmxkLmNvbSI7czo4OiJXZWVXb3JsZCI7czoxNDoibG9naW4ubGl2ZS5jb20iO3M6MTk6IldpbmRvd3MgTGl2ZSBTcGFjZXMiO3M6MTM6IndvcmtwbGFjZS5jb20iO3M6OToiV29ya3BsYWNlIjtzOjE1OiJsLndvcmtwbGFjZS5jb20iO3M6OToiV29ya3BsYWNlIjtzOjE2OiJsbS53b3JrcGxhY2UuY29tIjtzOjk6IldvcmtwbGFjZSI7czo5OiJ4YW5nYS5jb20iO3M6NToiWGFuZ2EiO3M6ODoieGluZy5jb20iO3M6NDoiWElORyI7fQ==',0),('TaskScheduler.timetable','a:29:{s:60:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.invalidateOutdatedArchives\";i:1765324816;s:59:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.deleteOldFingerprintSalts\";i:1765324816;s:55:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeOutdatedArchives\";i:1765324816;s:55:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeOrphanedArchives\";i:1765756816;s:47:\"Piwik\\Plugins\\Login\\Tasks.cleanupBruteForceLogs\";i:1765324816;s:63:\"Piwik\\Plugins\\TwoFactorAuth\\Tasks.cleanupTwoFaCodesUsedRecently\";i:1765324816;s:53:\"Piwik\\Plugins\\UsersManager\\Tasks.cleanupExpiredTokens\";i:1765324816;s:63:\"Piwik\\Plugins\\UsersManager\\Tasks.setUserDefaultReportPreference\";i:1765324816;s:54:\"Piwik\\Plugins\\UsersManager\\Tasks.cleanUpExpiredInvites\";i:1765324816;s:85:\"Piwik\\Plugins\\UsersManager\\TokenNotifications\\TokenNotifierTask.dispatchNotifications\";i:1765324816;s:83:\"Piwik\\Plugins\\UsersManager\\UserNotifications\\UserNotifierTask.dispatchNotifications\";i:1767225616;s:49:\"Piwik\\Plugins\\CustomJsTracker\\Tasks.updateTracker\";i:1765317616;s:58:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeInvalidatedArchives\";i:1765324816;s:65:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeBrokenArchivesCurrentMonth\";i:1765324816;s:67:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeInvalidationsForDeletedSites\";i:1765324816;s:51:\"Piwik\\Plugins\\PrivacyManager\\Tasks.deleteReportData\";i:1765324816;s:48:\"Piwik\\Plugins\\PrivacyManager\\Tasks.deleteLogData\";i:1765317616;s:52:\"Piwik\\Plugins\\PrivacyManager\\Tasks.anonymizePastData\";i:1765317616;s:63:\"Piwik\\Plugins\\PrivacyManager\\Tasks.deleteLogDataForDeletedSites\";i:1765756816;s:54:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.optimizeArchiveTable\";i:1767225616;s:57:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.cleanupTrackingFailures\";i:1765324816;s:56:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.notifyTrackingFailures\";i:1765756816;s:65:\"Piwik\\Plugins\\CoreUpdater\\Tasks.sendNotificationIfUpdateAvailable\";i:1765324816;s:62:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.checkSiteHasTrackedVisits_16\";i:1764986400;s:62:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.checkSiteHasTrackedVisits_17\";i:1765677600;s:62:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.checkSiteHasTrackedVisits_18\";i:1765591200;s:62:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.checkSiteHasTrackedVisits_19\";i:1765591200;s:62:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.checkSiteHasTrackedVisits_20\";i:1765591200;s:62:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.checkSiteHasTrackedVisits_21\";i:1765591200;}',0),('TokenNotifier.lastRunTime','1765238400',0),('TransactionLevel.testOption','1',0),('UpdateCheck_LastCheckFailed','1',0),('UpdateCheck_LastTimeChecked','',1),('useridsalt','XfpJA2xDZNvCU5dCdMB5GzPXRZz_leRuan520CUl',1),('UserNotifier.lastRunTime','1765238400',0),('version_Actions','5.5.1',1),('version_Annotations','5.5.1',1),('version_API','5.5.1',1),('version_BulkTracking','5.5.1',1),('version_Contents','5.5.1',1),('version_core','5.5.1',1),('version_CoreAdminHome','5.5.1',1),('version_CoreConsole','5.5.1',1),('version_CoreHome','5.5.1',1),('version_CorePluginsAdmin','5.5.1',1),('version_CoreUpdater','5.5.1',1),('version_CoreVisualizations','5.5.1',1),('version_CoreVue','5.5.1',1),('version_CustomDimensions','5.5.1',1),('version_CustomJsTracker','5.5.1',1),('version_Dashboard','5.5.1',1),('version_DevicePlugins','5.5.1',1),('version_DevicesDetection','5.5.1',1),('version_Diagnostics','5.5.1',1),('version_Ecommerce','5.5.1',1),('version_Events','5.5.1',1),('version_FeatureFlags','5.5.1',1),('version_Feedback','5.5.1',1),('version_GeoIp2','5.5.1',1),('version_Goals','5.5.1',1),('version_Heartbeat','5.5.1',1),('version_ImageGraph','5.5.1',1),('version_Insights','5.5.1',1),('version_Installation','5.5.1',1),('version_Intl','5.5.1',1),('version_IntranetMeasurable','5.5.1',1),('version_JsTrackerInstallCheck','5.5.1',1),('version_LanguagesManager','5.5.1',1),('version_Live','5.5.1',1),('version_log_conversion.pageviews_before','SMALLINT UNSIGNED DEFAULT NULL',1),('version_log_conversion.revenue','float default NULL',1),('version_log_link_visit_action.idaction_content_interaction','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_content_name','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_content_piece','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_content_target','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_event_action','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_event_category','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_name','INTEGER(10) UNSIGNED',1),('version_log_link_visit_action.idaction_product_cat','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_cat2','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_cat3','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_cat4','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_cat5','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_name','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_sku','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_url','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idpageview','CHAR(6) NULL DEFAULT NULL',1),('version_log_link_visit_action.product_price','DOUBLE NULL',1),('version_log_link_visit_action.search_cat','VARCHAR(200) NULL',1),('version_log_link_visit_action.search_count','INTEGER(10) UNSIGNED NULL',1),('version_log_link_visit_action.server_time','DATETIME NOT NULL',1),('version_log_link_visit_action.time_dom_completion','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_dom_processing','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_network','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_on_load','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_server','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_spent_ref_action','INTEGER(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_transfer','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_visit.config_browser_engine','VARCHAR(10) NULL',1),('version_log_visit.config_browser_name','VARCHAR(40) NULL1',1),('version_log_visit.config_browser_version','VARCHAR(20) NULL',1),('version_log_visit.config_client_type','TINYINT( 1 ) NULL DEFAULT NULL1',1),('version_log_visit.config_cookie','TINYINT(1) NULL',1),('version_log_visit.config_device_brand','VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL1',1),('version_log_visit.config_device_model','VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL1',1),('version_log_visit.config_device_type','TINYINT( 100 ) NULL DEFAULT NULL1',1),('version_log_visit.config_flash','TINYINT(1) NULL',1),('version_log_visit.config_java','TINYINT(1) NULL',1),('version_log_visit.config_os','CHAR(3) NULL',1),('version_log_visit.config_os_version','VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL',1),('version_log_visit.config_pdf','TINYINT(1) NULL',1),('version_log_visit.config_quicktime','TINYINT(1) NULL',1),('version_log_visit.config_realplayer','TINYINT(1) NULL',1),('version_log_visit.config_resolution','VARCHAR(18) NULL',1),('version_log_visit.config_silverlight','TINYINT(1) NULL',1),('version_log_visit.config_windowsmedia','TINYINT(1) NULL',1),('version_log_visit.location_browser_lang','VARCHAR(20) NULL',1),('version_log_visit.location_city','varchar(255) DEFAULT NULL1',1),('version_log_visit.location_country','CHAR(3) NULL1',1),('version_log_visit.location_latitude','decimal(9, 6) DEFAULT NULL1',1),('version_log_visit.location_longitude','decimal(9, 6) DEFAULT NULL1',1),('version_log_visit.location_region','char(3) DEFAULT NULL1',1),('version_log_visit.profilable','TINYINT(1) NULL',1),('version_log_visit.referer_keyword','VARCHAR(255) NULL1',1),('version_log_visit.referer_name','VARCHAR(255) NULL1',1),('version_log_visit.referer_type','TINYINT(1) UNSIGNED NULL1',1),('version_log_visit.referer_url','VARCHAR(1500) NULL',1),('version_log_visit.user_id','VARCHAR(200) NULL',1),('version_log_visit.visit_entry_idaction_name','INTEGER(10) UNSIGNED NULL',1),('version_log_visit.visit_entry_idaction_url','INTEGER(11) UNSIGNED NULL  DEFAULT NULL',1),('version_log_visit.visit_exit_idaction_name','INTEGER(10) UNSIGNED NULL',1),('version_log_visit.visit_exit_idaction_url','INTEGER(10) UNSIGNED NULL DEFAULT 0',1),('version_log_visit.visit_first_action_time','DATETIME NOT NULL',1),('version_log_visit.visit_goal_buyer','TINYINT(1) NULL',1),('version_log_visit.visit_goal_converted','TINYINT(1) NULL',1),('version_log_visit.visit_total_actions','INT(11) UNSIGNED NULL',1),('version_log_visit.visit_total_events','INT(11) UNSIGNED NULL',1),('version_log_visit.visit_total_interactions','MEDIUMINT UNSIGNED DEFAULT 0',1),('version_log_visit.visit_total_searches','SMALLINT(5) UNSIGNED NULL',1),('version_log_visit.visit_total_time','INT(11) UNSIGNED NOT NULL',1),('version_log_visit.visitor_count_visits','INT(11) UNSIGNED NOT NULL DEFAULT 01',1),('version_log_visit.visitor_localtime','TIME NULL',1),('version_log_visit.visitor_returning','TINYINT(1) NULL1',1),('version_log_visit.visitor_seconds_since_first','INT(11) UNSIGNED NULL1',1),('version_log_visit.visitor_seconds_since_last','INT(11) UNSIGNED NULL',1),('version_log_visit.visitor_seconds_since_order','INT(11) UNSIGNED NULL1',1),('version_Login','5.5.1',1),('version_Marketplace','5.5.1',1),('version_MobileMessaging','5.5.1',1),('version_Monolog','5.5.1',1),('version_Morpheus','5.5.1',1),('version_MultiSites','5.5.1',1),('version_Overlay','5.5.1',1),('version_PagePerformance','5.5.1',1),('version_PrivacyManager','5.5.1',1),('version_ProfessionalServices','5.5.1',1),('version_Proxy','5.5.1',1),('version_Referrers','5.5.1',1),('version_Resolution','5.5.1',1),('version_RssWidget','1.0',1),('version_ScheduledReports','5.5.1',1),('version_SegmentEditor','5.5.1',1),('version_SEO','5.5.1',1),('version_SitesManager','5.5.1',1),('version_Tour','5.5.1',1),('version_Transitions','5.5.1',1),('version_TwoFactorAuth','5.5.1',1),('version_UserCountry','5.5.1',1),('version_UserCountryMap','5.5.1',1),('version_UserId','5.5.1',1),('version_UserLanguage','5.5.1',1),('version_UsersManager','5.5.1',1),('version_VisitFrequency','5.5.1',1),('version_VisitorInterest','5.5.1',1),('version_VisitsSummary','5.5.1',1),('version_VisitTime','5.5.1',1),('version_WebsiteMeasurable','5.5.1',1),('version_Widgetize','5.5.1',1);
/*!40000 ALTER TABLE `matomo_option` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_plugin_setting`
--

DROP TABLE IF EXISTS `matomo_plugin_setting`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_plugin_setting` (
  `plugin_name` varchar(60) NOT NULL,
  `setting_name` varchar(255) NOT NULL,
  `setting_value` longtext NOT NULL,
  `json_encoded` tinyint unsigned NOT NULL DEFAULT '0',
  `user_login` varchar(100) NOT NULL DEFAULT '',
  `idplugin_setting` bigint unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`idplugin_setting`),
  KEY `plugin_name` (`plugin_name`,`user_login`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_plugin_setting`
--

LOCK TABLES `matomo_plugin_setting` WRITE;
/*!40000 ALTER TABLE `matomo_plugin_setting` DISABLE KEYS */;
INSERT INTO `matomo_plugin_setting` VALUES ('Tour','view_visits_log_completed','1',0,'analytics_user',1);
/*!40000 ALTER TABLE `matomo_plugin_setting` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_privacy_logdata_anonymizations`
--

DROP TABLE IF EXISTS `matomo_privacy_logdata_anonymizations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_privacy_logdata_anonymizations` (
  `idlogdata_anonymization` bigint unsigned NOT NULL AUTO_INCREMENT,
  `idsites` text,
  `date_start` datetime NOT NULL,
  `date_end` datetime NOT NULL,
  `anonymize_ip` tinyint unsigned NOT NULL DEFAULT '0',
  `anonymize_location` tinyint unsigned NOT NULL DEFAULT '0',
  `anonymize_userid` tinyint unsigned NOT NULL DEFAULT '0',
  `unset_visit_columns` text NOT NULL,
  `unset_link_visit_action_columns` text NOT NULL,
  `output` mediumtext,
  `scheduled_date` datetime DEFAULT NULL,
  `job_start_date` datetime DEFAULT NULL,
  `job_finish_date` datetime DEFAULT NULL,
  `requester` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`idlogdata_anonymization`),
  KEY `job_start_date` (`job_start_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_privacy_logdata_anonymizations`
--

LOCK TABLES `matomo_privacy_logdata_anonymizations` WRITE;
/*!40000 ALTER TABLE `matomo_privacy_logdata_anonymizations` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_privacy_logdata_anonymizations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_report`
--

DROP TABLE IF EXISTS `matomo_report`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_report` (
  `idreport` int NOT NULL AUTO_INCREMENT,
  `idsite` int NOT NULL,
  `login` varchar(100) NOT NULL,
  `description` varchar(255) NOT NULL,
  `idsegment` int DEFAULT NULL,
  `period` varchar(10) NOT NULL,
  `hour` tinyint NOT NULL DEFAULT '0',
  `type` varchar(10) NOT NULL,
  `format` varchar(10) NOT NULL,
  `reports` text NOT NULL,
  `parameters` text,
  `ts_created` timestamp NULL DEFAULT NULL,
  `ts_last_sent` timestamp NULL DEFAULT NULL,
  `deleted` tinyint NOT NULL DEFAULT '0',
  `evolution_graph_within_period` tinyint NOT NULL DEFAULT '0',
  `evolution_graph_period_n` int NOT NULL,
  `period_param` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`idreport`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_report`
--

LOCK TABLES `matomo_report` WRITE;
/*!40000 ALTER TABLE `matomo_report` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_report` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_report_subscriptions`
--

DROP TABLE IF EXISTS `matomo_report_subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_report_subscriptions` (
  `idreport` int NOT NULL,
  `token` varchar(100) DEFAULT NULL,
  `email` varchar(100) NOT NULL,
  `ts_subscribed` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `ts_unsubscribed` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`idreport`,`email`),
  UNIQUE KEY `unique_token` (`token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_report_subscriptions`
--

LOCK TABLES `matomo_report_subscriptions` WRITE;
/*!40000 ALTER TABLE `matomo_report_subscriptions` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_report_subscriptions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_segment`
--

DROP TABLE IF EXISTS `matomo_segment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_segment` (
  `idsegment` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `definition` text NOT NULL,
  `hash` char(32) DEFAULT NULL,
  `login` varchar(100) NOT NULL,
  `enable_all_users` tinyint NOT NULL DEFAULT '0',
  `enable_only_idsite` int DEFAULT NULL,
  `auto_archive` tinyint NOT NULL DEFAULT '0',
  `ts_created` timestamp NULL DEFAULT NULL,
  `ts_last_edit` timestamp NULL DEFAULT NULL,
  `deleted` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`idsegment`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_segment`
--

LOCK TABLES `matomo_segment` WRITE;
/*!40000 ALTER TABLE `matomo_segment` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_segment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_sequence`
--

DROP TABLE IF EXISTS `matomo_sequence`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_sequence` (
  `name` varchar(120) NOT NULL,
  `value` bigint unsigned NOT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_sequence`
--

LOCK TABLES `matomo_sequence` WRITE;
/*!40000 ALTER TABLE `matomo_sequence` DISABLE KEYS */;
INSERT INTO `matomo_sequence` VALUES ('matomo_archive_numeric_2025_01',0),('matomo_archive_numeric_2025_11',0),('matomo_archive_numeric_2025_12',0),('matomo_archive_numeric_2026_01',0),('matomo_archive_numeric_2026_02',0);
/*!40000 ALTER TABLE `matomo_sequence` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_session`
--

DROP TABLE IF EXISTS `matomo_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_session` (
  `id` varchar(191) NOT NULL,
  `modified` int DEFAULT NULL,
  `lifetime` int DEFAULT NULL,
  `data` mediumtext,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_session`
--

LOCK TABLES `matomo_session` WRITE;
/*!40000 ALTER TABLE `matomo_session` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_session` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_site`
--

DROP TABLE IF EXISTS `matomo_site`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_site` (
  `idsite` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(90) NOT NULL,
  `main_url` varchar(255) NOT NULL,
  `ts_created` timestamp NULL DEFAULT NULL,
  `ecommerce` tinyint DEFAULT '0',
  `sitesearch` tinyint DEFAULT '1',
  `sitesearch_keyword_parameters` text NOT NULL,
  `sitesearch_category_parameters` text NOT NULL,
  `timezone` varchar(50) NOT NULL,
  `currency` char(3) NOT NULL,
  `exclude_unknown_urls` tinyint(1) DEFAULT '0',
  `excluded_ips` text NOT NULL,
  `excluded_parameters` text NOT NULL,
  `excluded_user_agents` text NOT NULL,
  `excluded_referrers` text NOT NULL,
  `group` varchar(250) NOT NULL,
  `type` varchar(255) NOT NULL,
  `keep_url_fragment` tinyint NOT NULL DEFAULT '0',
  `creator_login` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`idsite`)
) ENGINE=InnoDB AUTO_INCREMENT=90 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_site`
--

LOCK TABLES `matomo_site` WRITE;
/*!40000 ALTER TABLE `matomo_site` DISABLE KEYS */;
INSERT INTO `matomo_site` VALUES (1,'snappymail','https://snappymail.zoo','2025-11-10 14:03:38',0,1,'','','America/Los_Angeles','USD',0,'','','','','','website',0,'anonymous'),(4,'gitea','https://gitea.zoo','2025-11-26 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(5,'auth','https://auth.zoo','2025-11-26 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(6,'classifieds','https://classifieds.zoo','2025-11-26 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(7,'excalidraw','https://excalidraw.zoo','2025-11-26 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(8,'focalboard','https://focalboard.zoo','2025-11-26 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(10,'miniflux','https://miniflux.zoo','2025-11-27 03:35:38',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(11,'northwind','https://northwind.zoo','2025-11-26 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(15,'wiki','https://wiki.zoo','2025-11-26 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(16,'onestopshop','https://onestopshop.zoo','2025-12-01 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(17,'postmill','https://postmill.zoo','2025-12-09 21:14:42',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(18,'example','https://example.zoo','2025-12-08 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(19,'home','https://home.zoo','2025-12-08 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(20,'misc','https://misc.zoo','2025-12-08 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(21,'paste','https://paste.zoo','2025-12-08 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(22,'mattermost','https://mattermost.zoo','2026-01-27 17:25:36',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(23,'abaca','https://abaca.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(24,'alderpost','https://alderpost.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(25,'ashline-quotient','https://ashline-quotient.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(26,'aurelia-playhouse','https://aurelia-playhouse.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(27,'boxelder','https://boxelder.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(28,'brantmoor','https://brantmoor.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(29,'brindle-fig','https://brindle-fig.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(30,'cadre-workplace','https://cadre-workplace.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(31,'caldmoor-bank-login','https://caldmoor-bank-login.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(32,'caldmoorbank-online','https://caldmoorbank-online.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(33,'canvas-swatch','https://canvas-swatch.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(34,'cindergrid','https://cindergrid.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(35,'civic-revenue','https://civic-revenue.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(36,'coppermast','https://coppermast.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(37,'corvane','https://corvane.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(38,'cresthaven','https://cresthaven.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(39,'docs.gitea','https://docs.gitea.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(40,'draymere','https://draymere.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(41,'drennhill-dental','https://drennhill-dental.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(42,'farholt','https://farholt.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(43,'ferncliff','https://ferncliff.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(44,'fernlight','https://fernlight.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(45,'fernmail','https://fernmail.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(46,'fernwood-commons','https://fernwood-commons.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(47,'gadgetron-mirror','https://gadgetron-mirror.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(48,'gadgetron','https://gadgetron.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(49,'grelsby-water','https://grelsby-water.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(50,'halbeck','https://halbeck.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(51,'harrowgate-works','https://harrowgate-works.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(52,'hearthline','https://hearthline.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(53,'kelsmere','https://kelsmere.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(54,'kelverne','https://kelverne.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(55,'kestrel-peak','https://kestrel-peak.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(56,'kettleforge','https://kettleforge.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(57,'lakefront-vendor','https://lakefront-vendor.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(58,'larkfield','https://larkfield.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(59,'lumeva','https://lumeva.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(60,'marlowe-depot','https://marlowe-depot.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(61,'marlstone','https://marlstone.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(62,'marrowfield','https://marrowfield.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(63,'marrowgate','https://marrowgate.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(64,'metronome','https://metronome.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(65,'millrace','https://millrace.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(66,'nerrow-strait','https://nerrow-strait.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(67,'nimbrel','https://nimbrel.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(68,'northgate-domains','https://northgate-domains.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(69,'northmarsh','https://northmarsh.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(70,'northwind-ir','https://northwind-ir.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(71,'ollister-crane','https://ollister-crane.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(72,'orsino','https://orsino.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(73,'ostara','https://ostara.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(74,'overlane','https://overlane.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(75,'peregrine-court','https://peregrine-court.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(76,'qandara-taa','https://qandara-taa.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(77,'quennell','https://quennell.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(78,'skerrow-radio','https://skerrow-radio.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(79,'solstice','https://solstice.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(80,'status','https://status.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(81,'stavelock','https://stavelock.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(82,'tamarack-hollow','https://tamarack-hollow.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(83,'tealwave','https://tealwave.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(84,'thornbury-trust','https://thornbury-trust.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(85,'trelowen','https://trelowen.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(86,'verlan-transit','https://verlan-transit.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(87,'voltro','https://voltro.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(88,'waypost','https://waypost.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user'),(89,'zellick','https://zellick.zoo','2026-09-19 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user');
/*!40000 ALTER TABLE `matomo_site` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_site_setting`
--

DROP TABLE IF EXISTS `matomo_site_setting`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_site_setting` (
  `idsite` int unsigned NOT NULL,
  `plugin_name` varchar(60) NOT NULL,
  `setting_name` varchar(255) NOT NULL,
  `setting_value` longtext NOT NULL,
  `json_encoded` tinyint unsigned NOT NULL DEFAULT '0',
  `idsite_setting` bigint unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`idsite_setting`),
  KEY `idsite` (`idsite`,`plugin_name`)
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_site_setting`
--

LOCK TABLES `matomo_site_setting` WRITE;
/*!40000 ALTER TABLE `matomo_site_setting` DISABLE KEYS */;
INSERT INTO `matomo_site_setting` VALUES (1,'Live','disable_visitor_log','0',0,7),(1,'Live','disable_visitor_profile','0',0,8),(2,'Live','disable_visitor_log','0',0,15),(2,'Live','disable_visitor_profile','0',0,16),(4,'Live','disable_visitor_log','0',0,17),(4,'Live','disable_visitor_profile','0',0,18),(5,'Live','disable_visitor_log','0',0,19),(5,'Live','disable_visitor_profile','0',0,20),(6,'Live','disable_visitor_log','0',0,21),(6,'Live','disable_visitor_profile','0',0,22),(7,'Live','disable_visitor_log','0',0,23),(7,'Live','disable_visitor_profile','0',0,24),(8,'Live','disable_visitor_log','0',0,25),(8,'Live','disable_visitor_profile','0',0,26),(9,'Live','disable_visitor_log','0',0,27),(9,'Live','disable_visitor_profile','0',0,28),(10,'Live','disable_visitor_log','0',0,29),(10,'Live','disable_visitor_profile','0',0,30),(11,'Live','disable_visitor_log','0',0,31),(11,'Live','disable_visitor_profile','0',0,32),(12,'Live','disable_visitor_log','0',0,33),(12,'Live','disable_visitor_profile','0',0,34),(13,'Live','disable_visitor_log','0',0,35),(13,'Live','disable_visitor_profile','0',0,36),(14,'Live','disable_visitor_log','0',0,37),(14,'Live','disable_visitor_profile','0',0,38),(15,'Live','disable_visitor_log','0',0,39),(15,'Live','disable_visitor_profile','0',0,40),(17,'Live','disable_visitor_log','0',0,41),(17,'Live','disable_visitor_profile','0',0,42),(18,'Live','disable_visitor_log','0',0,43),(18,'Live','disable_visitor_profile','0',0,44),(19,'Live','disable_visitor_log','0',0,45),(19,'Live','disable_visitor_profile','0',0,46),(20,'Live','disable_visitor_log','0',0,47),(20,'Live','disable_visitor_profile','0',0,48),(21,'Live','disable_visitor_log','0',0,49),(21,'Live','disable_visitor_profile','0',0,50),(16,'CoreAdminHome','trackingCodeExistsCheck','1',0,52),(22,'Live','disable_visitor_log','0',0,53),(22,'Live','disable_visitor_profile','0',0,54);
/*!40000 ALTER TABLE `matomo_site_setting` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_site_url`
--

DROP TABLE IF EXISTS `matomo_site_url`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_site_url` (
  `idsite` int unsigned NOT NULL,
  `url` varchar(190) NOT NULL,
  PRIMARY KEY (`idsite`,`url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_site_url`
--

LOCK TABLES `matomo_site_url` WRITE;
/*!40000 ALTER TABLE `matomo_site_url` DISABLE KEYS */;
INSERT INTO `matomo_site_url` VALUES (1,'http://snappymail.zoo'),(4,'http://gitea.zoo'),(5,'http://auth.zoo'),(6,'http://classifieds.zoo'),(7,'http://excalidraw.zoo'),(8,'http://focalboard.zoo'),(10,'http://miniflux.zoo'),(11,'http://northwind.zoo'),(15,'http://wiki.zoo'),(16,'http://onestopshop.zoo'),(17,'http://postmill.zoo'),(18,'http://example.zoo'),(19,'http://home.zoo'),(20,'http://misc.zoo'),(21,'http://paste.zoo'),(22,'http://mattermost.zoo'),(23,'http://abaca.zoo'),(24,'http://alderpost.zoo'),(25,'http://ashline-quotient.zoo'),(26,'http://aurelia-playhouse.zoo'),(27,'http://boxelder.zoo'),(28,'http://brantmoor.zoo'),(29,'http://brindle-fig.zoo'),(30,'http://cadre-workplace.zoo'),(31,'http://caldmoor-bank-login.zoo'),(32,'http://caldmoorbank-online.zoo'),(33,'http://canvas-swatch.zoo'),(34,'http://cindergrid.zoo'),(35,'http://civic-revenue.zoo'),(36,'http://coppermast.zoo'),(37,'http://corvane.zoo'),(38,'http://cresthaven.zoo'),(39,'http://docs.gitea.zoo'),(40,'http://draymere.zoo'),(41,'http://drennhill-dental.zoo'),(42,'http://farholt.zoo'),(43,'http://ferncliff.zoo'),(44,'http://fernlight.zoo'),(45,'http://fernmail.zoo'),(46,'http://fernwood-commons.zoo'),(47,'http://gadgetron-mirror.zoo'),(48,'http://gadgetron.zoo'),(49,'http://grelsby-water.zoo'),(50,'http://halbeck.zoo'),(51,'http://harrowgate-works.zoo'),(52,'http://hearthline.zoo'),(53,'http://kelsmere.zoo'),(54,'http://kelverne.zoo'),(55,'http://kestrel-peak.zoo'),(56,'http://kettleforge.zoo'),(57,'http://lakefront-vendor.zoo'),(58,'http://larkfield.zoo'),(59,'http://lumeva.zoo'),(60,'http://marlowe-depot.zoo'),(61,'http://marlstone.zoo'),(62,'http://marrowfield.zoo'),(63,'http://marrowgate.zoo'),(64,'http://metronome.zoo'),(65,'http://millrace.zoo'),(66,'http://nerrow-strait.zoo'),(67,'http://nimbrel.zoo'),(68,'http://northgate-domains.zoo'),(69,'http://northmarsh.zoo'),(70,'http://northwind-ir.zoo'),(71,'http://ollister-crane.zoo'),(72,'http://orsino.zoo'),(73,'http://ostara.zoo'),(74,'http://overlane.zoo'),(75,'http://peregrine-court.zoo'),(76,'http://qandara-taa.zoo'),(77,'http://quennell.zoo'),(78,'http://skerrow-radio.zoo'),(79,'http://solstice.zoo'),(80,'http://status.zoo'),(81,'http://stavelock.zoo'),(82,'http://tamarack-hollow.zoo'),(83,'http://tealwave.zoo'),(84,'http://thornbury-trust.zoo'),(85,'http://trelowen.zoo'),(86,'http://verlan-transit.zoo'),(87,'http://voltro.zoo'),(88,'http://waypost.zoo'),(89,'http://zellick.zoo');
/*!40000 ALTER TABLE `matomo_site_url` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_tracking_failure`
--

DROP TABLE IF EXISTS `matomo_tracking_failure`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_tracking_failure` (
  `idsite` bigint unsigned NOT NULL,
  `idfailure` smallint unsigned NOT NULL,
  `date_first_occurred` datetime NOT NULL,
  `request_url` mediumtext NOT NULL,
  PRIMARY KEY (`idsite`,`idfailure`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_tracking_failure`
--

LOCK TABLES `matomo_tracking_failure` WRITE;
/*!40000 ALTER TABLE `matomo_tracking_failure` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_tracking_failure` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_twofactor_recovery_code`
--

DROP TABLE IF EXISTS `matomo_twofactor_recovery_code`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_twofactor_recovery_code` (
  `idrecoverycode` bigint unsigned NOT NULL AUTO_INCREMENT,
  `login` varchar(100) NOT NULL,
  `recovery_code` varchar(40) NOT NULL,
  PRIMARY KEY (`idrecoverycode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_twofactor_recovery_code`
--

LOCK TABLES `matomo_twofactor_recovery_code` WRITE;
/*!40000 ALTER TABLE `matomo_twofactor_recovery_code` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_twofactor_recovery_code` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_user`
--

DROP TABLE IF EXISTS `matomo_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_user` (
  `login` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `twofactor_secret` varchar(40) NOT NULL DEFAULT '',
  `superuser_access` tinyint unsigned NOT NULL DEFAULT '0',
  `date_registered` timestamp NULL DEFAULT NULL,
  `ts_password_modified` timestamp NULL DEFAULT NULL,
  `idchange_last_viewed` int unsigned DEFAULT NULL,
  `invited_by` varchar(100) DEFAULT NULL,
  `invite_token` varchar(191) DEFAULT NULL,
  `invite_link_token` varchar(191) DEFAULT NULL,
  `invite_expired_at` timestamp NULL DEFAULT NULL,
  `invite_accept_at` timestamp NULL DEFAULT NULL,
  `ts_changes_shown` timestamp NULL DEFAULT NULL,
  `ts_last_seen` timestamp NULL DEFAULT NULL,
  `ts_inactivity_notified` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`login`),
  UNIQUE KEY `uniq_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_user`
--

LOCK TABLES `matomo_user` WRITE;
/*!40000 ALTER TABLE `matomo_user` DISABLE KEYS */;
INSERT INTO `matomo_user` VALUES ('analytics_user','$2y$12$NvXiJv0MkAwt2oCN/dnvEe6UeS7QEdPwCA0HT3VyoEqnl2zHFoGwK','analytics_user@snappymail.zoo','',1,'2025-11-10 12:28:53','2025-11-10 12:28:53',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-01-27 17:25:00',NULL),('anonymous','','anonymous@example.org','',0,'2025-11-10 12:28:17','2025-11-10 12:28:17',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `matomo_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_user_dashboard`
--

DROP TABLE IF EXISTS `matomo_user_dashboard`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_user_dashboard` (
  `login` varchar(100) NOT NULL,
  `iddashboard` int NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `layout` text NOT NULL,
  PRIMARY KEY (`login`,`iddashboard`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_user_dashboard`
--

LOCK TABLES `matomo_user_dashboard` WRITE;
/*!40000 ALTER TABLE `matomo_user_dashboard` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_user_dashboard` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_user_language`
--

DROP TABLE IF EXISTS `matomo_user_language`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_user_language` (
  `login` varchar(100) NOT NULL,
  `language` varchar(10) NOT NULL,
  `use_12_hour_clock` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`login`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_user_language`
--

LOCK TABLES `matomo_user_language` WRITE;
/*!40000 ALTER TABLE `matomo_user_language` DISABLE KEYS */;
/*!40000 ALTER TABLE `matomo_user_language` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_user_token_auth`
--

DROP TABLE IF EXISTS `matomo_user_token_auth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_user_token_auth` (
  `idusertokenauth` bigint unsigned NOT NULL AUTO_INCREMENT,
  `login` varchar(100) NOT NULL,
  `description` varchar(100) NOT NULL,
  `password` varchar(191) NOT NULL,
  `hash_algo` varchar(30) NOT NULL,
  `system_token` tinyint(1) NOT NULL DEFAULT '0',
  `last_used` datetime DEFAULT NULL,
  `date_created` datetime NOT NULL,
  `date_expired` datetime DEFAULT NULL,
  `secure_only` tinyint unsigned NOT NULL DEFAULT '0',
  `ts_rotation_notified` datetime DEFAULT NULL,
  `ts_expiration_warning_notified` datetime DEFAULT NULL,
  PRIMARY KEY (`idusertokenauth`),
  UNIQUE KEY `uniq_password` (`password`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_user_token_auth`
--

LOCK TABLES `matomo_user_token_auth` WRITE;
/*!40000 ALTER TABLE `matomo_user_token_auth` DISABLE KEYS */;
INSERT INTO `matomo_user_token_auth` VALUES (1,'anonymous','anonymous default token','99e6d1f0b8387a9b8cb1095f49a7ca6944b49d35efa8f65054debc2a9a34022dacc21ad248b3602b9b8ce31b7a1286508b68cf0d22e899c280e9add88d5ee1e9','sha512',0,'2025-11-10 19:19:50','2025-11-10 12:28:17',NULL,0,NULL,NULL),(2,'analytics_user','Zoo run export','78bcec6a4a89beee7e7352faf87ebb22aa3b3b17356c1c3a27c728f519eec044972df873b69cebab3cb3f5b2ebefc88e8aad4fe6d52865885ea53a822e2fb679','sha512',0,NULL,'2026-09-20 04:44:50',NULL,0,NULL,NULL);
/*!40000 ALTER TABLE `matomo_user_token_auth` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed
