CREATE DATABASE  IF NOT EXISTS `agri_services_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `agri_services_db`;
-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: agri_services_db
-- ------------------------------------------------------
-- Server version	8.0.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `audit_log`
--

DROP TABLE IF EXISTS `audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_log` (
  `log_id` int unsigned NOT NULL AUTO_INCREMENT,
  `log_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `table_name` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `operation` enum('INSERT','UPDATE','DELETE') COLLATE utf8mb4_unicode_ci NOT NULL,
  `record_id` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'PK of affected row',
  `changed_by` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (user()),
  `old_values` text COLLATE utf8mb4_unicode_ci COMMENT 'JSON before-state',
  `new_values` text COLLATE utf8mb4_unicode_ci COMMENT 'JSON after-state',
  PRIMARY KEY (`log_id`),
  KEY `idx_audit_table` (`table_name`),
  KEY `idx_audit_timestamp` (`log_timestamp`),
  KEY `idx_audit_operation` (`operation`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tamper-evident audit trail for sensitive data changes';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_log`
--

LOCK TABLES `audit_log` WRITE;
/*!40000 ALTER TABLE `audit_log` DISABLE KEYS */;
INSERT INTO `audit_log` VALUES (2,'2026-04-13 03:32:57','resource','UPDATE','2','root@localhost','{\"qty\": 5000, \"batch_no\": \"BATCH-2024-001\"}','{\"qty\": 4950, \"batch_no\": \"BATCH-2024-001\"}'),(3,'2026-04-13 03:32:57','farmer','INSERT','7','root@localhost',NULL,'{\"farmer_id\": 7, \"national_id\": \"TEST001\", \"registration_date\": \"2026-04-13\", \"cooperative_member\": 0}'),(4,'2026-04-13 03:32:58','farmer','INSERT','8','root@localhost',NULL,'{\"farmer_id\": 8, \"national_id\": \"CM901001A\", \"registration_date\": \"2026-04-13\", \"cooperative_member\": 0}');
/*!40000 ALTER TABLE `audit_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `backup_config`
--

DROP TABLE IF EXISTS `backup_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `backup_config` (
  `config_id` int unsigned NOT NULL AUTO_INCREMENT,
  `backup_type` enum('Full','Incremental','Binary Log') COLLATE utf8mb4_unicode_ci NOT NULL,
  `frequency` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `retention_days` int NOT NULL,
  `storage_path` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`config_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Backup schedule and retention policy';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `backup_config`
--

LOCK TABLES `backup_config` WRITE;
/*!40000 ALTER TABLE `backup_config` DISABLE KEYS */;
INSERT INTO `backup_config` VALUES (1,'Full','Every Sunday at 02:00',90,'/var/backups/agri_db/full/','Full mysqldump including routines, triggers, events. Compressed with gzip.'),(2,'Incremental','Monday to Saturday at 02:00',30,'/var/backups/agri_db/incremental/','Binary log backup since last full. Enables replay of daily changes.'),(3,'Binary Log','Continuous ? flushed daily',14,'/var/lib/mysql/binlog/','Enables point-in-time recovery to any second. Requires log_bin=ON in my.cnf.');
/*!40000 ALTER TABLE `backup_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `coffee_variety`
--

DROP TABLE IF EXISTS `coffee_variety`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `coffee_variety` (
  `variety_id` int unsigned NOT NULL AUTO_INCREMENT,
  `variety_name` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `variety_type` enum('Robusta','Arabica') COLLATE utf8mb4_unicode_ci NOT NULL,
  `avg_yield_kg_per_acre` decimal(8,2) DEFAULT NULL,
  `disease_resistance` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ideal_altitude_m` int DEFAULT NULL,
  PRIMARY KEY (`variety_id`),
  UNIQUE KEY `uq_variety_name` (`variety_name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Coffee variety catalogue maintained by the Ministry';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `coffee_variety`
--

LOCK TABLES `coffee_variety` WRITE;
/*!40000 ALTER TABLE `coffee_variety` DISABLE KEYS */;
INSERT INTO `coffee_variety` VALUES (1,'Robusta CRI','Robusta',800.00,'CBD Resistant',1050),(2,'Arabica SL28','Arabica',650.00,'Moderate Resistance',950),(3,'Arabica K7','Arabica',700.00,'CBD Resistant',900);
/*!40000 ALTER TABLE `coffee_variety` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `complaint_feedback`
--

DROP TABLE IF EXISTS `complaint_feedback`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `complaint_feedback` (
  `complaint_id` int unsigned NOT NULL AUTO_INCREMENT,
  `farmer_id` int unsigned NOT NULL,
  `date_raised` date NOT NULL,
  `category` enum('Input Quality','Late Delivery','Advisory','Extension Worker','General','Other') COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `resolution_status` enum('Open','In Progress','Resolved','Dismissed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Open',
  `resolved_date` date DEFAULT NULL,
  PRIMARY KEY (`complaint_id`),
  KEY `fk_cf_farmer` (`farmer_id`),
  KEY `idx_complaint_status` (`resolution_status`),
  CONSTRAINT `fk_cf_farmer` FOREIGN KEY (`farmer_id`) REFERENCES `farmer` (`farmer_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_cf_resolved` CHECK (((`resolved_date` is null) or (`resolved_date` >= `date_raised`)))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Weak entity — farmer complaints and service feedback';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `complaint_feedback`
--

LOCK TABLES `complaint_feedback` WRITE;
/*!40000 ALTER TABLE `complaint_feedback` DISABLE KEYS */;
/*!40000 ALTER TABLE `complaint_feedback` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `coop_membership`
--

DROP TABLE IF EXISTS `coop_membership`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `coop_membership` (
  `farmer_id` int unsigned NOT NULL,
  `coop_id` int unsigned NOT NULL,
  `join_date` date NOT NULL,
  `membership_status` enum('Active','Suspended','Withdrawn') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`farmer_id`,`coop_id`),
  KEY `fk_cm_coop` (`coop_id`),
  CONSTRAINT `fk_cm_coop` FOREIGN KEY (`coop_id`) REFERENCES `cooperative` (`coop_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_cm_farmer` FOREIGN KEY (`farmer_id`) REFERENCES `farmer` (`farmer_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Bridge — resolves FARMER to COOPERATIVE M:N';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `coop_membership`
--

LOCK TABLES `coop_membership` WRITE;
/*!40000 ALTER TABLE `coop_membership` DISABLE KEYS */;
/*!40000 ALTER TABLE `coop_membership` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cooperative`
--

DROP TABLE IF EXISTS `cooperative`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cooperative` (
  `coop_id` int unsigned NOT NULL AUTO_INCREMENT,
  `coop_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `registration_no` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `district` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `chairperson` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_established` date NOT NULL,
  PRIMARY KEY (`coop_id`),
  UNIQUE KEY `uq_coop_reg_no` (`registration_no`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Farmer cooperatives registered with the Ministry';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cooperative`
--

LOCK TABLES `cooperative` WRITE;
/*!40000 ALTER TABLE `cooperative` DISABLE KEYS */;
INSERT INTO `cooperative` VALUES (1,'Mukono Coffee Growers SACCO','COOP-MK-001','Mukono','Ssemakula John','2010-05-01'),(2,'Wakiso Farmers Union','COOP-WK-002','Wakiso','Namukasa Fatuma','2015-03-18'),(3,'Northern Uganda Coffee CIG','COOP-GU-003','Gulu','Ocen Richard','2020-07-12');
/*!40000 ALTER TABLE `cooperative` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `distribution_event`
--

DROP TABLE IF EXISTS `distribution_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `distribution_event` (
  `event_id` int unsigned NOT NULL AUTO_INCREMENT,
  `activity_id` int unsigned NOT NULL,
  `resource_id` int unsigned NOT NULL,
  `quantity_given` int unsigned NOT NULL,
  `distribution_point` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `received_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `acknowledgement_signed` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`event_id`),
  UNIQUE KEY `uq_de_activity_id` (`activity_id`),
  KEY `idx_dist_resource` (`resource_id`),
  CONSTRAINT `fk_de_interaction` FOREIGN KEY (`activity_id`) REFERENCES `interaction` (`activity_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_de_resource` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`resource_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_de_qty` CHECK ((`quantity_given` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Subtype of INTERACTION — physical goods delivery (disjoint)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `distribution_event`
--

LOCK TABLES `distribution_event` WRITE;
/*!40000 ALTER TABLE `distribution_event` DISABLE KEYS */;
/*!40000 ALTER TABLE `distribution_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `extension_worker`
--

DROP TABLE IF EXISTS `extension_worker`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `extension_worker` (
  `staff_id` int unsigned NOT NULL AUTO_INCREMENT,
  `national_id` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `qualification` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expertise_area` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `assigned_region` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `hire_date` date NOT NULL,
  PRIMARY KEY (`staff_id`),
  UNIQUE KEY `uq_ext_worker_nid` (`national_id`),
  CONSTRAINT `fk_ext_worker_person` FOREIGN KEY (`national_id`) REFERENCES `person` (`national_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Subtype of PERSON — Ministry field and training staff';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `extension_worker`
--

LOCK TABLES `extension_worker` WRITE;
/*!40000 ALTER TABLE `extension_worker` DISABLE KEYS */;
/*!40000 ALTER TABLE `extension_worker` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `farm`
--

DROP TABLE IF EXISTS `farm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `farm` (
  `farm_id` int unsigned NOT NULL AUTO_INCREMENT,
  `farmer_id` int unsigned NOT NULL,
  `gps_latitude` decimal(10,7) DEFAULT NULL,
  `gps_longitude` decimal(10,7) DEFAULT NULL,
  `land_size_acres` decimal(8,2) NOT NULL,
  `soil_type` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `water_source` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `altitude_m` int DEFAULT NULL,
  `district` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `village` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `registration_date` date NOT NULL,
  PRIMARY KEY (`farm_id`),
  KEY `idx_farm_farmer` (`farmer_id`),
  KEY `idx_farm_district` (`district`),
  CONSTRAINT `fk_farm_farmer` FOREIGN KEY (`farmer_id`) REFERENCES `farmer` (`farmer_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_farm_altitude` CHECK (((`altitude_m` is null) or (`altitude_m` between 0 and 5000))),
  CONSTRAINT `chk_farm_size` CHECK ((`land_size_acres` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Supertype — physical farm plot owned by a registered farmer';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `farm`
--

LOCK TABLES `farm` WRITE;
/*!40000 ALTER TABLE `farm` DISABLE KEYS */;
/*!40000 ALTER TABLE `farm` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `farm_variety`
--

DROP TABLE IF EXISTS `farm_variety`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `farm_variety` (
  `farm_id` int unsigned NOT NULL,
  `variety_id` int unsigned NOT NULL,
  `area_allocated_acres` decimal(8,2) NOT NULL,
  `year_planted` year NOT NULL,
  PRIMARY KEY (`farm_id`,`variety_id`),
  KEY `fk_fv_variety` (`variety_id`),
  CONSTRAINT `fk_fv_farm` FOREIGN KEY (`farm_id`) REFERENCES `farm` (`farm_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_fv_variety` FOREIGN KEY (`variety_id`) REFERENCES `coffee_variety` (`variety_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_fv_area` CHECK ((`area_allocated_acres` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Bridge — resolves FARM to COFFEE_VARIETY M:N';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `farm_variety`
--

LOCK TABLES `farm_variety` WRITE;
/*!40000 ALTER TABLE `farm_variety` DISABLE KEYS */;
/*!40000 ALTER TABLE `farm_variety` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `farmer`
--

DROP TABLE IF EXISTS `farmer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `farmer` (
  `farmer_id` int unsigned NOT NULL AUTO_INCREMENT,
  `national_id` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `registration_date` date NOT NULL,
  `cooperative_member` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1 = active cooperative member',
  PRIMARY KEY (`farmer_id`),
  UNIQUE KEY `uq_farmer_nid` (`national_id`),
  CONSTRAINT `fk_farmer_person` FOREIGN KEY (`national_id`) REFERENCES `person` (`national_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Subtype of PERSON — coffee farmers registered with the Ministry';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `farmer`
--

LOCK TABLES `farmer` WRITE;
/*!40000 ALTER TABLE `farmer` DISABLE KEYS */;
INSERT INTO `farmer` VALUES (8,'CM901001A','2026-04-13',0);
/*!40000 ALTER TABLE `farmer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `field_officer`
--

DROP TABLE IF EXISTS `field_officer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `field_officer` (
  `fo_id` int unsigned NOT NULL AUTO_INCREMENT,
  `staff_id` int unsigned NOT NULL,
  `farms_assigned` int unsigned NOT NULL DEFAULT '0',
  `last_visit_date` date DEFAULT NULL,
  PRIMARY KEY (`fo_id`),
  UNIQUE KEY `uq_fo_staff` (`staff_id`),
  CONSTRAINT `fk_fo_worker` FOREIGN KEY (`staff_id`) REFERENCES `extension_worker` (`staff_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Subtype L2 of EXT_WORKER — visits individual farms';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `field_officer`
--

LOCK TABLES `field_officer` WRITE;
/*!40000 ALTER TABLE `field_officer` DISABLE KEYS */;
/*!40000 ALTER TABLE `field_officer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `input`
--

DROP TABLE IF EXISTS `input`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `input` (
  `input_id` int unsigned NOT NULL AUTO_INCREMENT,
  `resource_id` int unsigned NOT NULL,
  `input_type` enum('Fertiliser','Pesticide','Tool','Other') COLLATE utf8mb4_unicode_ci NOT NULL,
  `weight_kg` decimal(10,2) DEFAULT NULL,
  `application_instructions` text COLLATE utf8mb4_unicode_ci,
  `expiry_date` date DEFAULT NULL,
  PRIMARY KEY (`input_id`),
  UNIQUE KEY `uq_input_rid` (`resource_id`),
  CONSTRAINT `fk_input_resource` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`resource_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Subtype of RESOURCE — fertilisers, pesticides, tools (disjoint)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `input`
--

LOCK TABLES `input` WRITE;
/*!40000 ALTER TABLE `input` DISABLE KEYS */;
INSERT INTO `input` VALUES (1,2,'Fertiliser',50.00,'Apply 200g per plant at onset of rains','2026-01-01'),(2,4,'Pesticide',25.00,'Dilute 10ml per litre, spray at dusk','2025-08-01');
/*!40000 ALTER TABLE `input` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `interaction`
--

DROP TABLE IF EXISTS `interaction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `interaction` (
  `activity_id` int unsigned NOT NULL AUTO_INCREMENT,
  `farmer_id` int unsigned NOT NULL,
  `activity_date` date NOT NULL,
  `district` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `activity_status` enum('Completed','Pending','Cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pending',
  PRIMARY KEY (`activity_id`),
  KEY `fk_interaction_farmer` (`farmer_id`),
  KEY `idx_interaction_date` (`activity_date`),
  KEY `idx_interaction_status` (`activity_status`),
  CONSTRAINT `fk_interaction_farmer` FOREIGN KEY (`farmer_id`) REFERENCES `farmer` (`farmer_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Supertype — all Ministry-farmer service interactions';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `interaction`
--

LOCK TABLES `interaction` WRITE;
/*!40000 ALTER TABLE `interaction` DISABLE KEYS */;
/*!40000 ALTER TABLE `interaction` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `person`
--

DROP TABLE IF EXISTS `person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `person` (
  `national_id` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Uganda NIN — primary key',
  `full_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_of_birth` date NOT NULL,
  `gender` enum('Male','Female','Other') COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone_number` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `village_lc1` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`national_id`),
  KEY `idx_person_district` (`district`),
  KEY `idx_person_full_name` (`full_name`),
  CONSTRAINT `chk_person_dob` CHECK ((`date_of_birth` >= _utf8mb4'1900-01-01')),
  CONSTRAINT `chk_person_phone` CHECK (regexp_like(`phone_number`,_utf8mb4'^[0-9+][0-9 \\-]{6,14}$'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Supertype — shared identity attributes for all stakeholders';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `person`
--

LOCK TABLES `person` WRITE;
/*!40000 ALTER TABLE `person` DISABLE KEYS */;
INSERT INTO `person` VALUES ('CM901001A','Nakato Aisha','1985-03-12','Female','0772100001','nakato@gmail.com','Mukono','Namanve','2026-04-12 13:01:37','2026-04-12 13:01:37'),('CM901002B','Ssekandi Robert','1979-07-24','Male','0752100002',NULL,'Wakiso','Buloba','2026-04-13 03:46:54','2026-04-13 03:46:54'),('CM901003C','Nabirye Grace','1990-11-05','Female','0700100003','grace@gmail.com','Jinja','Mpumudde','2026-04-13 03:46:54','2026-04-13 03:46:54'),('CM901004D','Kato Emmanuel','1982-01-18','Male','0783100004',NULL,'Mukono','Kiwanga','2026-04-13 03:46:54','2026-04-13 03:46:54'),('CM901005E','Namutebi Josephine','1975-09-30','Female','0756100005',NULL,'Kampala','Kawempe','2026-04-13 03:46:54','2026-04-13 03:46:54'),('CM901006F','Opio Samuel','1988-06-15','Male','0771200006','opio@gmail.com','Lira','Adyel','2026-04-13 03:46:54','2026-04-13 03:46:54'),('CM901007G','Akello Prossy','1992-04-22','Female','0702300007','akello@gmail.com','Gulu','Laroo','2026-04-13 03:46:54','2026-04-13 03:46:54');
/*!40000 ALTER TABLE `person` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `production_record`
--

DROP TABLE IF EXISTS `production_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `production_record` (
  `record_id` int unsigned NOT NULL AUTO_INCREMENT,
  `farm_id` int unsigned NOT NULL,
  `season` enum('Long','Short') COLLATE utf8mb4_unicode_ci NOT NULL,
  `year` year NOT NULL,
  `harvest_date` date DEFAULT NULL,
  `yield_kg` decimal(10,2) NOT NULL DEFAULT '0.00',
  `quality_grade` enum('A','B','C','Ungraded') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Ungraded',
  `pest_issues` text COLLATE utf8mb4_unicode_ci,
  `notes` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`record_id`),
  UNIQUE KEY `uq_prod_farm_ssn_yr` (`farm_id`,`season`,`year`),
  KEY `idx_prod_year` (`year`),
  KEY `idx_prod_quality` (`quality_grade`),
  CONSTRAINT `fk_pr_farm` FOREIGN KEY (`farm_id`) REFERENCES `farm` (`farm_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_pr_yield` CHECK ((`yield_kg` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Weak entity — one seasonal harvest record per farm';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `production_record`
--

LOCK TABLES `production_record` WRITE;
/*!40000 ALTER TABLE `production_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `production_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `programme_enrolment`
--

DROP TABLE IF EXISTS `programme_enrolment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `programme_enrolment` (
  `farmer_id` int unsigned NOT NULL,
  `programme_id` int unsigned NOT NULL,
  `enrolment_date` date NOT NULL,
  `completion_status` enum('Enrolled','Completed','Dropped') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Enrolled',
  `certificate_no` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`farmer_id`,`programme_id`),
  KEY `fk_pe_programme` (`programme_id`),
  CONSTRAINT `fk_pe_farmer` FOREIGN KEY (`farmer_id`) REFERENCES `farmer` (`farmer_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pe_programme` FOREIGN KEY (`programme_id`) REFERENCES `training_programme` (`programme_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Bridge — resolves FARMER to TRAINING_PROGRAMME M:N';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `programme_enrolment`
--

LOCK TABLES `programme_enrolment` WRITE;
/*!40000 ALTER TABLE `programme_enrolment` DISABLE KEYS */;
/*!40000 ALTER TABLE `programme_enrolment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resource`
--

DROP TABLE IF EXISTS `resource`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource` (
  `resource_id` int unsigned NOT NULL AUTO_INCREMENT,
  `supplier_id` int unsigned NOT NULL,
  `batch_no` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_received` date NOT NULL,
  `quantity_available` int unsigned NOT NULL DEFAULT '0',
  `unit_cost_ugx` decimal(12,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`resource_id`),
  UNIQUE KEY `uq_resource_batch` (`batch_no`),
  KEY `fk_resource_supplier` (`supplier_id`),
  KEY `idx_resource_batch` (`batch_no`),
  CONSTRAINT `fk_resource_supplier` FOREIGN KEY (`supplier_id`) REFERENCES `supplier` (`supplier_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_resource_cost` CHECK ((`unit_cost_ugx` >= 0)),
  CONSTRAINT `chk_resource_qty` CHECK ((`quantity_available` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Supertype — all procured items managed by the Ministry';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resource`
--

LOCK TABLES `resource` WRITE;
/*!40000 ALTER TABLE `resource` DISABLE KEYS */;
INSERT INTO `resource` VALUES (2,1,'BATCH-2024-001','2024-01-10',4950,1200.00),(3,2,'BATCH-2024-002','2024-02-05',200,45000.00),(4,1,'BATCH-2024-003','2024-03-18',3000,1200.00),(5,2,'BATCH-2024-004','2024-04-02',150,52000.00);
/*!40000 ALTER TABLE `resource` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `seedling`
--

DROP TABLE IF EXISTS `seedling`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `seedling` (
  `seedling_id` int unsigned NOT NULL AUTO_INCREMENT,
  `resource_id` int unsigned NOT NULL,
  `variety_id` int unsigned DEFAULT NULL,
  `variety_label` enum('Robusta','Arabica') COLLATE utf8mb4_unicode_ci NOT NULL,
  `germination_rate` decimal(5,2) DEFAULT NULL COMMENT 'Percentage 0–100',
  `age_weeks` int unsigned DEFAULT NULL,
  `nursery_source` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`seedling_id`),
  UNIQUE KEY `uq_seedling_rid` (`resource_id`),
  KEY `fk_seedling_variety` (`variety_id`),
  CONSTRAINT `fk_seedling_resource` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`resource_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_seedling_variety` FOREIGN KEY (`variety_id`) REFERENCES `coffee_variety` (`variety_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_seedling_germ` CHECK (((`germination_rate` is null) or (`germination_rate` between 0 and 100)))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Subtype of RESOURCE — coffee seedlings (disjoint)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `seedling`
--

LOCK TABLES `seedling` WRITE;
/*!40000 ALTER TABLE `seedling` DISABLE KEYS */;
/*!40000 ALTER TABLE `seedling` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `supplier`
--

DROP TABLE IF EXISTS `supplier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `supplier` (
  `supplier_id` int unsigned NOT NULL AUTO_INCREMENT,
  `supplier_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact_person` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `location` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `certification` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`supplier_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Approved suppliers of seedlings and inputs';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `supplier`
--

LOCK TABLES `supplier` WRITE;
/*!40000 ALTER TABLE `supplier` DISABLE KEYS */;
INSERT INTO `supplier` VALUES (1,'UCDA Nurseries','Tendo Paul','0414700001','Entebbe','UCDA Certified'),(2,'AgriInputs Uganda Ltd','Birungi Sarah','0772500001','Kampala','NDA Registered');
/*!40000 ALTER TABLE `supplier` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `trainer`
--

DROP TABLE IF EXISTS `trainer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trainer` (
  `tr_id` int unsigned NOT NULL AUTO_INCREMENT,
  `staff_id` int unsigned NOT NULL,
  `specialisation` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sessions_conducted` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`tr_id`),
  UNIQUE KEY `uq_trainer_staff` (`staff_id`),
  CONSTRAINT `fk_trainer_worker` FOREIGN KEY (`staff_id`) REFERENCES `extension_worker` (`staff_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Subtype L2 of EXT_WORKER — conducts group training sessions';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `trainer`
--

LOCK TABLES `trainer` WRITE;
/*!40000 ALTER TABLE `trainer` DISABLE KEYS */;
/*!40000 ALTER TABLE `trainer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `training_programme`
--

DROP TABLE IF EXISTS `training_programme`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `training_programme` (
  `programme_id` int unsigned NOT NULL AUTO_INCREMENT,
  `programme_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `topic` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `venue` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `max_participants` int unsigned NOT NULL DEFAULT '30',
  PRIMARY KEY (`programme_id`),
  CONSTRAINT `chk_tp_dates` CHECK ((`end_date` >= `start_date`)),
  CONSTRAINT `chk_tp_max` CHECK ((`max_participants` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ministry-organised training and sensitisation events';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `training_programme`
--

LOCK TABLES `training_programme` WRITE;
/*!40000 ALTER TABLE `training_programme` DISABLE KEYS */;
INSERT INTO `training_programme` VALUES (1,'Good Agricultural Practices 2024','Coffee quality improvement and post-harvest handling','2024-04-01','2024-04-03','Mukono District Headquarters',50),(2,'Pest and Disease Management Workshop','Identification and control of coffee wilt and leaf rust','2024-06-10','2024-06-11','Wakiso Agricultural Training Centre',40);
/*!40000 ALTER TABLE `training_programme` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `visit_report`
--

DROP TABLE IF EXISTS `visit_report`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `visit_report` (
  `session_id` int unsigned NOT NULL AUTO_INCREMENT,
  `activity_id` int unsigned NOT NULL,
  `staff_id` int unsigned NOT NULL,
  `advice_summary` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `follow_up_required` tinyint(1) NOT NULL DEFAULT '0',
  `next_visit_date` date DEFAULT NULL,
  `session_type` enum('Individual','Group','Remote') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Individual',
  PRIMARY KEY (`session_id`),
  UNIQUE KEY `uq_as_activity_id` (`activity_id`),
  KEY `idx_advisory_worker` (`staff_id`),
  CONSTRAINT `fk_as_interaction` FOREIGN KEY (`activity_id`) REFERENCES `interaction` (`activity_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_as_worker` FOREIGN KEY (`staff_id`) REFERENCES `extension_worker` (`staff_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Subtype of INTERACTION — advisory farm visit (disjoint)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `visit_report`
--

LOCK TABLES `visit_report` WRITE;
/*!40000 ALTER TABLE `visit_report` DISABLE KEYS */;
/*!40000 ALTER TABLE `visit_report` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `vw_cooperative_summary`
--

DROP TABLE IF EXISTS `vw_cooperative_summary`;
/*!50001 DROP VIEW IF EXISTS `vw_cooperative_summary`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_cooperative_summary` AS SELECT 
 1 AS `coop_id`,
 1 AS `coop_name`,
 1 AS `registration_no`,
 1 AS `district`,
 1 AS `chairperson`,
 1 AS `date_established`,
 1 AS `member_count`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_person_full`
--

DROP TABLE IF EXISTS `vw_person_full`;
/*!50001 DROP VIEW IF EXISTS `vw_person_full`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_person_full` AS SELECT 
 1 AS `national_id`,
 1 AS `full_name`,
 1 AS `date_of_birth`,
 1 AS `age`,
 1 AS `gender`,
 1 AS `phone_number`,
 1 AS `email`,
 1 AS `district`,
 1 AS `village_lc1`,
 1 AS `created_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_production_revenue`
--

DROP TABLE IF EXISTS `vw_production_revenue`;
/*!50001 DROP VIEW IF EXISTS `vw_production_revenue`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_production_revenue` AS SELECT 
 1 AS `record_id`,
 1 AS `farm_id`,
 1 AS `district`,
 1 AS `village`,
 1 AS `farmer_name`,
 1 AS `phone_number`,
 1 AS `season`,
 1 AS `year`,
 1 AS `harvest_date`,
 1 AS `yield_kg`,
 1 AS `quality_grade`,
 1 AS `pest_issues`,
 1 AS `revenue_estimate_ugx`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_resource_value`
--

DROP TABLE IF EXISTS `vw_resource_value`;
/*!50001 DROP VIEW IF EXISTS `vw_resource_value`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_resource_value` AS SELECT 
 1 AS `resource_id`,
 1 AS `batch_no`,
 1 AS `date_received`,
 1 AS `quantity_available`,
 1 AS `unit_cost_ugx`,
 1 AS `total_value_ugx`,
 1 AS `supplier_name`,
 1 AS `supplier_location`,
 1 AS `resource_type`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_worker_profile`
--

DROP TABLE IF EXISTS `vw_worker_profile`;
/*!50001 DROP VIEW IF EXISTS `vw_worker_profile`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_worker_profile` AS SELECT 
 1 AS `staff_id`,
 1 AS `full_name`,
 1 AS `national_id`,
 1 AS `phone_number`,
 1 AS `district`,
 1 AS `qualification`,
 1 AS `expertise_area`,
 1 AS `assigned_region`,
 1 AS `hire_date`,
 1 AS `years_of_service`,
 1 AS `worker_role`*/;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `vw_cooperative_summary`
--

/*!50001 DROP VIEW IF EXISTS `vw_cooperative_summary`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_cooperative_summary` AS select `c`.`coop_id` AS `coop_id`,`c`.`coop_name` AS `coop_name`,`c`.`registration_no` AS `registration_no`,`c`.`district` AS `district`,`c`.`chairperson` AS `chairperson`,`c`.`date_established` AS `date_established`,count(`cm`.`farmer_id`) AS `member_count` from (`cooperative` `c` left join `coop_membership` `cm` on(((`cm`.`coop_id` = `c`.`coop_id`) and (`cm`.`membership_status` = 'Active')))) group by `c`.`coop_id`,`c`.`coop_name`,`c`.`registration_no`,`c`.`district`,`c`.`chairperson`,`c`.`date_established` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_person_full`
--

/*!50001 DROP VIEW IF EXISTS `vw_person_full`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_person_full` AS select `p`.`national_id` AS `national_id`,`p`.`full_name` AS `full_name`,`p`.`date_of_birth` AS `date_of_birth`,timestampdiff(YEAR,`p`.`date_of_birth`,curdate()) AS `age`,`p`.`gender` AS `gender`,`p`.`phone_number` AS `phone_number`,`p`.`email` AS `email`,`p`.`district` AS `district`,`p`.`village_lc1` AS `village_lc1`,`p`.`created_at` AS `created_at` from `person` `p` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_production_revenue`
--

/*!50001 DROP VIEW IF EXISTS `vw_production_revenue`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_production_revenue` AS select `pr`.`record_id` AS `record_id`,`pr`.`farm_id` AS `farm_id`,`fm`.`district` AS `district`,`fm`.`village` AS `village`,`p`.`full_name` AS `farmer_name`,`p`.`phone_number` AS `phone_number`,`pr`.`season` AS `season`,`pr`.`year` AS `year`,`pr`.`harvest_date` AS `harvest_date`,`pr`.`yield_kg` AS `yield_kg`,`pr`.`quality_grade` AS `quality_grade`,`pr`.`pest_issues` AS `pest_issues`,(`pr`.`yield_kg` * 3500) AS `revenue_estimate_ugx` from (((`production_record` `pr` join `farm` `fm` on((`fm`.`farm_id` = `pr`.`farm_id`))) join `farmer` `f` on((`f`.`farmer_id` = `fm`.`farmer_id`))) join `person` `p` on((`p`.`national_id` = `f`.`national_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_resource_value`
--

/*!50001 DROP VIEW IF EXISTS `vw_resource_value`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_resource_value` AS select `r`.`resource_id` AS `resource_id`,`r`.`batch_no` AS `batch_no`,`r`.`date_received` AS `date_received`,`r`.`quantity_available` AS `quantity_available`,`r`.`unit_cost_ugx` AS `unit_cost_ugx`,(`r`.`quantity_available` * `r`.`unit_cost_ugx`) AS `total_value_ugx`,`s`.`supplier_name` AS `supplier_name`,`s`.`location` AS `supplier_location`,(case when (`se`.`seedling_id` is not null) then 'Seedling' when (`ip`.`input_id` is not null) then 'Input' else 'Unclassified' end) AS `resource_type` from (((`resource` `r` join `supplier` `s` on((`s`.`supplier_id` = `r`.`supplier_id`))) left join `seedling` `se` on((`se`.`resource_id` = `r`.`resource_id`))) left join `input` `ip` on((`ip`.`resource_id` = `r`.`resource_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_worker_profile`
--

/*!50001 DROP VIEW IF EXISTS `vw_worker_profile`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_worker_profile` AS select `ew`.`staff_id` AS `staff_id`,`p`.`full_name` AS `full_name`,`p`.`national_id` AS `national_id`,`p`.`phone_number` AS `phone_number`,`p`.`district` AS `district`,`ew`.`qualification` AS `qualification`,`ew`.`expertise_area` AS `expertise_area`,`ew`.`assigned_region` AS `assigned_region`,`ew`.`hire_date` AS `hire_date`,timestampdiff(YEAR,`ew`.`hire_date`,curdate()) AS `years_of_service`,(case when ((`fo`.`fo_id` is not null) and (`tr`.`tr_id` is not null)) then 'Field Officer & Trainer' when (`fo`.`fo_id` is not null) then 'Field Officer' when (`tr`.`tr_id` is not null) then 'Trainer' else 'Unclassified' end) AS `worker_role` from (((`extension_worker` `ew` join `person` `p` on((`p`.`national_id` = `ew`.`national_id`))) left join `field_officer` `fo` on((`fo`.`staff_id` = `ew`.`staff_id`))) left join `trainer` `tr` on((`tr`.`staff_id` = `ew`.`staff_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-13 20:44:23
