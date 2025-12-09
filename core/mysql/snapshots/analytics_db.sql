-- MySQL dump 10.13  Distrib 8.1.0, for Linux (aarch64)
--
-- Host: localhost    Database: analytics_db
-- ------------------------------------------------------
-- Server version	8.1.0

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
INSERT INTO `matomo_archive_blob_2025_11` VALUES (1,'Actions_actions',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúçî\›nÉ Ä_•\·~¥M\Òz≥ª\›⁄≤J¶`Ñ≠Köæ˚@=Æ\⁄\Œƒàá\Ôæ(\…	øhé+\…Y\Zò_/9j\‰^5®rúéVo÷Æ^ï\Ï5™4ß\·&\\ŒV\≈2ö3\\\«â%8\¬1è\—j,<BtÕë˚lÖ◊≠F˘≥\Ì?\‚Ç!å_0]\„¯BÉäŸãZ{\'\Œ\⁄\◊wt®M\–oµVõ\«\’H~?ÅJ\‡\ÂTˇ•˙\√ÿ®U\Ãi\›\‡lU´ÖZì§ñò\rp\ÚΩ4\ÓPînG´\ıúƒ≥\◊x-\÷®d∂º*nG€äÆ∑\Âú6\'\m\…¿2:gxüî<c\Ì\Ï˘§\ˆ¿&\€∞\ÁÉmªFymÕç\r\◊c\Ái“∏\Àgú!∂õ˝L:\√\Z\—Xyº”ö\Ô@\'üIg\‰˘¥N3°ë7©£∑˘oÑæ\«\v6•`Ü)π\Ã\—kå\»x\‡åæìß∞•¥oîË§ØO\Ã<gBJ<(Æ\◊Xuû'),(1,'Actions_actions_url',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúçînÇ0á\Ô\“HˇÄ\∆rØ@™t£¥Ü\÷ifº˚Z∞\ı1AGBÄ\ˆ{ø~^\'¸™8.g\Ò&\«¸jy¡Q+\ˆ≤E•\Âké2•kyA•\‚‘üûiÄï!@qÜ\Àzº!æòpÑC£\Â.\\òø¯QüiO]\ÂT\'+-\›\Ÿ\Ù_\˜•\\n\”5\‘K\Ë}\’(g´≥r\Õ\Ì≥	∫ßuJøN qy¿\À\ ˛[\ˆÜ±Q+ü\”z¿…™\0VY•ñò\rprΩ\–\ˆPînG´\ıúƒì\◊x-\Ê\rT4[^ï∑\⁄t’±7i≠“ü\‡›íÅet\Œ\π(zÜ\Ï\‰˘&{`£\Ì?ÿâ\Û¡t\«V:e\ÙÉ\ı\«k\Ái\—¯ó\œ8Cl7\'˙òtÜ\—UkD˝§5\ﬂÄé>ì\ŒH\Ûqù$f|#obGo\”\◊\}è\·\ÏlJ¡\…cqëFoaDÑ≠∆øPéN˝∞´ê-GçsGÀ≥\ÃJ\—ö’è1ŸÄáM\‚v˚Oßr2'),(1,'Actions_downloads',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Actions_outlink',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Actions_sitesearch',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Actions_SiteSearchCategories',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Contents_name_piece',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Contents_piece_name',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'DevicePlugins_plugin',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúÖ\–AÇ0–ª\Ã	Jã®øw\äåAäC∏ª›ê∏\–v\˜\Û3ˇ-\∆\‡Ñï!¥Å⁄É\ƒ\Íq\09sµé¥G*˚æeKö!CëÅ2\“#\ÁkHJ_\ˆ\‚?r\Ìåoæ\Ò€ëQ\'\›\Õl“åä2\n4TuZ…£\ \Ù|q\ŸN\‹Ÿ¥uàZô\0ç÷∏¡ô∑\”Z\◊\¬–≥õ\Ì\Ë¯\÷Li\Ó\Á$h\·G\’/æ≥\'ﬂø}\0ﬂ≤5'),(1,'DevicesDetection_brands',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúM\Ã=\nÄ0\‡ª\‰˝±J_&/ ^!ÇC°[«íªk∞äCH\»\˜ÅG/p,à\Ôê\—®\ qV\‚Ü\0Zw\‚?*åo\Ù o3\€y¡40=\Ë\Á_p˘\ˆjAÅCW˚µ±\ÍG&¨'),(1,'DevicesDetection_browserEngines',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨¡l\˜\‘\‰\Ï|%\ÎL+C(6Ç\“\∆@yC+%Cêú±•5»ÑL+®§)D\“\0$iÜ§\–.^Ròhe`U]2\Àœ∫∂\0π¥('),(1,'DevicesDetection_browsers',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúM\Ã1Ä –ª\ÙD\√\Ô\Œ\Ë0q ac$Ωª6¢qh\⁄\Ù˝∂Ä1*úÑwH\‘\ q6í ô§Çg˘\Ÿ√çb≥ê\ƒ\Œ+ñâ\ÒAg∏˛Ç€∑W8µ_ª®^I&ß'),(1,'DevicesDetection_browserVersions',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúMå1Ä E\Ô\“*¢\Úª3zLH\ÿ	w\◊*\Zá¶\ÕØ?ÇQåD\ÿ\˜\®î\„~díÇÇ∞\ıÉ!I\‡>c\ﬂ\ˆR\ƒ ¨-Iò:tºÁü∏|yS1¬†6\Ì⁄§µ\—\'\„'),(1,'DevicesDetection_models',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨ã≠-¨î¨\”S\ÛRã2ìRRã≥K\Úî¨3≠°\ÿJÉT[)Ç\‰å-≠A\ÊeZô@%M!í I3$Ö\Êp\ÒZê\¬D+´\ÍZêY~÷µµ\0ôª-'),(1,'DevicesDetection_os',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨ãÅ2Jæé\ŒJ÷ôVÜPl•çÅ≤ÜVJÜ 9cKkê˛L+®§)D\“\0$iÜ§\–.^Ròhe`U]2\Àœ∫∂\0.ç&\Ì'),(1,'DevicesDetection_osVersions',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúMåA\nÄ0ˇíHc≠\“\ÕI<\Î*x(\Ù\÷c\È\ﬂm∞äá∞ag\ÿ\0Fâ0`\ﬂ«£d8P\n\ÁïHr+h_7a3∞#â\‡~cO\€±2\ÎEW\"¶\›ç\¬˘\'.__U0(U∑©\ı¯}(#'),(1,'DevicesDetection_types',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨AÇôVÜPl•ç≠ãÅZïA\Ú∆ñPE&PISà§H\“I°9\\º§0\—\ ¿™∫dñüum-\0]é%ë'),(1,'Goals_ItemsCategory',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Goals_ItemsCategory_Cart',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Goals_ItemsName',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Goals_ItemsName_Cart',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Goals_ItemsSku',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Goals_ItemsSku_Cart',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Referrers_keywordByCampaign',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Referrers_keywordBySearchEngine',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Referrers_searchEngineByKeyword',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Referrers_type',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨3≠ë∞î6Ü—ñ\÷ ]ôV&PS(\ﬂ\ 7\ÛkAúD+´\ÍZê^?\Î\⁄Z\0[\"Æ'),(1,'Referrers_urlByAIAssistant',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Referrers_urlBySocialNetwork',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Referrers_urlByWebsite',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'Resolution_configuration',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúMå=\nÄ0F\Ô\“4≠Z˚e¡M\ÔP¡°\‡\÷E(ΩªF´8Ñ¸ºó/Äê#4\ÿw\\»	-\‘\÷mWú@\◊2#Oì\È\ı\·åVAµL\ÌVT(f=KXDSa˚¿˚±˚â\Óª4rë¨ÖK9\÷)˛'),(1,'Resolution_resolution',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúMåAÄ ˇ\“PÅ\Ì¸&H∏q1!¸]P4ö6;”ç`\‘%\Ê=jÅ\Â∏ô§¿ÉX{u:≠Hxéû\€tÖª2ò	2Jñ	\Ì\Ô\«\ı\'∫/oCåP®mtm\“\⁄\€<\'˝'),(1,'UserCountry_city',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúMå¡\rÄ0w\…\r•†:;∞CêxT\ÍØ\œ*ª”àÇxX±|éå^D_ì\—®\ÍyUíÜ\0\")\‡©e\ﬁ8É\ÿY\Ã\‚\œ\ÎÑ\ÈÅ¡\·\ˆ+\Ó_n^\‘1\ﬁÕ∑1ªµ\Œ&'),(1,'UserCountry_country',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúM\Ã\Õ\rÄ0\‡]ò†¥˛§è\‹Mzk<5\ÏÆ\ƒj<\ﬂ£Q§w\»\Ë\r3®\Í~TíÜ:Ièä£ß\ƒn)ãüL\ÁÉ\„\ÚÆ\ﬂ\ﬁ<®\Ë\Êø61ª\0+|\''),(1,'UserCountry_region',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúMå¡\rÄ0w\…\r•†:;∞CêxT\ÍØ\œ*ª”àÇxX±|éå^D_ì\—®\ÍyUíÜ\0\")\‡©e\ﬁ8É\ÿY\Ã\‚\œ\ÎÑ\ÈÅ¡\·\ˆ+\Ó_n^\‘1\ﬁÕ∑1ªµ\Œ&'),(1,'UserId_users',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(1,'UserLanguage_language',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨¡\Ï\‘<\›\“b%\ÎL+C(6Ç\“\∆@yC+%Cêú±•5»ÑL+®§)D\“\0$iÜ§\–.^Ròhe`U]2\Àœ∫∂\0π~('),(1,'VisitorInterest_daysSinceLastVisit',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúç\”=!\‡ˇ\"t\„\«5n]∫\›ÿµXpéµ\–\·∏ˇ^;thç€ãí	Øâ\—\ÒZX\«ƒ¥\√ke\«jI∑º®X´sæ\ÁGZÆs~]J-œ™ba\ÛπdÖ*nÖ±çj^[¢8\ÔˇQb•A)˙∑b$eÖ$≈Äë+)$+NR,XY\Òí\‚¿\…Jê^V&I	d\Â\ÿU,´	p`1\ÿ/s\À\ËÄöá˝∑L~\Íwÿ∑-∑õ©\ﬂ\„\ˆO\— êYSø\Ã\ÌQ\‰\›¡ú$i{\ı\Û/Ñ'),(1,'VisitorInterest_pageGap',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúç\—1\n\√0–ª:\n,\ŸNRi\Àz:≤eπ{µ:ˇl_∂¸r3IvtK\ﬁ,_A\Ìÿ≠\Zm\Ì˝\Ÿ\»\˜∏!a!\Ô¶QIT\‰g7â\ﬁx)˚\Î:*\ ˙£§ˇä\"%s\∆JFJ·ÇïÇî\ +)\œXôÜJ1ZXf\Ê!Y\‚Øo¨fÅNeΩ1\œ9*]ës~\ˆÜ≈Ä'),(1,'VisitorInterest_timeGap',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúç\–1\n\√0–ª:\n$\Ÿqú\Ô-\ËR\Ë»ñ1\‰\Ó\’\Ë\–\∆⁄æå\Ù∞¥@\«\ni\“«é¥-Ø\˜FmG	´P[a^*H©ù+‘õ}\‹Sj\œ\Î\·?\„Yï”∑#ø\Î9Iπút\ÎP\ÒΩ,\0\Â[h\Ù\≈L\ÿr@\Zzí+ú#*=\…øR@\Z{í+<E§z+Uê+¨5BM›ìW—á\Õ=\È¸\0Ça ô'),(1,'VisitorInterest_visitsByVisitCount',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúç\”;\n\√0\‡ª:\n$˘ï\»[\–;∏\–¡ê-£\…›´%–°H\ﬁ~?¯∞eπ%ôC∞uâw`ôßd	Gé\–N]	\⁄\÷\È(¥k\È^î©)∂\◊=a*¸£\‡Ö=%B\Ùï\Ë)	íØ$O…ê}%{JÅ\‚+\≈S*T_©û≤¡\Ê+õ©$	;\–Bywì\—Lx°¿d\˜Øf.êq≤[∏\ËÉ\ÎO¿\…n\„™wC^¢\Ï^\÷C1“Éüût}Z[Å'),(1,'VisitTime_localTime',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúµ\÷;É0Ñ\·ª¯Ãöóó;\‰éîâéq\˜b\'Rî\’Tkô\«O\ı\·\Ï\÷˙6{3eèuë|[Ω\Û∞\‰˚c	”±9; ¥2cù©,\⁄2ª2˚2ás\Ó\«≤7æ\Ì«≥∑∫\Ò?\nM\‘h\‘4\—H£Qmi¥\’D;\Z\Ì4—ûF{Mt†\—Ait\‘Dç&Mú$®L∫@I§8KπD2Å\”ëM\‡8°\ÍÑ\È\Û#à\”\Í\Ä\ù∆ô>/6/e>7\Ô˝üü¡πÇ\»+p∞ ú,à\ÃG\"µå´e\"µå´e™≥\‘\≈aJ§ñqµL¢\÷˛´F'),(1,'VisitTime_serverTime',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúµ\÷;É0Ñ\·ª¯Ãöóó;\‰éîâéq\˜b\'Rî\’Tkô\«O\ı\·\Ï\÷˙6{3eèuë|[Ω\Û∞\‰˚c	”±9; ¥2cù©,\⁄2ª2˚2ás\Ó\«≤7æ\Ì«≥∑∫\Ò?\nM\‘h\‘4\—H£Qmi¥\’D;\Z\Ì4—ûF{Mt†\—Ait\‘Dç&Mú$®L∫@I§8KπD2Å\”ëM\‡8°\ÍÑ\È\Û#à\”\Í\Ä\ù∆ô>/6/e>7\Ô˝üü¡πÇ\»+p∞ ú,à\ÃG\"µå´e\"µå´e™≥\‘\≈aJ§ñqµL¢\÷˛´F'),(4,'Actions_actions',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúçîMn\√ ÖØqÄäü\ÿi\≤\ÈÆD\Z£\⁄`\⁄Tär\˜Ç\Ì!\ƒu\⁄.0#\Ê1\Ôìêú\ãÊ∏íúA∞\∆¸\‚x¡Q#\˜™Aï\„Ñp¥zµv\ı¢d®Q•9\rÉƒëV\≈\Ìö3\\«Ä¿\n≠vqba\n\≈Jé\‹G+ºnï0 ümˇé\‚ñ\'LÀêß¡\Ÿ\ÏE≠Ωg\Ì\Îô0∫çEZmf9\«\√\ÚP#…Ø?DEÜ\„Tˇ©˙â&\ö\ı\r\Ë&ò\"ÉÅ\ÿ0ñl\À#\Õ&C\ÒΩ4\Ó\r`(\›Fòr	Ê¶úp6\Œ-9ôÖJ\…,=TQñ!m+∫\ﬁîs⁄ú\‡Ã¢%£K`s˝àK&ºπ$I\ˆ	\Ú\⁄;‘ÉmªFymÕÄ˙+fÆ’É\ˆf.\Ÿ-±\Õwçnçh¨<\…rì\'—àp\◊\‰)∑õwvñ	x;\›Gä!ÄkH\”U-  <CP¡5~d|\∆\Œ\Ì\‰)4â\ˆçù\Ù\ı\–?ò£¸I[\‚˝æ^ø˛ie¯'),(4,'Actions_actions_url',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúçîmrÉ Ü\Ô\¬¢@4\Õzá\\¡!ëV¶\n \”L\Ó^P!ƒö∂?ê\˜e\ﬂg`ÅÜõÄºb@C∞\Œ\·f†\0‘±=\ÔPe†î	\Ÿ\+™7∞1†ï_(Ä\ÊU38¸!\’\ŒO\‘M∞´cN}mE\œk\…\ÌE\ÈO‰ó¨rR∫<qûr_∑¬ö˙\"l;z∑±H/\‰,70urD\Ï˙á®Hp\◊gÆ\'\Z\«\Îh\÷K4A7¡	LHJ£Mdy•\Ÿ$(V3i\ﬁ![S.¡<î\Œ&¡y$\'3W)öE†ó*B§F\ı\ıQ´7F»èpfﬁíí%∞π~\ƒ\Û%#\ﬁ\\G˚˘\Ì\ÍA\ı«é[°\‰Ä˙+f™É\ˆf*\Ÿ-±\ÕOçÆd\›)\÷í\Â&è¢\·©\…cn7\Ô\Ï$\„vx;\›Gíá \\CØjÇ∑îCp\˜\Ê_∑iÄNzx\0\Pk\Ì\—@ñ\Œ\Ù°]})ï!/\˜w˚~ˇ\›bå'),(4,'Actions_downloads',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Actions_outlink',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Actions_sitesearch',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Actions_SiteSearchCategories',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Contents_name_piece',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Contents_piece_name',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'DevicePlugins_plugin',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xú}\–AÇ0Ö\·ª\‰Ö\"\Í\ÎºCÑ\"ë\"H\∆a∏ª∏`ßY$\ÛO\ﬂ\"åÅqªGä%\‚\0\n|\ıÅ\\D*∫ÆONênì∏\ıª\ÀV\÷]\ˆ\√d\Î*p¨w\√¸4R\’\»@wûX\'¨JXP_V∫ê©\¬\Ù|I—å\“z\›9®Nb@É\Á\–~˚Aór]J@Q\¬\‰á ∑z‘©£N•†Ye7\«÷ó¢æz˝\0Zƒ¨m'),(4,'DevicesDetection_brands',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨ã≠å¨îî¨3≠åÄ\ÿàç°¥	î6µ\ÈÃ¥2É\ÚÕ°|CCòB∞H-àóhe`U]2\ƒœ∫∂\0\Í#\Ò'),(4,'DevicesDetection_browserEngines',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨¡l\˜\‘\‰\Ï|%\ÎL+# 6bc(m•M≠Aö3≠Ã†|s(\ﬂ\–¶\–\0,R\‚%ZXU◊ÇÒ≥Æ≠\0≥%L'),(4,'DevicesDetection_browsers',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xú5å;¿ C\Ôí\ËGuv\∆\ﬁ!ï: ±1¢‹ΩPÖ¡≤_[¡\ËAiÖΩaU}\ﬁJ\“A9ì\ƒ!J\Óõ˚.≥Yp8ü\Œ\Ã\Î1¸õ§\Ë6Gn1˚\07#\Ï'),(4,'DevicesDetection_browserVersions',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xú5å¡Ä CˇÖ0õàJw\˜\Ë?\Ã\ƒ	7édˇ.84\Ì[\÷*5ÅD\·gà®.\Î\Ûf\'\'\‹u	˚∏êìÑµâõ¸\mxê\ﬁO\ÿÉô\Á#˝\Î§ T\Î#∑ò}\Ã%('),(4,'DevicesDetection_models',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xú5å\Õ	Ä0ÉWëN\–\Áøy\'W®Z§(*\÷[\È\Ó∂R!˘Bà¡HV(˛\–¡YTªö\Ù.ÿÇZà~\‰U˙6s∂hª=\Á%\ÿ ¢†\"yôº\‚xeP\'n˝C˘5>íÇÑ\Û\Òd`\Ô_G7*Z'),(4,'DevicesDetection_os',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨ãÅ2Jæé\ŒJ÷ôVF@l\ƒ\∆P\⁄JõZÉ¥fZôA˘\ÊPæ°!L°X§\ƒK¥2∞™Æ\‚g][\08a$2'),(4,'DevicesDetection_osVersions',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xú5å±\nÄ0Cˇ\Â>@\Ó¨U\ÃM\‚¨ˇP¡°–≠c\Èø\€\ u\…!Ç¡\Z\‡F\ÿQ2<(Ö\ÁM§πtß\nO\‚I#\Ê&irÊãπ\◊~±\Zo\∆\"c\»S;0J\Ì\'∑\÷˙\\'%h'),(4,'DevicesDetection_types',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨AÇôVF@l\ƒ\∆P\⁄JõB\ÂÕ†|s(\ﬂ\–¶\–\0,R\‚%ZXU◊ÇÒ≥Æ≠\0{\∆\"\÷'),(4,'Events_action_category',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Events_action_name',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Events_category_action',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Events_category_name',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Events_name_action',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Events_name_category',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Goals_ItemsCategory',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Goals_ItemsCategory_Cart',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Goals_ItemsName',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Goals_ItemsName_Cart',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Goals_ItemsSku',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Goals_ItemsSku_Cart',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Referrers_keywordByCampaign',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Referrers_keywordBySearchEngine',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Referrers_searchEngineByKeyword',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Referrers_type',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨3≠Å\ÿJCi(mj\r“îie\ÂõC˘ÜÜ0Ö`ëZ/\—\ ¿™∫dàüum-\0|\"\◊'),(4,'Referrers_urlByAIAssistant',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Referrers_urlBySocialNetwork',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Referrers_urlByWebsite',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'Resolution_configuration',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xú5åA\nÄ D\Ô\‚	˛\◊ öøä¿]\›¡†Ö\‡\ŒM \ﬁ=\r]3o∆ÉëH<\Ãr\¬˝˝D%	\\\·\‹qNXØ\ÙZMJtWô\ÓS\˜Y\⁄O¿\“\ŸvfC˙õ\“»ÉêK;π§î¯ú\'C'),(4,'Resolution_resolution',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xú5å¡\r¿ w\…	¥Ö:;t*\ıÅƒèO%î\›<,˚¢\ÿ	Çñ¡ö\‡W8\—*vPI\˜SH+\"H\\\‰78&\Õp]\“\Âßo\”w˝åcrò,≤˘øÿ†F≥1r©\Ÿ\’ %B'),(4,'UserCountry_city',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨ã≠¨îî¨3≠åÄ\ÿàç°¥	î6µ\ÈÀ¥2É\ÚÕ°|CCòB∞H-àó4≠∫dàüum-\0\Ã#^'),(4,'UserCountry_country',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xú5å¡\r¿ w\…J´:;táT\Íâ\Íe\˜Bñ}Ql£Q§N\ÙÜ™z?ï§!Ç\ﬁFRáx(πo\ÓYf≥`w>úô\◊c¯/6I\–mé\\b\ˆ4$H'),(4,'UserCountry_region',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨ã≠¨îî¨3≠åÄ\ÿàç°¥	î6µ\ÈÀ¥2É\ÚÕ°|CCòB∞H-àó4≠∫dàüum-\0\Ã#^'),(4,'UserId_users',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2∞™Æ\0O˛'),(4,'UserLanguage_language',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨¡\Ï\‘<\›\“b%\ÎL+# 6bc(m•M≠Aö3≠Ã†|s(\ﬂ\–¶\–\0,R\‚%ZXU◊ÇÒ≥Æ≠\0≤\€%K'),(4,'VisitorInterest_daysSinceLastVisit',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúÖ\”=1\‡ˇRp4M?4\›\\\‹ntï\n\náÉ\'8\˜ﬂç\√mö-/Jx\€ØÉ}mL{º.ú\ÿ\Õ\Ì\ﬁgW\∆\¬\Ó\“˝\Ÿ\Ê\€\‘\ﬂ◊±å\◊\‚\Í\‡ \Î\ˆΩ\Z{^%Qù\ˆ¡ê\ÿy\ª\‡\n¡P\»]àñ@@∫ê,!B‘Öl		í.K»êu\·h	ä.úT!≤;\Zã@Ω§í1≠BΩòí	![à\ﬁ\Õ,ïrK\—˚)ek-zI\Â1î\”!ú5e˚\0\÷\–$≠'),(4,'VisitorInterest_pageGap',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúÖ—±\n\ƒ0\‡w:\n\—ƒ∂ß[\‡\ﬁ!\n\›:ñæ˚yC∂C√èíèªR\—˚\–b]\Î¨\˜•¢p\ˆ\œ~Ç]>B;îΩ»û\ﬂ\—\’oz™\ˆçP`\‰!îøgB\≈\Z5\Z∂Xhô (± ô0\„s(4Ö©\ƒ\ƒû\…\˜ô|≈ö\ZÇúº\„ïLoë\Ò|\‘0æF'),(4,'VisitorInterest_timeGap',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúÖ\–1\n\√0–ª:\n$\Ÿqú\Ô≠\Ë\\\Ë»ñ1\‰\ÓUátj≠¡\‚#\–\√Rá\né\“:\“«é	¥\ı\Ák£∂#ÉÑU®≠0\⁄\ŒO\È\QO©=Æ\∆¬≥*ßØ!?\rãå§\\#\rç*æãH\"≥/c¬ñeä8G)ë\‚Ç_%P\ÊHqÅóH©C•Ç\\`≠≥ÑÁ≠¢7ªèî\Û\rú\„\√_'),(4,'VisitorInterest_visitsByVisitCount',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúÖ\“=\n\√0\‡ª:\n$˘/ë∑†wp°C [∆êªW≤ïß¡\Êa√á\ﬁ4)vn\∆cZæÉ\⁄yXµ¥\œ\˜gO\„\ù$$il¶>d\\øi\Z\€\È)è◊Ω\0%Ω˛+h$d\ X»ëP®`°DB•äÖ\Z	ç\ZZ$t\ÍXËë∞–ÇÖ\n\≈\“J<\Â\n	\œRIÉ\«\‹K\œ⁄®rÄ\‡j6ˇTo7G\nÆg\˜˚∞êÜ\Ó®FY˙D\ \ı\˜@c'),(4,'VisitTime_localTime',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúµ\÷;É0Ñ\·ªpfm\ÛX\Óê;Äîâ.%\‚\ÓÅh\› e®¶Zke˘\Ô>yvÀæØ\ﬁN≥ßz}ˇx\Òfõó\˜\÷L\◊ruãôb\Êò%f≥è	‘ã\Ì\Ôpú´\Û\Ì\÷\˜\„z\‰Uˇ´UçVMTM¥öD\’L´YT-¥ZD’éV;Qµß\’^ThuUGZEUpú \”\ÈÅ\'ïO\‡@A%8QPéTJÅ3Ö\Í¢ã\Ë\‚\÷≈Ωãá.á\n*©¿©Ç\ *p¨†\“\nú+®º2Óï©º2\Óï\…˛S*ïW∆Ω2çW\«JN:'),(4,'VisitTime_serverTime',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',_binary 'xúµ\÷;É0Ñ\·ªpfm\ÛX\Óê;Äîâ.%\‚\ÓÅh\› e®¶Zke˘\Ô>yvÀæØ\ﬁN≥ßz}ˇx\Òfõó\˜\÷L\◊ruãôb\Êò%f≥è	‘ã\Ì\Ôpú´\Û\Ì\÷\˜\„z\‰Uˇ´UçVMTM¥öD\’L´YT-¥ZD’éV;Qµß\’^ThuUGZEUpú \”\ÈÅ\'ïO\‡@A%8QPéTJÅ3Ö\Í¢ã\Ë\‚\÷≈Ωãá.á\n*©¿©Ç\ *p¨†\“\nú+®º2Óï©º2\Óï\…˛S*ïW∆Ω2çW\«JN:'),(5,'Actions_actions',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúçîMn\√ ÖØqÄäü\ÿi\≤\ÈÆD\Z£\⁄`\⁄Tär\˜Ç\Ì!\ƒu\⁄.0#\Ê1\Ôìêú\ãÊ∏íúA∞\∆¸\‚x¡Q#\˜™Aï\„Ñp¥zµv\ı¢d®Q•9\rÉƒëV\≈\Ìö3\\«Ä¿\n≠vqba\n\≈Jé\‹G+ºnï0 ümˇé\‚ñ\'LÀêß¡\Ÿ\ÏE≠Ωg\Ì\Îô0∫çEZmf9\«\√\ÚP#…Ø?DEÜ\„Tˇ©˙â&\ö\ı\r\Ë&ò\"ÉÅ\ÿ0ñl\À#\Õ&C\ÒΩ4\Ó\r`(\›Fòr	Ê¶úp6\Œ-9ôÖJ\…,=TQñ!m+∫\ﬁîs⁄ú\‡Ã¢%£K`s˝àK&ºπ$I\ˆ	\Ú\⁄;‘ÉmªFymÕÄ˙+fÆ’É\ˆf.\Ÿ-±\Õwçnçh¨<\…rì\'—àp\◊\‰)∑õwvñ	x;\›Gä!ÄkH\”U-  <CP¡5~d|\∆\Œ\Ì\‰)4â\ˆçù\Ù\ı\–?ò£¸I[\‚˝æ^ø˛ie¯'),(5,'Actions_actions_url',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúçîmrÉ Ü\Ô\¬¢@4\Õzá\\¡!ëV¶\n \”L\Ó^P!ƒö∂?ê\˜e\ﬂg`ÅÜõÄºb@C∞\Œ\·f†\0‘±=\ÔPe†î	\Ÿ\+™7∞1†ï_(Ä\ÊU38¸!\’\ŒO\‘M∞´cN}mE\œk\…\ÌE\ÈO‰ó¨rR∫<qûr_∑¬ö˙\"l;z∑±H/\‰,70urD\Ï˙á®Hp\◊gÆ\'\Z\«\Îh\÷K4A7¡	LHJ£Mdy•\Ÿ$(V3i\ﬁ![S.¡<î\Œ&¡y$\'3W)öE†ó*B§F\ı\ıQ´7F»èpfﬁíí%∞π~\ƒ\Û%#\ﬁ\\G˚˘\Ì\ÍA\ı«é[°\‰Ä˙+f™É\ˆf*\Ÿ-±\ÕOçÆd\›)\÷í\Â&è¢\·©\…cn7\Ô\Ï$\„vx;\›Gíá \\CØjÇ∑îCp\˜\Ê_∑iÄNzx\0\Pk\Ì\—@ñ\Œ\Ù°]})ï!/\˜w˚~ˇ\›bå'),(5,'Actions_downloads',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Actions_outlink',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Actions_sitesearch',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Actions_SiteSearchCategories',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Contents_name_piece',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Contents_piece_name',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'DevicePlugins_plugin',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xú}\–AÇ0Ö\·ª\‰Ö\"\Í\ÎºCÑ\"ë\"H\∆a∏ª∏`ßY$\ÛO\ﬂ\"åÅqªGä%\‚\0\n|\ıÅ\\D*∫ÆONênì∏\ıª\ÀV\÷]\ˆ\√d\Î*p¨w\√¸4R\’\»@wûX\'¨JXP_V∫ê©\¬\Ù|I—å\“z\›9®Nb@É\Á\–~˚Aór]J@Q\¬\‰á ∑z‘©£N•†Ye7\«÷ó¢æz˝\0Zƒ¨m'),(5,'DevicesDetection_brands',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨ã≠å¨îî¨3≠åÄ\ÿàç°¥	î6µ\ÈÃ¥2É\ÚÕ°|CCòB∞H-àóhe`U]2\ƒœ∫∂\0\Í#\Ò'),(5,'DevicesDetection_browserEngines',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨¡l\˜\‘\‰\Ï|%\ÎL+# 6bc(m•M≠Aö3≠Ã†|s(\ﬂ\–¶\–\0,R\‚%ZXU◊ÇÒ≥Æ≠\0≥%L'),(5,'DevicesDetection_browsers',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xú5å;¿ C\Ôí\ËGuv\∆\ﬁ!ï: ±1¢‹ΩPÖ¡≤_[¡\ËAiÖΩaU}\ﬁJ\“A9ì\ƒ!J\Óõ˚.≥Yp8ü\Œ\Ã\Î1¸õ§\Ë6Gn1˚\07#\Ï'),(5,'DevicesDetection_browserVersions',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xú5å¡Ä CˇÖ0õàJw\˜\Ë?\Ã\ƒ	7édˇ.84\Ì[\÷*5ÅD\·gà®.\Î\Ûf\'\'\‹u	˚∏êìÑµâõ¸\mxê\ﬁO\ÿÉô\Á#˝\Î§ T\Î#∑ò}\Ã%('),(5,'DevicesDetection_models',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xú5å\Õ	Ä0ÉWëN\–\Áøy\'W®Z§(*\÷[\È\Ó∂R!˘Bà¡HV(˛\–¡YTªö\Ù.ÿÇZà~\‰U˙6s∂hª=\Á%\ÿ ¢†\"yôº\‚xeP\'n˝C˘5>íÇÑ\Û\Òd`\Ô_G7*Z'),(5,'DevicesDetection_os',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨ãÅ2Jæé\ŒJ÷ôVF@l\ƒ\∆P\⁄JõZÉ¥fZôA˘\ÊPæ°!L°X§\ƒK¥2∞™Æ\‚g][\08a$2'),(5,'DevicesDetection_osVersions',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xú5å±\nÄ0Cˇ\Â>@\Ó¨U\ÃM\‚¨ˇP¡°–≠c\Èø\€\ u\…!Ç¡\Z\‡F\ÿQ2<(Ö\ÁM§πtß\nO\‚I#\Ê&irÊãπ\◊~±\Zo\∆\"c\»S;0J\Ì\'∑\÷˙\\'%h'),(5,'DevicesDetection_types',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨AÇôVF@l\ƒ\∆P\⁄JõB\ÂÕ†|s(\ﬂ\–¶\–\0,R\‚%ZXU◊ÇÒ≥Æ≠\0{\∆\"\÷'),(5,'Events_action_category',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Events_action_name',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Events_category_action',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Events_category_name',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Events_name_action',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Events_name_category',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Goals_ItemsCategory',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Goals_ItemsCategory_Cart',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Goals_ItemsName',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Goals_ItemsName_Cart',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Goals_ItemsSku',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Goals_ItemsSku_Cart',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Referrers_keywordByCampaign',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Referrers_keywordBySearchEngine',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Referrers_searchEngineByKeyword',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Referrers_type',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨3≠Å\ÿJCi(mj\r“îie\ÂõC˘ÜÜ0Ö`ëZ/\—\ ¿™∫dàüum-\0|\"\◊'),(5,'Referrers_urlByAIAssistant',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Referrers_urlBySocialNetwork',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Referrers_urlByWebsite',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'Resolution_configuration',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xú5åA\nÄ D\Ô\‚	˛\◊ öøä¿]\›¡†Ö\‡\ŒM \ﬁ=\r]3o∆ÉëH<\Ãr\¬˝˝D%	\\\·\‹qNXØ\ÙZMJtWô\ÓS\˜Y\⁄O¿\“\ŸvfC˙õ\“»ÉêK;π§î¯ú\'C'),(5,'Resolution_resolution',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xú5å¡\r¿ w\…	¥Ö:;t*\ıÅƒèO%î\›<,˚¢\ÿ	Çñ¡ö\‡W8\—*vPI\˜SH+\"H\\\‰78&\Õp]\“\Âßo\”w˝åcrò,≤˘øÿ†F≥1r©\Ÿ\’ %B'),(5,'UserCountry_city',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨ã≠¨îî¨3≠åÄ\ÿàç°¥	î6µ\ÈÀ¥2É\ÚÕ°|CCòB∞H-àó4≠∫dàüum-\0\Ã#^'),(5,'UserCountry_country',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xú5å¡\r¿ w\…J´:;táT\Íâ\Íe\˜Bñ}Ql£Q§N\ÙÜ™z?ï§!Ç\ﬁFRáx(πo\ÓYf≥`w>úô\◊c¯/6I\–mé\\b\ˆ4$H'),(5,'UserCountry_region',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨ã≠¨îî¨3≠åÄ\ÿàç°¥	î6µ\ÈÀ¥2É\ÚÕ°|CCòB∞H-àó4≠∫dàüum-\0\Ã#^'),(5,'UserId_users',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(5,'UserLanguage_language',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúK¥2¥™Œ¥2∞N¥2Ü1,≠™ã≠L≠îrìRsî¨¡\Ï\‘<\›\“b%\ÎL+# 6bc(m•M≠Aö3≠Ã†|s(\ﬂ\–¶\–\0,R\‚%ZXU◊ÇÒ≥Æ≠\0≤\€%K'),(5,'VisitorInterest_daysSinceLastVisit',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúÖ\”=1\‡ˇRp4M?4\›\\\‹ntï\n\náÉ\'8\˜ﬂç\√mö-/Jx\€ØÉ}mL{º.ú\ÿ\Õ\Ì\ﬁgW\∆\¬\Ó\“˝\Ÿ\Ê\€\‘\ﬂ◊±å\◊\‚\Í\‡ \Î\ˆΩ\Z{^%Qù\ˆ¡ê\ÿy\ª\‡\n¡P\»]àñ@@∫ê,!B‘Öl		í.K»êu\·h	ä.úT!≤;\Zã@Ω§í1≠BΩòí	![à\ﬁ\Õ,ïrK\—˚)ek-zI\Â1î\”!ú5e˚\0\÷\–$≠'),(5,'VisitorInterest_pageGap',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúÖ—±\n\ƒ0\‡w:\n\—ƒ∂ß[\‡\ﬁ!\n\›:ñæ˚yC∂C√èíèªR\—˚\–b]\Î¨\˜•¢p\ˆ\œ~Ç]>B;îΩ»û\ﬂ\—\’oz™\ˆçP`\‰!îøgB\≈\Z5\Z∂Xhô (± ô0\„s(4Ö©\ƒ\ƒû\…\˜ô|≈ö\ZÇúº\„ïLoë\Ò|\‘0æF'),(5,'VisitorInterest_timeGap',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúÖ\–1\n\√0–ª:\n$\Ÿqú\Ô≠\Ë\\\Ë»ñ1\‰\ÓUátj≠¡\‚#\–\√Rá\né\“:\“«é	¥\ı\Ák£∂#ÉÑU®≠0\⁄\ŒO\È\QO©=Æ\∆¬≥*ßØ!?\rãå§\\#\rç*æãH\"≥/c¬ñeä8G)ë\‚Ç_%P\ÊHqÅóH©C•Ç\\`≠≥ÑÁ≠¢7ªèî\Û\rú\„\√_'),(5,'VisitorInterest_visitsByVisitCount',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúÖ\“=\n\√0\‡ª:\n$˘/ë∑†wp°C [∆êªW≤ïß¡\Êa√á\ﬁ4)vn\∆cZæÉ\⁄yXµ¥\œ\˜gO\„\ù$$il¶>d\\øi\Z\€\È)è◊Ω\0%Ω˛+h$d\ X»ëP®`°DB•äÖ\Z	ç\ZZ$t\ÍXËë∞–ÇÖ\n\≈\“J<\Â\n	\œRIÉ\«\‹K\œ⁄®rÄ\‡j6ˇTo7G\nÆg\˜˚∞êÜ\Ó®FY˙D\ \ı\˜@c'),(5,'VisitTime_localTime',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúµ\÷;É0Ñ\·ªpfm\ÛX\Óê;Äîâ.%\‚\ÓÅh\› e®¶Zke˘\Ô>yvÀæØ\ﬁN≥ßz}ˇx\Òfõó\˜\÷L\◊ruãôb\Êò%f≥è	‘ã\Ì\Ôpú´\Û\Ì\÷\˜\„z\‰Uˇ´UçVMTM¥öD\’L´YT-¥ZD’éV;Qµß\’^ThuUGZEUpú \”\ÈÅ\'ïO\‡@A%8QPéTJÅ3Ö\Í¢ã\Ë\‚\÷≈Ωãá.á\n*©¿©Ç\ *p¨†\“\nú+®º2Óï©º2\Óï\…˛S*ïW∆Ω2çW\«JN:'),(5,'VisitTime_serverTime',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',_binary 'xúµ\÷;É0Ñ\·ªpfm\ÛX\Óê;Äîâ.%\‚\ÓÅh\› e®¶Zke˘\Ô>yvÀæØ\ﬁN≥ßz}ˇx\Òfõó\˜\÷L\◊ruãôb\Êò%f≥è	‘ã\Ì\Ôpú´\Û\Ì\÷\˜\„z\‰Uˇ´UçVMTM¥öD\’L´YT-¥ZD’éV;Qµß\’^ThuUGZEUpú \”\ÈÅ\'ïO\‡@A%8QPéTJÅ3Ö\Í¢ã\Ë\‚\÷≈Ωãá.á\n*©¿©Ç\ *p¨†\“\nú+®º2Óï©º2\Óï\…˛S*ïW∆Ω2çW\«JN:'),(6,'Goals_ItemsCategory',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(6,'Goals_ItemsCategory_Cart',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(6,'Goals_ItemsName',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(6,'Goals_ItemsName_Cart',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(6,'Goals_ItemsSku',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛'),(6,'Goals_ItemsSku_Cart',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',_binary 'xúK¥2∞™Æ\0O˛');
/*!40000 ALTER TABLE `matomo_archive_blob_2025_11` ENABLE KEYS */;
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
INSERT INTO `matomo_archive_numeric_2025_11` VALUES (1,'Actions_hits',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'Actions_nb_downloads',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'Actions_nb_hits_with_time_generation',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'Actions_nb_keywords',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'Actions_nb_outlinks',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'Actions_nb_pageviews',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'Actions_nb_searches',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'Actions_nb_uniq_downloads',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'Actions_nb_uniq_outlinks',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'Actions_nb_uniq_pageviews',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'Actions_sum_time_generation',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'bounce_count',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'done',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'max_actions',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'nb_actions',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'nb_uniq_visitors',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'nb_users',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'nb_visits',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'nb_visits_converted',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'PagePerformance_domcompletion_hits',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'PagePerformance_domcompletion_time',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'PagePerformance_domprocessing_hits',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'PagePerformance_domprocessing_time',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',21),(1,'PagePerformance_network_hits',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'PagePerformance_network_time',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',26),(1,'PagePerformance_onload_hits',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'PagePerformance_onload_time',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'PagePerformance_pageload_hits',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'PagePerformance_pageload_time',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',309),(1,'PagePerformance_server_hits',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'PagePerformance_servery_time',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',33),(1,'PagePerformance_transfer_hits',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(1,'PagePerformance_transfer_time',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',229),(1,'Referrers_distinctAIAssistants',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'Referrers_distinctCampaigns',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'Referrers_distinctKeywords',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'Referrers_distinctSearchEngines',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'Referrers_distinctSocialNetworks',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'Referrers_distinctWebsites',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'Referrers_distinctWebsitesUrls',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'sum_visit_length',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(1,'UserCountry_distinctCountries',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(2,'bounce_count',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:05',1),(2,'done90a5a511e1974bca37613b6daec137ba.VisitsSummary',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:05',1),(2,'max_actions',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:05',1),(2,'nb_actions',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:05',1),(2,'nb_uniq_visitors',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:05',1),(2,'nb_users',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:05',0),(2,'nb_visits',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:05',1),(2,'nb_visits_converted',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:05',0),(2,'sum_visit_length',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:05',0),(3,'bounce_count',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(3,'donefea44bece172bc9696ae57c26888bf8a.VisitsSummary',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(3,'max_actions',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(3,'nb_actions',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(3,'nb_uniq_visitors',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(3,'nb_users',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(3,'nb_visits',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(3,'nb_visits_converted',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(3,'sum_visit_length',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',0),(4,'Actions_hits',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'Actions_nb_downloads',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'Actions_nb_hits_with_time_generation',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'Actions_nb_keywords',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'Actions_nb_outlinks',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'Actions_nb_pageviews',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'Actions_nb_searches',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'Actions_nb_uniq_downloads',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'Actions_nb_uniq_outlinks',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'Actions_nb_uniq_pageviews',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'Actions_sum_time_generation',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'bounce_count',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'done',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'max_actions',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'nb_actions',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'nb_uniq_visitors',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'nb_users',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'nb_visits',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'nb_visits_converted',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'PagePerformance_domcompletion_hits',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'PagePerformance_domcompletion_time',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'PagePerformance_domprocessing_hits',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'PagePerformance_domprocessing_time',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',21),(4,'PagePerformance_network_hits',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'PagePerformance_network_time',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',26),(4,'PagePerformance_onload_hits',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'PagePerformance_onload_time',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'PagePerformance_pageload_hits',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'PagePerformance_pageload_time',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',309),(4,'PagePerformance_server_hits',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'PagePerformance_servery_time',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',33),(4,'PagePerformance_transfer_hits',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(4,'PagePerformance_transfer_time',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',229),(4,'Referrers_distinctAIAssistants',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'Referrers_distinctCampaigns',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'Referrers_distinctKeywords',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'Referrers_distinctSearchEngines',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'Referrers_distinctSocialNetworks',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'Referrers_distinctWebsites',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'Referrers_distinctWebsitesUrls',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'sum_visit_length',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(4,'UserCountry_distinctCountries',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(5,'Actions_hits',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'Actions_nb_downloads',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'Actions_nb_hits_with_time_generation',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'Actions_nb_keywords',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'Actions_nb_outlinks',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'Actions_nb_pageviews',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'Actions_nb_searches',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'Actions_nb_uniq_downloads',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'Actions_nb_uniq_outlinks',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'Actions_nb_uniq_pageviews',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'Actions_sum_time_generation',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'bounce_count',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'done',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'max_actions',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'nb_actions',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'nb_uniq_visitors',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'nb_users',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'nb_visits',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'nb_visits_converted',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'PagePerformance_domcompletion_hits',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'PagePerformance_domcompletion_time',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'PagePerformance_domprocessing_hits',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'PagePerformance_domprocessing_time',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',21),(5,'PagePerformance_network_hits',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'PagePerformance_network_time',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',26),(5,'PagePerformance_onload_hits',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'PagePerformance_onload_time',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'PagePerformance_pageload_hits',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'PagePerformance_pageload_time',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',309),(5,'PagePerformance_server_hits',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'PagePerformance_servery_time',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',33),(5,'PagePerformance_transfer_hits',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(5,'PagePerformance_transfer_time',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',229),(5,'Referrers_distinctAIAssistants',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'Referrers_distinctCampaigns',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'Referrers_distinctKeywords',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'Referrers_distinctSearchEngines',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'Referrers_distinctSocialNetworks',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'Referrers_distinctWebsites',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'Referrers_distinctWebsitesUrls',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'sum_visit_length',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(5,'UserCountry_distinctCountries',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(6,'done90a5a511e1974bca37613b6daec137ba.Goals',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:06',1),(7,'bounce_count',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(7,'done90a5a511e1974bca37613b6daec137ba.VisitsSummary',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(7,'max_actions',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(7,'nb_actions',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(7,'nb_uniq_visitors',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(7,'nb_users',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(7,'nb_visits',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(7,'nb_visits_converted',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(7,'sum_visit_length',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(8,'bounce_count',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(8,'donefea44bece172bc9696ae57c26888bf8a.VisitsSummary',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',1),(8,'max_actions',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(8,'nb_actions',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(8,'nb_uniq_visitors',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(8,'nb_users',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(8,'nb_visits',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(8,'nb_visits_converted',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(8,'sum_visit_length',1,'2025-11-03','2025-11-09',2,'2025-11-04 14:54:06',0),(9,'donefea44bece172bc9696ae57c26888bf8a.Goals',1,'2025-11-04','2025-11-04',1,'2025-11-04 14:54:07',1),(10,'bounce_count',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(10,'done90a5a511e1974bca37613b6daec137ba.VisitsSummary',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(10,'max_actions',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(10,'nb_actions',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(10,'nb_uniq_visitors',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(10,'nb_users',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(10,'nb_visits',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(10,'nb_visits_converted',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(10,'sum_visit_length',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(11,'bounce_count',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(11,'donefea44bece172bc9696ae57c26888bf8a.VisitsSummary',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',1),(11,'max_actions',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(11,'nb_actions',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(11,'nb_uniq_visitors',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(11,'nb_users',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(11,'nb_visits',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(11,'nb_visits_converted',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0),(11,'sum_visit_length',1,'2025-11-01','2025-11-30',3,'2025-11-04 14:54:07',0);
/*!40000 ALTER TABLE `matomo_archive_numeric_2025_11` ENABLE KEYS */;
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
INSERT INTO `matomo_brute_force_log` VALUES (1,'172.20.250.4','2025-11-04 14:51:02','mysql_superuser');
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_changes`
--

LOCK TABLES `matomo_changes` WRITE;
/*!40000 ALTER TABLE `matomo_changes` DISABLE KEYS */;
INSERT INTO `matomo_changes` VALUES (1,'2025-11-04 14:51:06','TagManager','5.0.1','Now Supports Variables in Custom JavaScript','You can now reference existing variables within Custom JavaScript variables. This means less development hassle and more convenience. For instance, you can easily retrieve a custom variable from the currently clicked element using {{ClickElement}}.','Learn more','https://matomo.org/faq/tag-manager/how-do-i-use-variables-within-a-custom-javascript-variable/');
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_log_action`
--

LOCK TABLES `matomo_log_action` WRITE;
/*!40000 ALTER TABLE `matomo_log_action` DISABLE KEYS */;
INSERT INTO `matomo_log_action` VALUES (1,'Zoo Search',177128507,4,NULL),(2,'search.zoo/',2958132702,1,2);
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_log_link_visit_action`
--

LOCK TABLES `matomo_log_link_visit_action` WRITE;
/*!40000 ALTER TABLE `matomo_log_link_visit_action` DISABLE KEYS */;
INSERT INTO `matomo_log_link_visit_action` VALUES (1,1,_binary '3¨,¨.ª¸',1,0,0,NULL,1,'2025-11-04 14:53:07','i1fbER',1,2,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,21,26,NULL,33,229,NULL,NULL,NULL,NULL,NULL,NULL);
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_log_visit`
--

LOCK TABLES `matomo_log_visit` WRITE;
/*!40000 ALTER TABLE `matomo_log_visit` DISABLE KEYS */;
INSERT INTO `matomo_log_visit` VALUES (1,1,_binary '3¨,¨.ª¸','2025-11-04 14:53:07',_binary '1ç\Î˘€§Ÿî',_binary '¨\0\0',1,NULL,'2025-11-04 14:53:07',0,0,0,0,NULL,1,1,2,1,2,1,1,0,NULL,NULL,1,'','en-us','Gecko','FF','139.0',1,'AP','generic desktop',0,'MAC','10.15',0,'15:53:07',0,'1280x720',1,0,0,0,0,0,0,0,0,NULL,'us',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
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
INSERT INTO `matomo_option` VALUES ('AIAssistantDefinitions','YToxNzp7czoxNToieWl5YW4uYmFpZHUuY29tIjtzOjg6IkJhaWR1IEFJIjtzOjEyOiJhaS5iYWlkdS5jb20iO3M6ODoiQmFpZHUgQUkiO3M6MTE6ImNoYXRncHQuY29tIjtzOjc6IkNoYXRHUFQiO3M6MTU6ImNoYXQub3BlbmFpLmNvbSI7czo3OiJDaGF0R1BUIjtzOjE1OiJsYWJzLm9wZW5haS5jb20iO3M6NzoiQ2hhdEdQVCI7czo5OiJjbGF1ZGUuYWkiO3M6NjoiQ2xhdWRlIjtzOjIxOiJjb3BpbG90Lm1pY3Jvc29mdC5jb20iO3M6NzoiQ29waWxvdCI7czoxMDoiY2hhdGdsbS5jbiI7czo3OiJDaGF0R0xNIjtzOjE3OiJjaGF0LmRlZXBzZWVrLmNvbSI7czo4OiJEZWVwc2VlayI7czoxNzoiZ2VtaW5pLmdvb2dsZS5jb20iO3M6NjoiR2VtaW5pIjtzOjE1OiJiYXJkLmdvb2dsZS5jb20iO3M6NjoiR2VtaW5pIjtzOjg6Imdyb2suY29tIjtzOjQ6Ikdyb2siO3M6NzoiaWFzay5haSI7czo0OiJpQXNrIjtzOjE1OiJjaGF0Lm1pc3RyYWwuYWkiO3M6NzoiTGUgQ2hhdCI7czo3OiJtZXRhLmFpIjtzOjc6Ik1ldGEgQUkiO3M6MTM6InBlcnBsZXhpdHkuYWkiO3M6MTA6IlBlcnBsZXhpdHkiO3M6NzoieW91LmNvbSI7czozOiJZb3UiO30=',0),('CorePluginsAdmin.disableTagManagerTeaser','1',1),('Feedback.nextFeedbackReminder.mysql_superuser','2026-05-04',0),('fingerprint_salt_1_2025-11-02','{\"value\":\"lbvp326llrhbeuu4pvxxf8l4y07s3suj\",\"time\":1762267323}',0),('fingerprint_salt_1_2025-11-03','{\"value\":\"ncejfhx9wgc06x8rnbl0t0rryeor3xdd\",\"time\":1762267323}',0),('fingerprint_salt_1_2025-11-04','{\"value\":\"sk0p5vo909rmh1oc828253hrj1w0ehvp\",\"time\":1762267323}',0),('fingerprint_salt_1_2025-11-05','{\"value\":\"8gv19b4ziu8v4gfxrtjuxo70crgvkk25\",\"time\":1762267323}',0),('geoip2.autosetup','1',0),('geoip2.loc_db_url','https://download.db-ip.com/free/dbip-city-lite-2025-11.mmdb.gz',0),('geoip2.updater_last_run_time','1762214400',0),('geoip2.updater_period','month',0),('install_mail_sent','1',0),('install_version','5.5.1',0),('InvalidatedOldReports_DatesWebsiteIds','a:2:{i:0;s:7:\"2025_11\";i:1;s:7:\"2025_01\";}',0),('LastPluginActivation.TagManager','1762267866',0),('lastTrackerCronRun','1762267987',0),('MatomoUpdateHistory','5.5.1,',0),('MobileMessaging_DelegatedManagement','false',0),('piwikUrl','https://analytics.zoo/',1),('PrivacyManager.ipAnonymizerEnabled','1',0),('SitesManager_DefaultTimezone','Africa/Algiers',0),('SitesManagerHadTrafficInPast_1','1',0),('SocialDefinitions','YToyMTA6e3M6OToiYmFkb28uY29tIjtzOjU6IkJhZG9vIjtzOjg6ImJlYm8uY29tIjtzOjQ6IkJlYm8iO3M6MTI6ImJpbGliaWxpLmNvbSI7czo4OiJiaWxpYmlsaSI7czoxNToiYmxhY2twbGFuZXQuY29tIjtzOjExOiJCbGFja1BsYW5ldCI7czo4OiJic2t5LmFwcCI7czo3OiJCbHVlc2t5IjtzOjExOiJza3lmZWVkLmFwcCI7czo3OiJCbHVlc2t5IjtzOjExOiJidXp6bmV0LmNvbSI7czo3OiJCdXp6bmV0IjtzOjE0OiJjbGFzc21hdGVzLmNvbSI7czoxNDoiQ2xhc3NtYXRlcy5jb20iO3M6MTg6Imdsb2JhbC5jeXdvcmxkLmNvbSI7czo3OiJDeXdvcmxkIjtzOjEwOiJkb3V5aW4uY29tIjtzOjY6IkRvdXlpbiI7czo5OiJkb3V5dS5jb20iO3M6NToiRG91eXUiO3M6MTQ6ImdhaWFvbmxpbmUuY29tIjtzOjExOiJHYWlhIE9ubGluZSI7czo4OiJnZW5pLmNvbSI7czo4OiJHZW5pLmNvbSI7czoxMDoiZ2l0aHViLmNvbSI7czo2OiJHaXRIdWIiO3M6MTU6InBsdXMuZ29vZ2xlLmNvbSI7czo5OiJHb29nbGUlMkIiO3M6MTQ6InVybC5nb29nbGUuY29tIjtzOjk6Ikdvb2dsZSUyQiI7czoyODoiY29tLmdvb2dsZS5hbmRyb2lkLmFwcHMucGx1cyI7czo5OiJHb29nbGUlMkIiO3M6MTA6ImRvdWJhbi5jb20iO3M6NjoiRG91YmFuIjtzOjEyOiJkcmliYmJsZS5jb20iO3M6ODoiRHJpYmJibGUiO3M6MTI6ImZhY2Vib29rLmNvbSI7czo4OiJGYWNlYm9vayI7czo1OiJmYi5tZSI7czo4OiJGYWNlYm9vayI7czoxNDoibS5mYWNlYm9vay5jb20iO3M6ODoiRmFjZWJvb2siO3M6MTQ6ImwuZmFjZWJvb2suY29tIjtzOjg6IkZhY2Vib29rIjtzOjExOiJmZXRsaWZlLmNvbSI7czo3OiJGZXRsaWZlIjtzOjEwOiJmbGlja3IuY29tIjtzOjY6IkZsaWNrciI7czoxMjoiZmxpeHN0ZXIuY29tIjtzOjg6IkZsaXhzdGVyIjtzOjExOiJmb3RvbG9nLmNvbSI7czo3OiJGb3RvbG9nIjtzOjE0OiJmb3Vyc3F1YXJlLmNvbSI7czoxMDoiRm91cnNxdWFyZSI7czoxOToiZnJpZW5kc3JldW5pdGVkLmNvbSI7czoxNjoiRnJpZW5kcyBSZXVuaXRlZCI7czoxNDoiZnJpZW5kc3Rlci5jb20iO3M6MTA6IkZyaWVuZHN0ZXIiO3M6NzoiZ3JlZS5qcCI7czo0OiJncmVlIjtzOjk6ImhhYmJvLmNvbSI7czo1OiJIYWJvbyI7czoyMDoibmV3cy55Y29tYmluYXRvci5jb20iO3M6MTE6IkhhY2tlciBOZXdzIjtzOjc6ImhpNS5jb20iO3M6MzoiaGk1IjtzOjg6Imh1eWEuY29tIjtzOjQ6Ikh1eWEiO3M6ODoiaHl2ZXMubmwiO3M6NToiSHl2ZXMiO3M6OToiaWRlbnRpLmNhIjtzOjk6ImlkZW50aS5jYSI7czoxMzoiaW5zdGFncmFtLmNvbSI7czo5OiJJbnN0YWdyYW0iO3M6MTU6ImwuaW5zdGFncmFtLmNvbSI7czo5OiJJbnN0YWdyYW0iO3M6MTA6ImxhbmctOC5jb20iO3M6NjoibGFuZy04IjtzOjc6Imxhc3QuZm0iO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0ucnUiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uZGUiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uZXMiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uZnIiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uaXQiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uanAiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0ucGwiO3M6NzoiTGFzdC5mbSI7czoxMzoibGFzdGZtLmNvbS5iciI7czo3OiJMYXN0LmZtIjtzOjk6Imxhc3RmbS5zZSI7czo3OiJMYXN0LmZtIjtzOjEzOiJsYXN0Zm0uY29tLnRyIjtzOjc6Ikxhc3QuZm0iO3M6MTI6ImxpbmtlZGluLmNvbSI7czo4OiJMaW5rZWRJbiI7czo3OiJsbmtkLmluIjtzOjg6IkxpbmtlZEluIjtzOjE2OiJsaW5rZWRpbi5hbmRyb2lkIjtzOjg6IkxpbmtlZEluIjtzOjE0OiJsaXZlam91cm5hbC5ydSI7czoxMToiTGl2ZUpvdXJuYWwiO3M6MTU6ImxpdmVqb3VybmFsLmNvbSI7czoxMToiTGl2ZUpvdXJuYWwiO3M6MTU6Im1hc3RvZG9uLnNvY2lhbCI7czo4OiJNYXN0b2RvbiI7czoxNDoibWFzdG9kb24uY2xvdWQiO3M6ODoiTWFzdG9kb24iO3M6MTk6Im1hc3RvZG9uLnRlY2hub2xvZ3kiO3M6ODoiTWFzdG9kb24iO3M6MTI6Im1hc3RvZG9uLnh5eiI7czo4OiJNYXN0b2RvbiI7czoxMToibWFzdG9kb24uYXQiO3M6ODoiTWFzdG9kb24iO3M6MTI6Im1hc3RvZG9uLmFydCI7czo4OiJNYXN0b2RvbiI7czo4OiJtYW1vdC5mciI7czo4OiJNYXN0b2RvbiI7czo5OiJwYXdvby5uZXQiO3M6ODoiTWFzdG9kb24iO3M6ODoibXN0ZG4uaW8iO3M6ODoiTWFzdG9kb24iO3M6ODoibXN0ZG4uanAiO3M6ODoiTWFzdG9kb24iO3M6MTI6ImZyaWVuZHMubmljbyI7czo4OiJNYXN0b2RvbiI7czoxOToicm8tbWFzdG9kb24ucHV5by5qcCI7czo4OiJNYXN0b2RvbiI7czo4OiJxdWV5Lm9yZyI7czo4OiJNYXN0b2RvbiI7czoxMjoiYm90c2luLnNwYWNlIjtzOjg6Ik1hc3RvZG9uIjtzOjE2OiJzb2NpYWwudGNobmNzLmRlIjtzOjg6Ik1hc3RvZG9uIjtzOjc6ImtuemsubWUiO3M6ODoiTWFzdG9kb24iO3M6MTM6Im1hc3RvZG9udC5jYXQiO3M6ODoiTWFzdG9kb24iO3M6MTg6ImJpdGNvaW5oYWNrZXJzLm9yZyI7czo4OiJNYXN0b2RvbiI7czoxMzoiZm9zc3RvZG9uLm9yZyI7czo4OiJNYXN0b2RvbiI7czoxMjoiY2hhb3Muc29jaWFsIjtzOjg6Ik1hc3RvZG9uIjtzOjExOiJjeWJyZS5zcGFjZSI7czo4OiJNYXN0b2RvbiI7czoxMDoidmlzLnNvY2lhbCI7czo4OiJNYXN0b2RvbiI7czoxMToidHlwby5zb2NpYWwiO3M6ODoiTWFzdG9kb24iO3M6MTY6ImZyb250LWVuZC5zb2NpYWwiO3M6ODoiTWFzdG9kb24iO3M6MTI6ImhhY2h5ZGVybS5pbyI7czo4OiJNYXN0b2RvbiI7czoxNToibWFzdG9kb24ub25saW5lIjtzOjg6Ik1hc3RvZG9uIjtzOjEzOiJuZXdzaWUuc29jaWFsIjtzOjg6Ik1hc3RvZG9uIjtzOjEyOiJtc3Rkbi5zb2NpYWwiO3M6ODoiTWFzdG9kb24iO3M6MTU6ImluZGlld2ViLnNvY2lhbCI7czo4OiJNYXN0b2RvbiI7czoxMToic2ZiYS5zb2NpYWwiO3M6ODoiTWFzdG9kb24iO3M6NjoibWFzLnRvIjtzOjg6Ik1hc3RvZG9uIjtzOjExOiJtc3Rkbi5wYXJ0eSI7czo4OiJNYXN0b2RvbiI7czo0OiJjLmltIjtzOjg6Ik1hc3RvZG9uIjtzOjE0OiJtYXN0b2RvbmFwcC51ayI7czo4OiJNYXN0b2RvbiI7czoxNjoidW5pdmVyc2VvZG9uLmNvbSI7czo4OiJNYXN0b2RvbiI7czoxODoic29jaWFsLnZpdmFsZGkubmV0IjtzOjg6Ik1hc3RvZG9uIjtzOjExOiJvaGFpLnNvY2lhbCI7czo4OiJNYXN0b2RvbiI7czoxNDoidG9vdC5jb21tdW5pdHkiO3M6ODoiTWFzdG9kb24iO3M6ODoibWFzdG8uYWkiO3M6ODoiTWFzdG9kb24iO3M6MTM6Im1hc3RvZG9uLnNjb3QiO3M6ODoiTWFzdG9kb24iO3M6MTQ6Im1hc3RvZG9uLndvcmxkIjtzOjg6Ik1hc3RvZG9uIjtzOjExOiJtYXN0b2Rvbi5ueiI7czo4OiJNYXN0b2RvbiI7czoxNToiZ3JhcGhpY3Muc29jaWFsIjtzOjg6Ik1hc3RvZG9uIjtzOjI0OiJvcmcuam9pbm1hc3RvZG9uLmFuZHJvaWQiO3M6ODoiTWFzdG9kb24iO3M6MTI6Im1hc3RvZG9uLmV1cyI7czo4OiJNYXN0b2RvbiI7czoxODoibWFzdG9kb24uamFsZ2kuZXVzIjtzOjg6Ik1hc3RvZG9uIjtzOjc6InRrbS5ldXMiO3M6ODoiTWFzdG9kb24iO3M6MTA6Im1laW52ei5uZXQiO3M6NjoiTWVpblZaIjtzOjEyOiJtaXNzZXZhbi5jb20iO3M6ODoiTWlzc0V2YW4iO3M6NzoibWl4aS5qcCI7czo0OiJNaXhpIjtzOjEwOiJtb2lrcnVnLnJ1IjtzOjEwOiJNb2lLcnVnLnJ1IjtzOjEyOiJtdWx0aXBseS5jb20iO3M6ODoiTXVsdGlwbHkiO3M6MTA6Im15Lm1haWwucnUiO3M6MTA6Im15Lm1haWwucnUiO3M6MTQ6Im15aGVyaXRhZ2UuY29tIjtzOjEwOiJNeUhlcml0YWdlIjtzOjk6Im15bGlmZS5ydSI7czo2OiJNeUxpZmUiO3M6MTE6Im15c3BhY2UuY29tIjtzOjc6Ik15c3BhY2UiO3M6MTQ6Im15eWVhcmJvb2suY29tIjtzOjEwOiJteVllYXJib29rIjtzOjU6Im5rLnBsIjtzOjE0OiJOYXN6YS1rbGFzYS5wbCI7czoxMDoibmV0bG9nLmNvbSI7czo2OiJOZXRsb2ciO3M6MTI6Im5pY292aWRlby5qcCI7czo4OiJOaWNvbmljbyI7czoxNjoib2Rub2tsYXNzbmlraS5ydSI7czoxMzoiT2Rub2tsYXNzbmlraSI7czo5OiJvcmt1dC5jb20iO3M6NToiT3JrdXQiO3M6MTI6InF6b25lLnFxLmNvbSI7czo1OiJPem9uZSI7czoxMToicGVlcGV0aC5jb20iO3M6NzoiUGVlcGV0aCI7czoxMzoicGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5jYSI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5jaCI7czo5OiJQaW50ZXJlc3QiO3M6MTU6InBpbnRlcmVzdC5jby51ayI7czo5OiJQaW50ZXJlc3QiO3M6MTY6InBpbnRlcmVzdC5jb20uYXUiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuZGUiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuZGsiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuZXMiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuZnIiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuaWUiO3M6OToiUGludGVyZXN0IjtzOjE0OiJwaW50ZXJlc3QuaW5mbyI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5qcCI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5ueiI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5wdCI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5zZSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6ImF0LnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJjaC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoiY2wucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6ImNvLnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJkay5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoiZXMucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6Imh1LnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJpZC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoiaWUucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6ImluLnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJpdC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoia3IucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6Im14LnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJubC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoibnoucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6InBoLnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJwdC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoicnUucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6InNlLnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE1OiJwaXhlbGZlZC5zb2NpYWwiO3M6ODoiUGl4ZWxmZWQiO3M6MTE6InBpeGVsZmVkLmRlIjtzOjg6IlBpeGVsZmVkIjtzOjk6InB4bG1vLmNvbSI7czo4OiJQaXhlbGZlZCI7czoxMjoibWV0YXBpeGwuY29tIjtzOjg6IlBpeGVsZmVkIjtzOjE0OiJwaXgudG9vdC53YWxlcyI7czo4OiJQaXhlbGZlZCI7czoxMjoicGl4ZWxmZWQudW5vIjtzOjg6IlBpeGVsZmVkIjtzOjk6InBpeGV5Lm9yZyI7czo4OiJQaXhlbGZlZCI7czo5OiJwbGF4by5jb20iO3M6NToiUGxheG8iO3M6MTA6InJlZGRpdC5jb20iO3M6NjoicmVkZGl0IjtzOjEzOiJucC5yZWRkaXQuY29tIjtzOjY6InJlZGRpdCI7czoxNDoicGF5LnJlZGRpdC5jb20iO3M6NjoicmVkZGl0IjtzOjIwOiJjb20ucmVkZGl0LmZyb250cGFnZSI7czo2OiJyZWRkaXQiO3M6MTA6InJlbnJlbi5jb20iO3M6NjoiUmVucmVuIjtzOjExOiJza3lyb2NrLmNvbSI7czo3OiJTa3lyb2NrIjtzOjEyOiJzbmFwY2hhdC5jb20iO3M6ODoiU25hcGNoYXQiO3M6MTA6InNvbmljby5jb20iO3M6MTA6IlNvbmljby5jb20iO3M6MTQ6InNvdW5kY2xvdWQuY29tIjtzOjEwOiJTb3VuZENsb3VkIjtzOjc6ImdhdGUuc2MiO3M6MTA6IlNvdW5kQ2xvdWQiO3M6MTc6InN0YWNrb3ZlcmZsb3cuY29tIjtzOjEzOiJTdGFja092ZXJmbG93IjtzOjExOiJzdHVkaXZ6Lm5ldCI7czo3OiJTdHVkaVZaIjtzOjE2OiJsb2dpbi50YWdnZWQuY29tIjtzOjY6IlRhZ2dlZCI7czoxMToidGFyaW5nYS5uZXQiO3M6ODoiVGFyaW5nYSEiO3M6MTY6IndlYi50ZWxlZ3JhbS5vcmciO3M6ODoiVGVsZWdyYW0iO3M6MjI6Im9yZy50ZWxlZ3JhbS5tZXNzZW5nZXIiO3M6ODoiVGVsZWdyYW0iO3M6MTE6InRocmVhZHMubmV0IjtzOjc6IlRocmVhZHMiO3M6MTM6ImwudGhyZWFkcy5uZXQiO3M6NzoiVGhyZWFkcyI7czoxMToidGhyZWFkcy5jb20iO3M6NzoiVGhyZWFkcyI7czoxMzoibC50aHJlYWRzLmNvbSI7czo3OiJUaHJlYWRzIjtzOjEwOiJ0aWt0b2suY29tIjtzOjY6IlRpa1RvayI7czoxMDoidHVlbnRpLmNvbSI7czo2OiJUdWVudGkiO3M6MTA6InR1bWJsci5jb20iO3M6NjoidHVtYmxyIjtzOjExOiJ0LnVtYmxyLmNvbSI7czo2OiJ0dW1ibHIiO3M6MTQ6InR3aXRjYXN0aW5nLnR2IjtzOjg6IlR3aXRjYXN0IjtzOjExOiJ0d2l0dGVyLmNvbSI7czo3OiJUd2l0dGVyIjtzOjQ6InQuY28iO3M6NzoiVHdpdHRlciI7czo1OiJ4LmNvbSI7czo3OiJUd2l0dGVyIjtzOjE1OiJzb3VyY2Vmb3JnZS5uZXQiO3M6MTE6IlNvdXJjZWZvcmdlIjtzOjE1OiJzdHVtYmxldXBvbi5jb20iO3M6MTE6IlN0dW1ibGVVcG9uIjtzOjY6InZrLmNvbSI7czo5OiJWa29udGFrdGUiO3M6MTI6InZrb250YWt0ZS5ydSI7czo5OiJWa29udGFrdGUiO3M6MTE6InlvdXR1YmUuY29tIjtzOjc6IllvdVR1YmUiO3M6ODoieW91dHUuYmUiO3M6NzoiWW91VHViZSI7czo4OiJ2MmV4LmNvbSI7czo0OiJWMkVYIjtzOjEwOiJ2aWFkZW8uY29tIjtzOjY6IlZpYWRlbyI7czo5OiJ2aW1lby5jb20iO3M6NToiVmltZW8iO3M6MTU6InZrcnVndWRydXplaS5ydSI7czoxNToidmtydWd1ZHJ1emVpLnJ1IjtzOjg6IndheW4uY29tIjtzOjQ6IldBWU4iO3M6OToid2VpYm8uY29tIjtzOjU6IldlaWJvIjtzOjQ6InQuY24iO3M6NToiV2VpYm8iO3M6MTI6IndlZXdvcmxkLmNvbSI7czo4OiJXZWVXb3JsZCI7czoxNDoibG9naW4ubGl2ZS5jb20iO3M6MTk6IldpbmRvd3MgTGl2ZSBTcGFjZXMiO3M6MTM6IndvcmtwbGFjZS5jb20iO3M6OToiV29ya3BsYWNlIjtzOjE1OiJsLndvcmtwbGFjZS5jb20iO3M6OToiV29ya3BsYWNlIjtzOjE2OiJsbS53b3JrcGxhY2UuY29tIjtzOjk6IldvcmtwbGFjZSI7czo5OiJ4YW5nYS5jb20iO3M6NToiWGFuZ2EiO3M6ODoieGluZy5jb20iO3M6NDoiWElORyI7fQ==',0),('tagmanager_salt','3c80d065e949f2e01fb0SttGeh0w9P5L?DZ6AnK6',0),('TaskScheduler.timetable','a:33:{s:45:\"Piwik\\Plugins\\GeoIp2\\GeoIP2AutoUpdater.update\";i:1762300800;s:60:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.invalidateOutdatedArchives\";i:1762300808;s:59:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.deleteOldFingerprintSalts\";i:1762300808;s:55:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeOutdatedArchives\";i:1762300808;s:55:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeOrphanedArchives\";i:1762732808;s:51:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.updateSpammerList\";i:1762732808;s:61:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.checkSiteHasTrackedVisits_1\";i:1762567200;s:49:\"Piwik\\Plugins\\Referrers\\Tasks.updateSearchEngines\";i:1762732808;s:43:\"Piwik\\Plugins\\Referrers\\Tasks.updateSocials\";i:1762732808;s:48:\"Piwik\\Plugins\\Referrers\\Tasks.updateAIAssistants\";i:1762732808;s:47:\"Piwik\\Plugins\\Login\\Tasks.cleanupBruteForceLogs\";i:1762300808;s:63:\"Piwik\\Plugins\\TwoFactorAuth\\Tasks.cleanupTwoFaCodesUsedRecently\";i:1762300808;s:53:\"Piwik\\Plugins\\UsersManager\\Tasks.cleanupExpiredTokens\";i:1762300808;s:63:\"Piwik\\Plugins\\UsersManager\\Tasks.setUserDefaultReportPreference\";i:1762300808;s:54:\"Piwik\\Plugins\\UsersManager\\Tasks.cleanUpExpiredInvites\";i:1762300808;s:85:\"Piwik\\Plugins\\UsersManager\\TokenNotifications\\TokenNotifierTask.dispatchNotifications\";i:1762300808;s:83:\"Piwik\\Plugins\\UsersManager\\UserNotifications\\UserNotifierTask.dispatchNotifications\";i:1764547208;s:49:\"Piwik\\Plugins\\CustomJsTracker\\Tasks.updateTracker\";i:1762268408;s:59:\"Piwik\\Plugins\\TagManager\\Tasks.regenerateReleasedContainers\";i:1762268408;s:65:\"Piwik\\Plugins\\TagManager\\Tasks.deleteContainersForNonExistingSite\";i:1762300808;s:58:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeInvalidatedArchives\";i:1762300808;s:65:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeBrokenArchivesCurrentMonth\";i:1762300808;s:67:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeInvalidationsForDeletedSites\";i:1762300808;s:51:\"Piwik\\Plugins\\PrivacyManager\\Tasks.deleteReportData\";i:1762300808;s:48:\"Piwik\\Plugins\\PrivacyManager\\Tasks.deleteLogData\";i:1762268408;s:52:\"Piwik\\Plugins\\PrivacyManager\\Tasks.anonymizePastData\";i:1762268408;s:63:\"Piwik\\Plugins\\PrivacyManager\\Tasks.deleteLogDataForDeletedSites\";i:1762732808;s:54:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.optimizeArchiveTable\";i:1764547208;s:57:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.cleanupTrackingFailures\";i:1762300808;s:56:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.notifyTrackingFailures\";i:1762732808;s:65:\"Piwik\\Plugins\\CoreUpdater\\Tasks.sendNotificationIfUpdateAvailable\";i:1762300808;s:52:\"Piwik\\Plugins\\Marketplace\\Tasks.clearAllCacheEntries\";i:1762300808;s:66:\"Piwik\\Plugins\\Marketplace\\Tasks.sendNotificationIfUpdatesAvailable\";i:1762300808;}',0),('TransactionLevel.testOption','1',0),('UpdateCheck_LastCheckFailed','1',0),('UpdateCheck_LastTimeChecked','',1),('useridsalt','DlwaUa8eGdJNPfM0dAms6azwXoDnRHRZSlJM3HOJ',1),('version_Actions','5.5.1',1),('version_Annotations','5.5.1',1),('version_API','5.5.1',1),('version_BulkTracking','5.5.1',1),('version_Contents','5.5.1',1),('version_core','5.5.1',1),('version_CoreAdminHome','5.5.1',1),('version_CoreConsole','5.5.1',1),('version_CoreHome','5.5.1',1),('version_CorePluginsAdmin','5.5.1',1),('version_CoreUpdater','5.5.1',1),('version_CoreVisualizations','5.5.1',1),('version_CoreVue','5.5.1',1),('version_CustomDimensions','5.5.1',1),('version_CustomJsTracker','5.5.1',1),('version_Dashboard','5.5.1',1),('version_DevicePlugins','5.5.1',1),('version_DevicesDetection','5.5.1',1),('version_Diagnostics','5.5.1',1),('version_Ecommerce','5.5.1',1),('version_Events','5.5.1',1),('version_FeatureFlags','5.5.1',1),('version_Feedback','5.5.1',1),('version_GeoIp2','5.5.1',1),('version_Goals','5.5.1',1),('version_Heartbeat','5.5.1',1),('version_ImageGraph','5.5.1',1),('version_Insights','5.5.1',1),('version_Installation','5.5.1',1),('version_Intl','5.5.1',1),('version_IntranetMeasurable','5.5.1',1),('version_JsTrackerInstallCheck','5.5.1',1),('version_LanguagesManager','5.5.1',1),('version_Live','5.5.1',1),('version_log_conversion.pageviews_before','SMALLINT UNSIGNED DEFAULT NULL',1),('version_log_conversion.revenue','float default NULL',1),('version_log_link_visit_action.idaction_content_interaction','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_content_name','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_content_piece','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_content_target','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_event_action','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_event_category','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_name','INTEGER(10) UNSIGNED',1),('version_log_link_visit_action.idaction_product_cat','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_cat2','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_cat3','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_cat4','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_cat5','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_name','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_sku','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_url','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idpageview','CHAR(6) NULL DEFAULT NULL',1),('version_log_link_visit_action.product_price','DOUBLE NULL',1),('version_log_link_visit_action.search_cat','VARCHAR(200) NULL',1),('version_log_link_visit_action.search_count','INTEGER(10) UNSIGNED NULL',1),('version_log_link_visit_action.server_time','DATETIME NOT NULL',1),('version_log_link_visit_action.time_dom_completion','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_dom_processing','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_network','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_on_load','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_server','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_spent_ref_action','INTEGER(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_transfer','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_visit.config_browser_engine','VARCHAR(10) NULL',1),('version_log_visit.config_browser_name','VARCHAR(40) NULL1',1),('version_log_visit.config_browser_version','VARCHAR(20) NULL',1),('version_log_visit.config_client_type','TINYINT( 1 ) NULL DEFAULT NULL1',1),('version_log_visit.config_cookie','TINYINT(1) NULL',1),('version_log_visit.config_device_brand','VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL1',1),('version_log_visit.config_device_model','VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL1',1),('version_log_visit.config_device_type','TINYINT( 100 ) NULL DEFAULT NULL1',1),('version_log_visit.config_flash','TINYINT(1) NULL',1),('version_log_visit.config_java','TINYINT(1) NULL',1),('version_log_visit.config_os','CHAR(3) NULL',1),('version_log_visit.config_os_version','VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL',1),('version_log_visit.config_pdf','TINYINT(1) NULL',1),('version_log_visit.config_quicktime','TINYINT(1) NULL',1),('version_log_visit.config_realplayer','TINYINT(1) NULL',1),('version_log_visit.config_resolution','VARCHAR(18) NULL',1),('version_log_visit.config_silverlight','TINYINT(1) NULL',1),('version_log_visit.config_windowsmedia','TINYINT(1) NULL',1),('version_log_visit.location_browser_lang','VARCHAR(20) NULL',1),('version_log_visit.location_city','varchar(255) DEFAULT NULL1',1),('version_log_visit.location_country','CHAR(3) NULL1',1),('version_log_visit.location_latitude','decimal(9, 6) DEFAULT NULL1',1),('version_log_visit.location_longitude','decimal(9, 6) DEFAULT NULL1',1),('version_log_visit.location_region','char(3) DEFAULT NULL1',1),('version_log_visit.profilable','TINYINT(1) NULL',1),('version_log_visit.referer_keyword','VARCHAR(255) NULL1',1),('version_log_visit.referer_name','VARCHAR(255) NULL1',1),('version_log_visit.referer_type','TINYINT(1) UNSIGNED NULL1',1),('version_log_visit.referer_url','VARCHAR(1500) NULL',1),('version_log_visit.user_id','VARCHAR(200) NULL',1),('version_log_visit.visit_entry_idaction_name','INTEGER(10) UNSIGNED NULL',1),('version_log_visit.visit_entry_idaction_url','INTEGER(11) UNSIGNED NULL  DEFAULT NULL',1),('version_log_visit.visit_exit_idaction_name','INTEGER(10) UNSIGNED NULL',1),('version_log_visit.visit_exit_idaction_url','INTEGER(10) UNSIGNED NULL DEFAULT 0',1),('version_log_visit.visit_first_action_time','DATETIME NOT NULL',1),('version_log_visit.visit_goal_buyer','TINYINT(1) NULL',1),('version_log_visit.visit_goal_converted','TINYINT(1) NULL',1),('version_log_visit.visit_total_actions','INT(11) UNSIGNED NULL',1),('version_log_visit.visit_total_events','INT(11) UNSIGNED NULL',1),('version_log_visit.visit_total_interactions','MEDIUMINT UNSIGNED DEFAULT 0',1),('version_log_visit.visit_total_searches','SMALLINT(5) UNSIGNED NULL',1),('version_log_visit.visit_total_time','INT(11) UNSIGNED NOT NULL',1),('version_log_visit.visitor_count_visits','INT(11) UNSIGNED NOT NULL DEFAULT 01',1),('version_log_visit.visitor_localtime','TIME NULL',1),('version_log_visit.visitor_returning','TINYINT(1) NULL1',1),('version_log_visit.visitor_seconds_since_first','INT(11) UNSIGNED NULL1',1),('version_log_visit.visitor_seconds_since_last','INT(11) UNSIGNED NULL',1),('version_log_visit.visitor_seconds_since_order','INT(11) UNSIGNED NULL1',1),('version_Login','5.5.1',1),('version_Marketplace','5.5.1',1),('version_MobileMessaging','5.5.1',1),('version_Monolog','5.5.1',1),('version_Morpheus','5.5.1',1),('version_MultiSites','5.5.1',1),('version_Overlay','5.5.1',1),('version_PagePerformance','5.5.1',1),('version_PrivacyManager','5.5.1',1),('version_ProfessionalServices','5.5.1',1),('version_Proxy','5.5.1',1),('version_Referrers','5.5.1',1),('version_Resolution','5.5.1',1),('version_RssWidget','1.0',1),('version_ScheduledReports','5.5.1',1),('version_SegmentEditor','5.5.1',1),('version_SEO','5.5.1',1),('version_SitesManager','5.5.1',1),('version_TagManager','5.5.1',1),('version_Tour','5.5.1',1),('version_Transitions','5.5.1',1),('version_TwoFactorAuth','5.5.1',1),('version_UserCountry','5.5.1',1),('version_UserCountryMap','5.5.1',1),('version_UserId','5.5.1',1),('version_UserLanguage','5.5.1',1),('version_UsersManager','5.5.1',1),('version_VisitFrequency','5.5.1',1),('version_VisitorInterest','5.5.1',1),('version_VisitsSummary','5.5.1',1),('version_VisitTime','5.5.1',1),('version_WebsiteMeasurable','5.5.1',1),('version_Widgetize','5.5.1',1);
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_plugin_setting`
--

LOCK TABLES `matomo_plugin_setting` WRITE;
/*!40000 ALTER TABLE `matomo_plugin_setting` DISABLE KEYS */;
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
INSERT INTO `matomo_sequence` VALUES ('matomo_archive_numeric_2025_01',0),('matomo_archive_numeric_2025_11',11);
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
INSERT INTO `matomo_session` VALUES ('2d0c15d1328387ab1b5bcbefa47a947ed95aabf0cf8a411b28cbbfddf469fa31d4ba63d3c3d0735116564172701cd47a2a0e6ab62176a5cfb9c5a26373743e2b',1762267949,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIxZTgwYjBiNTBjY2FkZjYzNjc5NGJjN2QxYjE4MGRiMiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4NTQ5O319fX0=\";}'),('35600d6ab5474dcc59b65d07f4f11bfd2922c7f10d7ed7c991fb798fbcd89a8eb6295abad2c04d225e868ecc2be54a712e48b7ceb6ec70b3dbbdcc6ea9261e14',1762268191,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJmZTM0NDEyY2JmZTkxYTQ0NWQwMDdkNGIyMzNlYzM1ZiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4NzkxO319fX0=\";}'),('4001d071cfc8bb2f4708360c3ae7c22ed4d36a439d8f85ed3ecbd3875515cd1fcff628ea06ad3fcb40565c93fcf3cd95b9e1c9b4bdd6829b7a4c09e60b815e10',1762268312,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI0ZjJmZWU3NjNiMjk5Y2Q5YWFhZjc1MTFlNTE2OGQ5NyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4OTEyO319fX0=\";}'),('40950d254e06abe85339be70dec20dd366b6c8f54c7ea0ec618892d2bcb21fa8aeab169ce1d05aa09434abae92401780679214172332175e4125f5a8e0af6dec',1762267758,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI2ODg3ZjdmYjVlMTQyOWYxOGZiZTEyMGNmYzBlZTAzNCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4MzU4O319fX0=\";}'),('56cf0a40724ba751e1bc6a126acff5ea045ff6d39add87b09e9f554948303c711e12252bc1c0cca5122bc259bc7f3c9e8d74b0f68dd7b28eb7bf56f6e0dbe789',1762268070,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIwOTQ2N2UyOWQ2ZWVhYjY3ZGNjMWMzNGQ3MTYyOTA3MyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4NjcwO319fX0=\";}'),('5e127503ecfe9ea6c126a9e8a67ca051d87e0507623a814b4efbf93c1c9404ff53ae99e9ec9bd4a64c96acc7910ff57b55958a14c2b36424f08b6e11e5466635',1762268010,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJmMTBhYTJmOWU5ZTc5ZTgzNzVmY2FmMjc2YzM0MTYzYyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4NjEwO319fX0=\";}'),('613a57ce709f0c867ba18754f553f198cb02f5bff1752ac3a5ca7d70dc2b0b85df866a5dc628ec2d551b2e9563febe450b2a5ee11e412ddba7b51692cd6c7530',1762268434,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI2ZTgwMDkxMmVlNmY1ZWMxOTEzNzBkOWYwMDk3YmRlNiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY5MDM0O319fX0=\";}'),('6aad33976663efd2ee6612406c60c1672f82997df12e319536d81516f9f0318f6e8aa1ec728230a68e94bd32becd80092e3538d199dfb4ff568f41128c8c7dbb',1762268251,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkMmFlOWIyNjY5NDc4NmUxZTQyZmM4MDkwMDQ3NDFmMSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4ODUxO319fX0=\";}'),('943173591b2b3e57fbc61991a276dcda09434041fa3273c76afb7c80ae4b4d078f5356fcce8bc2aa3254a206a709afaef75982d946335a9dba5af8310c146adb',1762268046,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkMzkwN2Q3YjBhNTZiMTM2YTU3Y2E4NTFhOWM4NmVmNSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4NjQ2O319fX0=\";}'),('9d0ae46b354d97e95eb9cbf21747f61b0e1742cec31d084b42279f14b2092223b8dcf8b91d9f056468b23c676e2cfa71bf1d36dd810f39c2915e1199b128b7f3',1762268373,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI4NDk5ZmE3NjNiN2QyNTJlYTEyOWFjOTk0NmRmNTRkNSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4OTczO319fX0=\";}'),('b06d4c4ef87ea203aeca99c164afb1fd16d48752523efde67e98aaf09e9c2b48aa828aa1a1909e3033102a054b80a2d93be3c4df2eabb99ce4e50c34d85d9c5c',1762267768,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkYmY2N2E3MTRmM2RmZTcxZDgwMjAwMDRhZjUwNTRkMiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4MzY4O319fX0=\";}'),('b5baf210ecade39e81158c0b45d56ed4926ce00b2bd292c5fccc0f45378027ddfe9ecd07a7b417f52597eeae9a6e4cf39ad2af3ffb69044b6c23c41ff6bc373f',1762267829,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI3MDM3MGE3MWM2YjcyYmY5MjI4N2U0ZTM3N2U4MjI1MyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4NDI5O319fX0=\";}'),('bba70ffa716bb8a378dca1b6a221662c5543f1ad75d130519fdcc142c58cb13ce7b623836ffa8f269094be8ff7356d4660357a06f35a9da16b4edd4fbc2be139',1762268449,1209600,'a:1:{s:4:\"data\";s:1492:\"YTo4OntzOjQ6Il9fWkYiO2E6Mzp7czozMToiQ29yZVBsdWdpbnNBZG1pbi5hY3RpdmF0ZVBsdWdpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4NDUwO319czo1OiJMb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6Mjp7czoxNDoicmVkaXJlY3RQYXJhbXMiO2k6MTc2MjI2OTY2NjtzOjE2OiJsYXN0UGFzc3dvcmRBdXRoIjtpOjE3NjIyNjk2NjY7fX1zOjE1OiJjb25maXJtUGFzc3dvcmQiO2E6MTp7czo0OiJFTlZUIjthOjE6e3M6NToibm9uY2UiO2k6MTc2MjI2ODQ2Mjt9fX1zOjk6InVzZXIubmFtZSI7czoxNToibXlzcWxfc3VwZXJ1c2VyIjtzOjIyOiJ0d29mYWN0b3JhdXRoLnZlcmlmaWVkIjtpOjA7czoyMDoidXNlci50b2tlbl9hdXRoX3RlbXAiO3M6MzI6IjQyOWYzNTM1YjcxOWRhNzBjNzZjMzNkNzc5NmJkMzNmIjtzOjEyOiJzZXNzaW9uLmluZm8iO2E6Mzp7czoyOiJ0cyI7aToxNzYyMjY3NzU3O3M6MTA6InJlbWVtYmVyZWQiO2I6MDtzOjEwOiJleHBpcmF0aW9uIjtpOjE3NjIyNzIwNDk7fXM6MTI6Im5vdGlmaWNhdGlvbiI7YToxOntzOjEzOiJub3RpZmljYXRpb25zIjthOjA6e319czo1OiJMb2dpbiI7YToyOntzOjE0OiJyZWRpcmVjdFBhcmFtcyI7YTo2OntzOjY6Im1vZHVsZSI7czoxNjoiQ29yZVBsdWdpbnNBZG1pbiI7czo2OiJhY3Rpb24iO3M6ODoiYWN0aXZhdGUiO3M6MTA6InBsdWdpbk5hbWUiO3M6MTA6IlRhZ01hbmFnZXIiO3M6NToibm9uY2UiO3M6MzI6IjI3YWIzYjMxYzk2YTVkNWEzMTMzNzFjZGRmYTAyNmQwIjtzOjEwOiJyZWRpcmVjdFRvIjtzOjEwOiJ0YWdtYW5hZ2VyIjtzOjg6InJlZmVycmVyIjtzOjE0MzoiaHR0cHMlM0ElMkYlMkZhbmFseXRpY3Muem9vJTJGaW5kZXgucGhwJTNGbW9kdWxlJTNEQ29yZVBsdWdpbnNBZG1pbiUyNmFjdGlvbiUzRHRhZ01hbmFnZXJUZWFzZXIlMjZpZFNpdGUlM0QxJTI2cGVyaW9kJTNEZGF5JTI2ZGF0ZSUzRDIwMjUtMTEtMDQiO31zOjE2OiJsYXN0UGFzc3dvcmRBdXRoIjtzOjE5OiIyMDI1LTExLTA0IDE0OjUxOjA2Ijt9czoxNToiY29uZmlybVBhc3N3b3JkIjthOjE6e3M6NToibm9uY2UiO3M6MzI6Ijc3YWZmODUzYzg2ZDA1NjZiZTNhMjU5ZTE0N2FmNDY4Ijt9fQ==\";}'),('db816ea50b6dda859c3b1128d64dfe074f4254e7ccd8c7eccfd55c40378b93860f1d3b6e93ebc77c33f144f1974d4f2d321939dc24a4038f719388c17b5ce30e',1762267889,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI5MjhjODZhODdmZWU2YjExMWM3ZmVjNzBlYzgzNDNjMSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4NDg5O319fX0=\";}'),('fd036da7023fb1bd25028dd6f05bab9eb461c849258a77d0aa62814f851522a9ac94e462cc5826d412856ad2e5109fab59b581803a8b71328d516316cf8abc4c',1762268131,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI1MjhjNGYyZTRmZjUwMDQyZjA4MDFkYzZmMDI3ZTE0OCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyMjY4NzMxO319fX0=\";}');
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_site`
--

LOCK TABLES `matomo_site` WRITE;
/*!40000 ALTER TABLE `matomo_site` DISABLE KEYS */;
INSERT INTO `matomo_site` VALUES (1,'analytics','https://analytics.zoo','2025-11-03 00:00:00',0,1,'','','Africa/Algiers','USD',0,'','','','','','website',0,'anonymous');
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_site_setting`
--

LOCK TABLES `matomo_site_setting` WRITE;
/*!40000 ALTER TABLE `matomo_site_setting` DISABLE KEYS */;
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
/*!40000 ALTER TABLE `matomo_site_url` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_tagmanager_container`
--

DROP TABLE IF EXISTS `matomo_tagmanager_container`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_tagmanager_container` (
  `idcontainer` varchar(8) NOT NULL,
  `idsite` int unsigned NOT NULL,
  `context` varchar(10) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(1000) NOT NULL DEFAULT '',
  `ignoreGtmDataLayer` tinyint unsigned NOT NULL DEFAULT '0',
  `activelySyncGtmDataLayer` tinyint unsigned NOT NULL DEFAULT '1',
  `isTagFireLimitAllowedInPreviewMode` tinyint unsigned NOT NULL DEFAULT '0',
  `status` varchar(10) NOT NULL,
  `created_date` datetime NOT NULL,
  `updated_date` datetime NOT NULL,
  `deleted_date` datetime DEFAULT NULL,
  PRIMARY KEY (`idcontainer`),
  KEY `idsite` (`idsite`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_tagmanager_container`
--

LOCK TABLES `matomo_tagmanager_container` WRITE;
/*!40000 ALTER TABLE `matomo_tagmanager_container` DISABLE KEYS */;
INSERT INTO `matomo_tagmanager_container` VALUES ('tNJU3NKP',1,'web','Default Container','This container was auto generated when the website was created.',0,0,0,'active','2025-11-04 14:51:06','2025-11-04 14:51:06',NULL);
/*!40000 ALTER TABLE `matomo_tagmanager_container` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_tagmanager_container_release`
--

DROP TABLE IF EXISTS `matomo_tagmanager_container_release`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_tagmanager_container_release` (
  `idcontainerrelease` bigint NOT NULL AUTO_INCREMENT,
  `idcontainer` varchar(8) NOT NULL,
  `idcontainerversion` bigint unsigned NOT NULL,
  `idsite` int unsigned NOT NULL,
  `status` varchar(10) NOT NULL,
  `environment` varchar(40) NOT NULL,
  `release_login` varchar(100) NOT NULL,
  `release_date` datetime NOT NULL,
  `deleted_date` datetime DEFAULT NULL,
  PRIMARY KEY (`idcontainerrelease`),
  KEY `idsite` (`idsite`,`idcontainer`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_tagmanager_container_release`
--

LOCK TABLES `matomo_tagmanager_container_release` WRITE;
/*!40000 ALTER TABLE `matomo_tagmanager_container_release` DISABLE KEYS */;
INSERT INTO `matomo_tagmanager_container_release` VALUES (1,'tNJU3NKP',1,1,'active','live','mysql_superuser','2025-11-04 14:51:06',NULL);
/*!40000 ALTER TABLE `matomo_tagmanager_container_release` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_tagmanager_container_version`
--

DROP TABLE IF EXISTS `matomo_tagmanager_container_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_tagmanager_container_version` (
  `idcontainerversion` bigint unsigned NOT NULL AUTO_INCREMENT,
  `idcontainer` varchar(8) NOT NULL,
  `idsite` int unsigned NOT NULL,
  `status` varchar(10) NOT NULL,
  `revision` mediumint unsigned NOT NULL DEFAULT '1',
  `name` varchar(255) NOT NULL DEFAULT '',
  `description` varchar(1000) NOT NULL DEFAULT '',
  `created_date` datetime NOT NULL,
  `updated_date` datetime NOT NULL,
  `deleted_date` datetime DEFAULT NULL,
  PRIMARY KEY (`idcontainerversion`),
  KEY `idcontainer` (`idcontainer`),
  KEY `idsite` (`idsite`,`idcontainer`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_tagmanager_container_version`
--

LOCK TABLES `matomo_tagmanager_container_version` WRITE;
/*!40000 ALTER TABLE `matomo_tagmanager_container_version` DISABLE KEYS */;
INSERT INTO `matomo_tagmanager_container_version` VALUES (1,'tNJU3NKP',1,'active',0,'','','2025-11-04 14:51:06','2025-11-04 14:51:06',NULL),(2,'tNJU3NKP',1,'active',1,'0.1.0 - Auto generated','','2025-11-04 14:51:06','2025-11-04 14:51:06',NULL);
/*!40000 ALTER TABLE `matomo_tagmanager_container_version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_tagmanager_tag`
--

DROP TABLE IF EXISTS `matomo_tagmanager_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_tagmanager_tag` (
  `idtag` bigint unsigned NOT NULL AUTO_INCREMENT,
  `idcontainerversion` bigint unsigned NOT NULL,
  `idsite` int unsigned NOT NULL,
  `type` varchar(50) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(1000) NOT NULL,
  `status` varchar(10) NOT NULL,
  `parameters` mediumtext NOT NULL,
  `fire_trigger_ids` text NOT NULL,
  `block_trigger_ids` text NOT NULL,
  `fire_limit` varchar(20) NOT NULL DEFAULT 'unlimited',
  `priority` smallint unsigned NOT NULL,
  `fire_delay` mediumint unsigned NOT NULL DEFAULT '0',
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `created_date` datetime NOT NULL,
  `updated_date` datetime NOT NULL,
  `deleted_date` datetime DEFAULT NULL,
  PRIMARY KEY (`idtag`),
  KEY `idsite` (`idsite`,`idcontainerversion`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_tagmanager_tag`
--

LOCK TABLES `matomo_tagmanager_tag` WRITE;
/*!40000 ALTER TABLE `matomo_tagmanager_tag` DISABLE KEYS */;
INSERT INTO `matomo_tagmanager_tag` VALUES (1,1,1,'Matomo','Matomo Analytics','','active','{\"matomoConfig\":\"{{Matomo Configuration}}\"}','[1]','','unlimited',999,0,NULL,NULL,'2025-11-04 14:51:06','2025-11-04 14:51:06',NULL),(2,2,1,'Matomo','Matomo Analytics','','active','{\"matomoConfig\":\"{{Matomo Configuration}}\",\"trackingType\":\"pageview\",\"idGoal\":\"\",\"goalCustomRevenue\":\"\",\"documentTitle\":\"\",\"customUrl\":\"\",\"isEcommerceView\":false,\"productSKU\":\"\",\"productName\":\"\",\"categoryName\":\"\",\"price\":\"\",\"eventCategory\":\"\",\"eventAction\":\"\",\"eventName\":\"\",\"eventValue\":\"\",\"customDimensions\":[],\"areCustomDimensionsSticky\":false}','[2]','','unlimited',999,0,NULL,NULL,'2025-11-04 14:51:06','2025-11-04 14:51:06',NULL);
/*!40000 ALTER TABLE `matomo_tagmanager_tag` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_tagmanager_trigger`
--

DROP TABLE IF EXISTS `matomo_tagmanager_trigger`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_tagmanager_trigger` (
  `idtrigger` bigint unsigned NOT NULL AUTO_INCREMENT,
  `idcontainerversion` bigint unsigned NOT NULL,
  `idsite` int unsigned NOT NULL,
  `type` varchar(50) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(1000) NOT NULL,
  `status` varchar(10) NOT NULL,
  `parameters` mediumtext NOT NULL,
  `conditions` mediumtext NOT NULL,
  `created_date` datetime NOT NULL,
  `updated_date` datetime NOT NULL,
  `deleted_date` datetime DEFAULT NULL,
  PRIMARY KEY (`idtrigger`),
  KEY `idsite` (`idsite`,`idcontainerversion`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_tagmanager_trigger`
--

LOCK TABLES `matomo_tagmanager_trigger` WRITE;
/*!40000 ALTER TABLE `matomo_tagmanager_trigger` DISABLE KEYS */;
INSERT INTO `matomo_tagmanager_trigger` VALUES (1,1,1,'PageView','Pageview','','active','','','2025-11-04 14:51:06','2025-11-04 14:51:06',NULL),(2,2,1,'PageView','Pageview','','active','','','2025-11-04 14:51:06','2025-11-04 14:51:06',NULL);
/*!40000 ALTER TABLE `matomo_tagmanager_trigger` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matomo_tagmanager_variable`
--

DROP TABLE IF EXISTS `matomo_tagmanager_variable`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matomo_tagmanager_variable` (
  `idvariable` bigint unsigned NOT NULL AUTO_INCREMENT,
  `idcontainerversion` bigint unsigned NOT NULL,
  `idsite` int unsigned NOT NULL,
  `type` varchar(50) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(1000) NOT NULL,
  `status` varchar(10) NOT NULL,
  `parameters` mediumtext NOT NULL,
  `lookup_table` mediumtext NOT NULL,
  `default_value` text,
  `created_date` datetime NOT NULL,
  `updated_date` datetime NOT NULL,
  `deleted_date` datetime DEFAULT NULL,
  PRIMARY KEY (`idvariable`),
  KEY `idsite` (`idsite`,`idcontainerversion`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_tagmanager_variable`
--

LOCK TABLES `matomo_tagmanager_variable` WRITE;
/*!40000 ALTER TABLE `matomo_tagmanager_variable` DISABLE KEYS */;
INSERT INTO `matomo_tagmanager_variable` VALUES (1,1,1,'MatomoConfiguration','Matomo Configuration','','active','','','','2025-11-04 14:51:06','2025-11-04 14:51:06',NULL),(2,2,1,'MatomoConfiguration','Matomo Configuration','','active','{\"matomoUrl\":\"\\/\\/analytics.zoo\\/\",\"idSite\":\"1\",\"enableLinkTracking\":true,\"enableFileTracking\":false,\"enableCrossDomainLinking\":false,\"crossDomainLinkingTimeout\":180,\"enableDoNotTrack\":false,\"disablePerformanceTracking\":false,\"enableJSErrorTracking\":false,\"enableHeartBeatTimer\":false,\"heartBeatTime\":15,\"trackAllContentImpressions\":false,\"trackVisibleContentImpressions\":false,\"trackBots\":false,\"disableCookies\":false,\"requireConsent\":false,\"requireCookieConsent\":false,\"customCookieTimeOutEnable\":false,\"customCookieTimeOut\":393,\"referralCookieTimeOut\":182,\"sessionCookieTimeOut\":30,\"setSecureCookie\":false,\"cookieDomain\":\"\",\"cookieNamePrefix\":\"_pk_\",\"cookiePath\":\"\",\"cookieSameSite\":\"Lax\",\"disableBrowserFeatureDetection\":false,\"disableCampaignParameters\":false,\"domains\":[],\"alwaysUseSendBeacon\":false,\"disableAlwaysUseSendBeacon\":false,\"userId\":\"\",\"customDimensions\":[],\"registerAsDefaultTracker\":true,\"bundleTracker\":true,\"jsEndpoint\":\"matomo.js\",\"jsEndpointCustom\":\"custom.js\",\"trackingEndpoint\":\"matomo.php\",\"trackingEndpointCustom\":\"custom.php\",\"appendToTrackingUrl\":\"\",\"forceRequestMethod\":false,\"requestMethod\":\"GET\",\"requestContentType\":\"application\\/x-www-form-urlencoded; charset=UTF-8\",\"customRequestProcessing\":\"\",\"customData\":[],\"setDownloadExtensions\":\"\",\"addDownloadExtensions\":\"\",\"removeDownloadExtensions\":\"\",\"setIgnoreClasses\":\"\",\"setReferrerUrl\":\"\",\"setApiUrl\":\"\",\"setPageViewId\":\"\",\"setExcludedReferrers\":\"\",\"setDownloadClasses\":\"\",\"setLinkClasses\":\"\",\"setCampaignNameKey\":\"\",\"setCampaignKeywordKey\":\"\",\"setConsentGiven\":false,\"rememberConsentGiven\":false,\"rememberConsentGivenForHours\":\"\",\"forgetConsentGiven\":false,\"discardHashTag\":false,\"setExcludedQueryParams\":\"\",\"setConversionAttributionFirstReferrer\":false,\"setDoNotTrack\":false,\"setLinkTrackingTimer\":\"\",\"killFrame\":false,\"setCountPreRendered\":false,\"setRequestQueueInterval\":\"\"}','','','2025-11-04 14:51:06','2025-11-04 14:51:06',NULL);
/*!40000 ALTER TABLE `matomo_tagmanager_variable` ENABLE KEYS */;
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
INSERT INTO `matomo_user` VALUES ('anonymous','','anonymous@example.org','',0,'2025-11-04 14:39:55','2025-11-04 14:39:55',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),('mysql_superuser','$2y$12$UuoWpspOgujsG5s7CnRpge7Zs3NuxIrOJ2tIFRLBwX67lBRLSiag6','mysql_superuser@snappymail.zoo','',1,'2025-11-04 14:41:26','2025-11-04 14:41:26',NULL,NULL,NULL,NULL,NULL,NULL,'2025-11-04 14:54:05','2025-11-04 14:59:49',NULL);
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_user_token_auth`
--

LOCK TABLES `matomo_user_token_auth` WRITE;
/*!40000 ALTER TABLE `matomo_user_token_auth` DISABLE KEYS */;
INSERT INTO `matomo_user_token_auth` VALUES (1,'anonymous','anonymous default token','410bbc33dad06b62a632a3c872b2df96e0cc17626f38fb131e5b9b823b97091d0e47d46dde29a00e3bcfcb796e7fa5aad91d1d95ff71cf8d46a51d794c74f62f','sha512',0,'2025-11-04 15:00:34','2025-11-04 14:39:55',NULL,0,NULL,NULL);
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

-- Dump completed on 2025-11-04 15:01:12
