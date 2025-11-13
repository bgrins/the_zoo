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
INSERT INTO `matomo_archive_blob_2025_11` VALUES (12,'Actions_actions',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœu”\İnƒ \Ç_e\á>´V|‡\Ş\ìn7„¶¬’)aë’¦\ï>\ÉhA…søŸs~œ\"z“vœ’8i\é\ÍĞš‚\Å\0:C¢\à\å]\ë—7Á\çS:I±{QúzG\å\'\Ä}\öM\ë5­¥\0ù\0»³K\ï&(x\á\â\Å\İÁ\Ä\rÎ»£À|\Ì\ÊQ0%\ìUÏŸ¾¾s\ÃWH*\è\r\ì\ÈÔ‘\õ\Ò\Zv•¶\Ï\Ô.wş²RmdsO\ñŸ\r\ÚQp1‹9jP‹VU\ÂúGª:¡z\Ê\á.Ö‹P\Ï\õP\Ø\Ô$Lv\æ\Ê|¤*Xª]‰*•G®&\á\Ê\ò\Å\íj²\\U“P•$lg=²i\Ö\'aŒT—Œ\àa´rúÜ‘s#\÷º‹v¥\İ\ÒVm™ù¤\ÇiVj•\í\Â6\ócP8\å\æTv(>:C+6h~Î°Ê‘¨W‡Îˆ\ëk’¬¸¾n\ÖNO»\Z\Ã`\ì\Ãw¶û“¶nÇ’w\Êı]\÷\Ä/\îøH;6q\Û/L‚\ôŠq!şR¸\ß$¥tR'),(12,'Actions_actions_url',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœu”\rnƒ €\ï\â*ˆÖŠw\è­l’)4@\×fM\ï>~&£›X¿\÷\Ş\'\ñA0\Ä†AO0\nƒ?np1“‹^\á=.J\ÆGz/z†+sÁø²µ \ówh;\Ët&\n\â\Ú\0ú\Ñ$6\èW[­ú£½!s3«¦„º.ƒf8\Õ7!¿ş*ƒ@5°“\Ê8\ñ\Ó01­†\ÓSB›\Üu\ñ—ma|#›ùˆ\Ü7 x\ğPy)*¿©\ì*¯U\ç´ş\á`\ÕDVo¹\0Ø‡zA\ê½\ô\Û\0\Û\ÈIK\Â\ÕGL\Æ[\ísV1¼\Ú\È+\É¶«\ÌRªA¾*Š\ÜF±)\ÎT)\Æ?CT\åÓ \Õ\Ó\æ¹\×}t\ìj»\Å\Ö]\Şù,–\ËL5<Ù…m\ç\× ÿ•gœc\ì˜}^:C\ğadL´\òÑ«\ÏKg„\çk =1}İ®wuü\ä\à&¶³Í›tM\ë¦U(ù´¡Ä2¸Jw À“\Ö…\ËRQ\"\Ï\Ó\îGˆ\Ò\á\ö@x>jsp\æ'),(12,'Actions_downloads',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Actions_outlink',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Actions_sitesearch',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ\í“\ánƒ …\ß\ÅXk\í\ğú\nä¶²J&`„®KŒ\ï>HE¡I—\ì§&\ğ\Ëù\ïŒ\ğ\Äp\Ş\0.ı&Ç“\Â\Îz8\Ñ>k>\àLµ  U5#³\n»ì¦´ûªj[:4G\ÓP\ìMÇ•\Í8%‚\ê›?\íE\æsş–›\Ç±\'\Ò1­È\é.RFı\ŞÆ™XÕ‡\ïT¥\n¿\è\ìR\0±\÷¯Wv&\Ş~Q¨w=‚P)ÿ}\Ê?”{‚: xœ•gX–PP´’“a”gª—ˆ¥D)–¸\ÉÙ»=\ÑZ\æ\Ì=\×3Á‚\î,ù\ĞSÍ¤øİ²\é)](KÒ­‹	–‚\ô\Ú\'8P\'\'\Ø×£	*&T\Õı‚\"kf›70‡\é>s\\Ì¿fº§d\0\İEm,®\Í½¯ƒ½³]­ŠB]¸P£|\õ\ê-\Ôÿ\êr\ì\é2<ÿ\0\Óc‰'),(12,'Actions_SiteSearchCategories',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Contents_name_piece',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Contents_piece_name',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'DevicePlugins_plugin',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ…\ĞA‚0Ğ»\Ì	J‹¨¿w\ğŠŒAŠC¸»İ¸\Ğv\÷\ó3ÿ-\Æ\à„•!´Úƒ\Ä\êq\09sµ´G*û¾eKš!C‘2\Ò#\çkHJ_\ö\â?r\íŒo¾\ñÛ‘Q\'\İ\ÍlÒŒŠ2\n4TuZÉ£\Ê\ô|q\ÙN\ÜÙ´uˆZ™\0Ö¸Á™·\ÓZ\×\ÂĞ³›\í\èø\ÖLi\î\ç$h\áG\Õ/¾³\'ß¿}\0ß²5'),(12,'DevicesDetection_brands',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=Œ»\rÀ Dw\ñ|B€s•¢¬\àH)\è(»+Ÿ\â\É\'½\ó	,zaÿBFo *\çU‰h;ˆ\ì‹{¯ŸÒ‚’:ŸY\ß–Iš„)=(‡¨z}ªFsü\ó\ĞAº¶\ó7V„\'0'),(12,'DevicesDetection_browserEngines',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=ŒK€ \ï\Ò€ˆÀ\ë\Üy4,ˆ$.\\\î.\õ·˜t’i^„F\ÍPa>	¨\',¨\Ä5\â\Û\ç´\íq†~\Şkz\× /\Í–…Œ±\ã;¶G\n\ÖIW%\î~o²¡P›¬-\Ü\Ú\n¶(‹'),(12,'DevicesDetection_browsers',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=Œ»\rÀ Dw\ñ|B€sŸ2;8R\n$:J\Ä\îÁ\nI\ñ\ä“\Şù½À°À!£7P•\ë®\Ä\rt\Äv\á\Ö\õSZPR\ç3\ë{Á6I“0¥\åU\ïo\Õhº#0\èC\×N\ãT|\'+'),(12,'DevicesDetection_browserVersions',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=Œ;€ D\ï²0\àŠÀlo\é0± ¡£$\Ü]\Ö_1™I\Ş\ä%X´#	üˆV\á@%g!© m\Ëq2$\ö\Íü6‹eE%\ËHq2(:¯x}®·\Æÿ»«\'Á uµ\í\Òû!\Ï(g'),(12,'DevicesDetection_models',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=ŒA\Â D¯bş	@ŠÀü•0^•\"±tG¸»üØºx™—\Ìd\"4Z†\â³K@«° o©Wh:_ù™\Ş\é“\ï‡Gª¯u^ˆ3\ô\ÆqK#k—\Î–¿Œi\àv”¬“ú\ô›*q\÷\÷.?\n­\ËÛ…{ÿ\ô\Ê-™'),(12,'DevicesDetection_os',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=Œ1€ ÿr/\0½\ÊX\ë0± ¡£$ü]. \Å\æ&™ÛĞ¨	Š#\ÌµÀ‚r¼ŸL\\º¡s?ˆ\ô\Ì2¯\éVƒ¼8Xú	kï±£\Z¬½W%\ì~n²¡P›¬]\Ü\Ú}L\'q'),(12,'DevicesDetection_osVersions',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=ŒK\n€0D\ï’Hc­µ“•¸\Ö;TpQp\ç²\ô\î&øYy\ä\r“Á¨N2ü	\õB\0y?N’K´Î‹°\ë8\ğ›ş½^;š\Ìù$¶R0h&MP\éA)D\Ó\ãSu\Æ\ñ\çf;µ\Ù\Ú&­\İI·(§'),(12,'DevicesDetection_types',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=ŒÁ\rÀ wahJg‡\îJ} \ñ\ã‰Ø½‰Jû8Å²F…g}¢`tD¸&\×\İ›YÛº\Ä]_]¶œ\Ê*\íJV¢†Wb²øx«\Ştú\õ´Ç˜¶v\òœ©•&'),(12,'Goals_ItemsCategory',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Goals_ItemsCategory_Cart',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Goals_ItemsName',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Goals_ItemsName_Cart',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Goals_ItemsSku',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Goals_ItemsSku_Cart',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Referrers_keywordByCampaign',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Referrers_keywordBySearchEngine',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Referrers_searchEngineByKeyword',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Referrers_type',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2´ªÎ´2°N´2†1,­ª‹­L­”r“Rs”¬3­‘°”6bmi\rÒ•ie0bKSs i•1Óµ }‰VVÕµ \İ~Öµµ\0ŸO#0'),(12,'Referrers_urlByAIAssistant',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Referrers_urlBySocialNetwork',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Referrers_urlByWebsite',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'Resolution_configuration',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=ŒA\n€ E\ï2\'\Ğ\Ì\Ô?«\Ú\ÕZ\î\Ú\â\İs\ÈZ|\æ\r\ï\ó#4J‚\â\óA@¹`A9g&¾ Û³\Í¯+\ëÑ©;Ø‰8A\÷ı\Z©‚¼8X\Æ\Æ\ßb›4 `\è\é­*a\÷s•…Rem\çZv±*'),(12,'Resolution_resolution',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=Œ\É	À0{\Ù\n\Ö\ñ­\í!=8‡Á?Æ½\ÇKÇ 	Œ\n–ûI\Æ\è\ğ V³‘t$q‘¯\ìI…y\ÙŞ´kb@I;›EO*\Ü\"-ü*-(û¨ux¦¬ŸúSÀS\ßv™\ó1$('),(12,'UserCountry_city',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=ŒA€ ÿ\Ò€\íü&H¸q$ü\İ6¢‡M\'™\íxŒ\n\'üA\Æ\è V®»‘t8I…_\Ù\ÖeU”\Ìq{®\Ø5IT2(‡húx«\Î8ş<m§\èü˜¶vÊœ\ô&'),(12,'UserCountry_country',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=ŒK\nÀ D\ï’ø©U\'w\è,t!¸“®Ä»7¡¶‹G\Şd\n,F…\áÿ…Œ\Ñ@­œW#\îp »WØ…[×‹´ ¤\Îg\Ö\÷ŠMHB\éA9D\Õû[5šãŸ§\îŒ©k\Ïù\0zg\'‡'),(12,'UserCountry_region',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=ŒA€ ÿ\Ò€\íü&H¸q$ü\İ6¢‡M\'™\íxŒ\n\'üA\Æ\è V®»‘t8I…_\Ù\ÖeU”\Ìq{®\Ø5IT2(‡húx«\Î8ş<m§\èü˜¶vÊœ\ô&'),(12,'UserId_users',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœK´2°ª®\0Oş'),(12,'UserLanguage_language',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ=Œ;\nÀ \ï²}@cŒú\ö¹ƒA\ÒH*\ñ\îq\ó+†˜\åEh´\Åæ“€VaA%\î©ß\é¬\Äúe~¯]ƒ¼4X2–\Ø\r(X\'y}^•¸û½\ËN„Bë²¶q\ï\n~(Š'),(12,'VisitorInterest_daysSinceLastVisit',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ\Ó=!\àÿ\"t\ã\Ç5n]º\İØµXpµ\Ğ\á¸ÿ^;thÛ‹’	¯‰\Ñ\ñZX\ÇÄ´\Ãke\ÇjI·¼¨X«s¾\çGZ®s~]J-Ïªba\ó¹d…*n…±j^[¢8\ïÿQb¥A)ú·b$e…$Å€‘+)$+NR,XY\ñ’\âÀ\ÉJ^V&I	d\å\ØU,«	p`1\Ø/s\Ë\è€š‡ı·L~\êwØ·-·›©\ß\ã\öO\Ñ YS¿\Ì\íQ\ä\İÁœ$i{\õ\ó/„'),(12,'VisitorInterest_pageGap',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ\Ñ1\n\Ã0Ğ»:\n,\ÙN\Ò\ï­\è\\\è`È–1\ä\î\Õ\èP\ò»}Y\Ò\äK\ØR\ë\Ègp\ì*d\í¯\÷*m‹˜š´\Ê I\Ú1`1Û‘r{—Š«sÅ™’5s%3¥h\áJaJ\ÕÊ•Ê”Ig®L—J,jé‹±\ß\Ì|\ÉD¶ø\ë?N³P§ª\'\îÜ™\ãv\ós\ô\áÅ€'),(12,'VisitorInterest_timeGap',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ\Ğ1\n\Ã0Ğ»:\n,\Ùqy\Ëz:²e¹{ÿ’¡\Ğ\ÚÚ¾Œü\ÔL‚›…\Ú,\ŞA\í<l2\Ú\Û\ë½S=,–@u3E)(©^›	š\ñ)\Ö\çı\ğŸA\á\èpt\äD\á\ìpb\×\ÉF{©J]h\Æb\ZX“CšFN™\òH‚‚+9¤y$A\á\Å#•®TŒ °”/J~S\Ë\ğ\ä%\ÈC\×\ÑP\×€Ê™'),(12,'VisitorInterest_visitsByVisitCount',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœ\Ó;\n\Ã0\à»:\n$ù•\È[\Ğ;¸\ĞÁ-£\Éİ«%Ğ¡H\Ş~?ø°e¹%™C°u‰w`™§d	G\ĞN]	\Ú\Ö\é(´k\é^”©)¶\×=a*ü£\à…=%B\ô•\è)	’¯$OÉ}%{J\â+\ÅS*T_©²Á\æ+›©$	;\ĞByw“\ÑLx¡Àd\÷¯f.q²[¸\èƒ\ëOÀ\Én\ãªwC^¢\ì^\ÖC1ÒƒŸt}Z['),(12,'VisitTime_localTime',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœµ\Ö1ƒ0DÑ»ø\Ì\Z^\î;)%\â\î	\ÄV¤(ª©Ö²À¿{\ö\ä\Öú6{3N\ë\"û¶z\ò°L\÷\Ç\Æcsv”ie\Æ:sY´e¦2»2ûs\î\Ç	“7¾\íÇ¿·º\ñ?\nM\Ôh\Ô4\ÑH£Qmi´\ÕD&M´£\ÑN\íi´\×D\Z4\ÑL£Y\'	*“.P©\ÎD.\Ã‘L\à4Ad8N\é\ÎD>‘P\àDAd8R¨Jaü\\\òq\\†\ğ\Î\ôú:/\äÔ¿\ï\ó\Ó\æM{]ÿ|_p·L\ä–q·L\õšºxN‰\Ü2\î–I\ÜÚŸ¬\é\Ê'),(12,'VisitTime_serverTime',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',_binary 'xœµ\ÖA\nƒ0„\á»\äÎ‹Q\ó¼C\ï`¡ÁK\ñ\î­6¡P\Úq5«Dı\õ#“[\ë\Û\ì\Í8y¬‹\ì\Û\ê\É\Ã2\İKƒ³£L+3Ö™Ë¢-3•Ù•ÙŸs?\î0y\ã\Û~\\{«şG¡‰\Zš&\Zi4j¢-¶šh¢Ñ¤‰v4\Úi¢=\öš\è@£ƒ&ši4k¢\à$¡š„\ñ\ó\×\Æqux\Âwz8\Ó\ë\ë~!§şıQœ§6\ïwU\×?\ä‚)‘S\àPA$8UYDZs‘W\à`A$8Y™Dj³‘[\Æİ²F”\åJ™j7u±)e\\)“(µ?H\Ê'),(15,'Actions_actions',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ}”]ƒ €¯\Òp€€V\Å;ø²oûbh\ËV²\nF\Ø\í&Mï¾Œ?”R»&\è\è|Œ_ÌŒœav•,©8£>(\ÙÕ°Œ¡D‡*\Ã0fh\÷¡\õ\î]\ğ\ñØ¢J2\â†A\nu§\"/!W.IšT\'W\Òp7¤ª\áB\İ\Å\Õ\İ3d¾û\Æ\Ê^4JØ‹¿lyKh\ê\ò\ÄI¨C\ÓJkš‹´mÂ‹\ç\"½TQ\Î0\÷\Ø\ÕqZ!şû\Â\Åe\ãg\\°I·lVn‘\É™5\å]\öş5\Ş%b0Ng&T\ìÈ•ù\ô2I2û-™;¹\è\ä\Î=œ<z¦2:Q„J\'\İ7Ã¨\Â©Î¡%[b1?\ëAI¯#\ÑW›\ØU\ò›–ÛªG\İ°R«I\õ_Í•û¤\"\õ–[<4ºVM§ùi5\Ùnr\Í\nM\îsu\Ü\ÙA\ÆM\à:†&¯€\0\î\Ê,‡,‰\ñ:\É\Å\Ü\à\Ä\á·0w\êÀÏ®)¤\íD3p\ÛNı’0ş\r\Ü˜\ç\Û\íC–d¨'),(15,'Actions_actions_url',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ}”nƒ @\ï\Âª€V\Å;\ô\n†V6\ÉT\Z¡k³¦w•R\êf‚|\òŸŸÂ—3\Ìî’¥5g\Ô»k–3\Ô\ó£\èQ­Ù¡D­¸¡Z2b†Aµ¯²¨ W-IšÖ­-fX¹€\Ô˜¨4Ã¶¤¾‘ƒhFa®júB\ğ\É.¥™\Í»ıxl:its•¦‹@\Øx.2\È1\Ê9][\Ç>h…ø\í—3”:ZL\ßbšmpEÀ&Û²Y¹E&dÖ”w\Ùûm¼K\Ä`œ\ÍL¨˜‰ú\ÃË¤9\È\ì·d\ä¢S:\Ïd|8E \ôN\å\ÔQ„J­\Zš\ó¤NBk9~†b”l‰\Åü¬%½^ŒD§\æ\ØU\ò/6«¶UOj8\÷\ÂH5:\Õ5CV:\öM3D[n1\ğr\Ñ\Õ\ØôŠ·«\É\ö%\÷Ğ¬\ğr\É}\î\ß\ì c;pmCWB\0«*/ $KGb¼vr\é‚¼8ü\ì!1t™\\\ïãŠ¡Î˜³fI¢ŸN\İ\îG©½üxüXŠa<'),(15,'Actions_downloads',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Actions_outlink',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Actions_sitesearch',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ\í“Qn\Ã D\ï\â\Ø8S|‡\\‘@cT–¡M¥\Èw/›‚1iû\ß|€fv\ßJ\ìPŒ\ğEà²£¸_np1\ĞŠ\Î\à.£†2C‹N`\äN5<\àjZv\İ\ŞT[W\ñ.‰’\Å\íYOoE\Ç\\{ƒ‘\ë¬¤Ö³°}bW4B%šo-\égNi\"¨\á\ÓŸs“cz\Ï\r\ÙDH/ù¾¸\Úh\'ª\Ìk„\Ü\æw\×\r\ÚFĞ»\è»\ìRBufZ’q\ÒGnŒP\'¯QŸz¿‡€vaˆ\Ô\âya”G†\Å@G-Ç[¡\Õ\ï\Å\ŞÅ–\ì@©a±€Z‘AS\ö\óSfƒ¶ZÀHq1h®Á˜á¢¸‚Á\îŒ\ô\ä>PØ“‘\Ú~¨B´\÷e!†\è%\áª˜YE°\òD\å3‚\Ïş\ßş!y!C>u\ó\ö\ÏkV'),(15,'Actions_SiteSearchCategories',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Contents_name_piece',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Contents_piece_name',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'DevicePlugins_plugin',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ}\ĞA‚0…\á»\ä…\"\ê\ë¼C„\"‘\"H\Æa¸»¸`§Y$\óO\ß\"Œq»GŠ%\â\0\n|\õ\\D*º®ONn“¸\õ»\ËV\Ö]\ö\Ãd\ë*p¬w\Ãü4R\Õ\È@wX\'¬JXP_Vº©\Â\ô|IÑŒ\Òz\İ9¨Nb@ƒ\ç\Ğ~ûA—r]J@Q\Â\ä‡ ·zÔ©£N¥ Ye7\ÇÖ—¢¾zı\0ZÄ¬m'),(15,'DevicesDetection_brands',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5Œ»\rÀ Dw\ñ|C8WY \Ê\n”‰±{LDŠwK>E/0,\ğ\È\è\rT\å~*qƒqS¬\â•]	Ë£’cR\İxn¤\åÖ®—`¾Ë˜M`\ĞÇœ9yŒ\\S$s'),(15,'DevicesDetection_browserEngines',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5ŒA€ ÿ\ÂX‘\î¼ù4ˆ$<ş\îB\ğ0\Ûn“6‚P34G˜\ß\Ôª\Ä3\Å\Ã\ï\éº\Å‹@‚6ÁNuBp^\î\Ê}&\ÃO%š«G\Òú¡Q[Ÿ9¸µü!%\Î'),(15,'DevicesDetection_browsers',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5Œ»\rÀ Dw\ñ˜O\ç2;)%b\÷˜ˆ\ï>–|ŒQa¤Àı!atP+\÷\ÓH:,(g’\n«°\â”S\ñÛƒ’BT=dmT\Ä\í\ÌûÅ›\ï2W+0s\Í\\2\çZ–$n'),(15,'DevicesDetection_browserVersions',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5Œ=€ …\ï\Âx\İ½CMH\Ø	w·¾\÷Ó¤O@\è–\î	½Á\ÃT¹Ÿj¸!\Â\ä\Ì\ä\Òf\r\ì\n)N‰Ê±\Ü+\ÉÕ“\çRAXN´^û]\Æl‹>\æ\Ì\Åc¼e%ª'),(15,'DevicesDetection_models',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5ŒKƒ0D¯‚r‚Ÿ\ñª@\\!´ŠŠ\nj\ØE¹;\n‹7KB\ô\Ğl\Ñ<aD0P›]Ü¦8€¨\×Ì«û¹¿W¾\ç~(\ö¨\Za\Ú\âFM/\Úq\õ\è‹•—Vß—”›…FLyf\â”.šr*\Ü'),(15,'DevicesDetection_os',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5Œ;€ D\ï²\'\0‘\Ù\ÊX\ë0± ¡£${wƒÅ›\ÙOf2,z\á\÷	½!€j¾ŸJ\Ü\ôC\ç~,ŠUœ²)~zPRˆª+’‚8\İ\Ú\ñ\æ»\È\Ø2ºŒš‹E^L$´'),(15,'DevicesDetection_osVersions',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5ŒÁ€ Cÿ…0LœHw2\õ0\ñ@Â#\á\ß¯İš´„š`%\ÂıG@-`˜\ï\')\Z˜s?„\ìDl$aVHqÊ¦,\ÃY	\ìUW\éS	~8Ñ¨,\öKZÿ\",j\ë3—´\ö9%\ê'),(15,'DevicesDetection_types',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2´ªÎ´2°N´2†1,­ª‹­L­”r“Rs”¬A‚™VF@l\Ä\Æ@l\Ä&P\Úˆ-MÍ¤T¥9”64„j11\0‹Ô‚x‰VVÕµ cü¬kk¿ù#X'),(15,'Events_action_category',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Events_action_name',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Events_category_action',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Events_category_name',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Events_name_action',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Events_name_category',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Goals_ItemsCategory',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Goals_ItemsCategory_Cart',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Goals_ItemsName',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Goals_ItemsName_Cart',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Goals_ItemsSku',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Goals_ItemsSku_Cart',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Referrers_keywordByCampaign',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Referrers_keywordBySearchEngine',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Referrers_searchEngineByKeyword',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Referrers_type',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5ŒAÀ ÿ\â¤j­\Ëúš\ô`\â­G\Ãß‹\r=³,\Â\ìˆ,Hh˜\nÂ\ë;\È\Ø\Ü\É8Œ\ì.F+\Õ\æÎ«\ŞQ\İD^\É\ñ»\è\ÚS×›“U_ÀR#Y'),(15,'Referrers_urlByAIAssistant',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Referrers_urlBySocialNetwork',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Referrers_urlByWebsite',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'Resolution_configuration',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5Œ;\n€0D\ï’d53[‰N\ïÁ\"`—F¹»‰\Å\Û\Ù˜I \Ô\Í	\óÿ\Ôu§\óº˜}\İ8F&\ã\õ¬Sœ1	$\Ì\Â\"˜¡V\Ö\Ëu\Ü3üP¢Q1úKZw	\Zµ\õ™ƒ[{Iş\'\Ñ'),(15,'Resolution_resolution',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5ŒK\nÀ D\ï\â	’úŸÜ¡w°Ğ…\à\ÎMA¼{c±‹7Ÿ@¦€1*H\n\ì2F‡‡iåº›‘\Ã.Ò“}0Rq(¬X%)n»W²ªA\ÖRE\ÜÎ¼_}—¹Za\Ì5sÊœ/\"€%\Ğ'),(15,'UserCountry_city',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5ŒAÀ ÿ\Â¤\ÖZ—?\ô4\éÁÄ›G\Ãß‹=»0\nÆ¨¢ˆ)	\Ô\ô~\ZIG\0‘Tl;\Ñ9}erJ\Ê>™†Š¼’y½\ì\á»\Ø\Ü\Ô}Ã¦\æ³`#\à'),(15,'UserCountry_country',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5ŒK€ D\ï\ÒP‘\é¼&.H\ØW¤w·\\¼ù4\é0F…“‚\ğ‡Œ\ÑA­\\w#\éğ §“Txƒ`Æ¶<\Z9&\Ó]\æFEZÎ¼^6\÷]t¶‡¡s\æ\Õ{$\Ê'),(15,'UserCountry_region',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5ŒAÀ ÿ\Â¤\ÖZ—?\ô4\éÁÄ›G\Ãß‹=»0\nÆ¨¢ˆ)	\Ô\ô~\ZIG\0‘Tl;\Ñ9}erJ\Ê>™†Š¼’y½\ì\á»\Ø\Ü\Ô}Ã¦\æ³`#\à'),(15,'UserId_users',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(15,'UserLanguage_language',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ5ŒA\nÀ ÿâ½ Uk\Íş¡Ø‚Az‘Ä¿w{˜M60Z†&†ıMD«\ğP…\ïTMŸ\í­Š2vÁV8·\Ô\Ñ¹™Œ°Ô˜Uqz&}|\Ö\Ç\ÌE½ûø%\Í'),(15,'VisitorInterest_daysSinceLastVisit',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ…\Ó=1\àÿRp4M?4\İ\\\Ünt•\n\n‡ƒ\'8\÷ß\Ãmš-/Jx\Û¯ƒ}mL{¼.œ\Ø\Í\í\ŞgW\Æ\Â\î\Òı\Ù\æ\Û\Ô\ß×±Œ\×\â\ê\à \ë\ö½\Z{^%Q\öÁ\Øy\ğ»\à\nÁP\È]ˆ–@@º,!BÔ…l		’.KÈu\áh	Š.œT!²;\Z‹@½¤’1­B½˜’	![ˆ\Ş\Í,•rK\Ñû)ek-zI\å1”\Ó!œ5eû\0\Ö\Ğ$­'),(15,'VisitorInterest_pageGap',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ…\Ñ;\Ã0\à» uD2\Ø$)l9@\ï\àJ,e\Ë\åî¥ƒ·\n¶_<¾ºR\Ñkh±®u\Ö\ëTQ8úûs€\ŞB\Ê\ö¹‡’\Ïù¦§j¯YFÎ„Š5j&4l±\Ğ2APbA2aÁ5–Ph\nR™ı%Ö\ğLş\Ï\ä[jr‰gf0=xŒûÒ£¾F'),(15,'VisitorInterest_timeGap',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ…\Ğ1\n\Ã0Ğ»:\n$\Ùqœ\ï­\è\\\èÈ–1\ä\îU‡Ğ¥µ¶’:Tp¬Ö‘®`8vL ­?_µ$¬Bm…µOÏ¹B½\ÑG=¥\ö¸\nÿ	Ïªœ\Ã\"#)—ÀHC£€Š\ßb’‡\È\ìÇ˜°\å@™\"\Å\Î\Ñ.%R\\\ğ¯\Ê).\ğ)u¨T¬\õ\Ë\èOf	\ß[Eov-s¾š·\Ã_'),(15,'VisitorInterest_visitsByVisitCount',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœ…\Ò=\n\Ã0\à»:\n$ù/‘· wp¡C [Æ»W²•§Á\æaÃ‡\Ş4)vn\ÆcZ¾ƒ\ÚyXµ´\Ï\÷gO\ã\ğ$$il¦>d\\¿i\Z\Û\é)×½\0%½ş+h$d\ÊXÈ‘P¨`¡DB¥Š…\Z	\ZZ$t\êXè‘°Ğ‚…\n\Å\ÒJ<\å\n	\ÏRIƒ\Ç\ÜK\ÏÚ¨r€\àj6ÿTo7G\n®g\÷û°†\î¨FYúD\Ê\õ\÷@c'),(15,'VisitTime_localTime',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœµ\Ö1ƒ0DÑ»pfm^\î;)]J\Ä\İÑºd¨¦ZkeùwO^Ü²\ï«\÷\ó\â©ª\ï_/\Şm\Ëû³u\óµ\\\İb¦˜9f‰9\Äc\íbÿ?\ç\ê|»\÷ı¸yµ\Å}¢ªÑª‰ª‰V“¨ši5‹ª…V‹¨:\Ğ\ê ª´:Šª­N¢j¥\Õ*ª‚\ã™N<©|\n*¡À‰‚\Ê(p¤ R\nœ)¨œ‡\n*©À©‚\Ê*p¬ \Ò\nœ+4¯\İ)ºStk\ï\Ê\àe\ãb™J,\ãb™\ìG\õ\ğ¥R‰e\\,Óˆuü\0a\á¼'),(15,'VisitTime_serverTime',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',_binary 'xœµ\Ö1ƒ0DÑ»p\Ï\Ú¼\Ü!w R\n$º”ˆ»¢¥d¨¦ZkeùwOİŠo‹§i\ö|šo_¯Ş­\óû³vÓ¹\\\Üb\æ˜%f\Ù\Çb\×\Å\ô?\ì\Ç\êx;ù¶Ÿ¼®\Å}¢ªÑª‰ª™V³¨Zhµˆª•V«¨\Ú\Ój/ª´:ˆª#­¢j£\Õ&ª‚\ã„K\'DwŒ\î\İV‡»2\Ê@©„\'\n*£À‘‚J)p¦ r\n*¨¤§\n*«À±‚J+p® \ò\n,¨\Ä2.–%U—{e²\ÕÃ—J\å•q¯L\ã\ÕşE\r¼'),(16,'Actions_actions',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ}”]ƒ €¯\Òp€€V\Å;ø²oûbh\ËV²\nF\Ø\í&Mï¾Œ?”R»&\è\è|Œ_ÌŒœav•,©8£>(\ÙÕ°Œ¡D‡*\Ã0fh\÷¡\õ\î]\ğ\ñØ¢J2\â†A\nu§\"/!W.IšT\'W\Òp7¤ª\áB\İ\Å\Õ\İ3d¾û\Æ\Ê^4JØ‹¿lyKh\ê\ò\ÄI¨C\ÓJkš‹´mÂ‹\ç\"½TQ\Î0\÷\Ø\ÕqZ!şû\Â\Åe\ãg\\°I·lVn‘\É™5\å]\öş5\Ş%b0Ng&T\ìÈ•ù\ô2I2û-™;¹\è\ä\Î=œ<z¦2:Q„J\'\İ7Ã¨\Â©Î¡%[b1?\ëAI¯#\ÑW›\ØU\ò›–ÛªG\İ°R«I\õ_Í•û¤\"\õ–[<4ºVM§ùi5\Ùnr\Í\nM\îsu\Ü\ÙA\ÆM\à:†&¯€\0\î\Ê,‡,‰\ñ:\É\Å\Ü\à\Ä\á·0w\êÀÏ®)¤\íD3p\ÛNı’0ş\r\Ü˜\ç\Û\íC–d¨'),(16,'Actions_actions_url',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ}”nƒ @\ï\Âª€V\Å;\ô\n†V6\ÉT\Z¡k³¦w•R\êf‚|\òŸŸÂ—3\Ìî’¥5g\Ô»k–3\Ô\ó£\èQ­Ù¡D­¸¡Z2b†Aµ¯²¨ W-IšÖ­-fX¹€\Ô˜¨4Ã¶¤¾‘ƒhFa®júB\ğ\É.¥™\Í»ıxl:its•¦‹@\Øx.2\È1\Ê9][\Ç>h…ø\í—3”:ZL\ßbšmpEÀ&Û²Y¹E&dÖ”w\Ùûm¼K\Ä`œ\ÍL¨˜‰ú\ÃË¤9\È\ì·d\ä¢S:\Ïd|8E \ôN\å\ÔQ„J­\Zš\ó¤NBk9~†b”l‰\Åü¬%½^ŒD§\æ\ØU\ò/6«¶UOj8\÷\ÂH5:\Õ5CV:\öM3D[n1\ğr\Ñ\Õ\ØôŠ·«\É\ö%\÷Ğ¬\ğr\É}\î\ß\ì c;pmCWB\0«*/ $KGb¼vr\é‚¼8ü\ì!1t™\\\ïãŠ¡Î˜³fI¢ŸN\İ\îG©½üxüXŠa<'),(16,'Actions_downloads',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Actions_outlink',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Actions_sitesearch',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ\í“Qn\Ã D\ï\â\Ø8S|‡\\‘@cT–¡M¥\Èw/›‚1iû\ß|€fv\ßJ\ìPŒ\ğEà²£¸_np1\ĞŠ\Î\à.£†2C‹N`\äN5<\àjZv\İ\ŞT[W\ñ.‰’\Å\íYOoE\Ç\\{ƒ‘\ë¬¤Ö³°}bW4B%šo-\égNi\"¨\á\ÓŸs“cz\Ï\r\ÙDH/ù¾¸\Úh\'ª\Ìk„\Ü\æw\×\r\ÚFĞ»\è»\ìRBufZ’q\ÒGnŒP\'¯QŸz¿‡€vaˆ\Ô\âya”G†\Å@G-Ç[¡\Õ\ï\Å\ŞÅ–\ì@©a±€Z‘AS\ö\óSfƒ¶ZÀHq1h®Á˜á¢¸‚Á\îŒ\ô\ä>PØ“‘\Ú~¨B´\÷e!†\è%\áª˜YE°\òD\å3‚\Ïş\ßş!y!C>u\ó\ö\ÏkV'),(16,'Actions_SiteSearchCategories',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Contents_name_piece',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Contents_piece_name',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'DevicePlugins_plugin',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ}\ĞA‚0…\á»\ä…\"\ê\ë¼C„\"‘\"H\Æa¸»¸`§Y$\óO\ß\"Œq»GŠ%\â\0\n|\õ\\D*º®ONn“¸\õ»\ËV\Ö]\ö\Ãd\ë*p¬w\Ãü4R\Õ\È@wX\'¬JXP_Vº©\Â\ô|IÑŒ\Òz\İ9¨Nb@ƒ\ç\Ğ~ûA—r]J@Q\Â\ä‡ ·zÔ©£N¥ Ye7\ÇÖ—¢¾zı\0ZÄ¬m'),(16,'DevicesDetection_brands',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5Œ»\rÀ Dw\ñ|C8WY \Ê\n”‰±{LDŠwK>E/0,\ğ\È\è\rT\å~*qƒqS¬\â•]	Ë£’cR\İxn¤\åÖ®—`¾Ë˜M`\ĞÇœ9yŒ\\S$s'),(16,'DevicesDetection_browserEngines',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5ŒA€ ÿ\ÂX‘\î¼ù4ˆ$<ş\îB\ğ0\Ûn“6‚P34G˜\ß\Ôª\Ä3\Å\Ã\ï\éº\Å‹@‚6ÁNuBp^\î\Ê}&\ÃO%š«G\Òú¡Q[Ÿ9¸µü!%\Î'),(16,'DevicesDetection_browsers',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5Œ»\rÀ Dw\ñ˜O\ç2;)%b\÷˜ˆ\ï>–|ŒQa¤Àı!atP+\÷\ÓH:,(g’\n«°\â”S\ñÛƒ’BT=dmT\Ä\í\ÌûÅ›\ï2W+0s\Í\\2\çZ–$n'),(16,'DevicesDetection_browserVersions',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5Œ=€ …\ï\Âx\İ½CMH\Ø	w·¾\÷Ó¤O@\è–\î	½Á\ÃT¹Ÿj¸!\Â\ä\Ì\ä\Òf\r\ì\n)N‰Ê±\Ü+\ÉÕ“\çRAXN´^û]\Æl‹>\æ\Ì\Åc¼e%ª'),(16,'DevicesDetection_models',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5ŒKƒ0D¯‚r‚Ÿ\ñª@\\!´ŠŠ\nj\ØE¹;\n‹7KB\ô\Ğl\Ñ<aD0P›]Ü¦8€¨\×Ì«û¹¿W¾\ç~(\ö¨\Za\Ú\âFM/\Úq\õ\è‹•—Vß—”›…FLyf\â”.šr*\Ü'),(16,'DevicesDetection_os',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5Œ;€ D\ï²\'\0‘\Ù\ÊX\ë0± ¡£${wƒÅ›\ÙOf2,z\á\÷	½!€j¾ŸJ\Ü\ôC\ç~,ŠUœ²)~zPRˆª+’‚8\İ\Ú\ñ\æ»\È\Ø2ºŒš‹E^L$´'),(16,'DevicesDetection_osVersions',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5ŒÁ€ Cÿ…0LœHw2\õ0\ñ@Â#\á\ß¯İš´„š`%\ÂıG@-`˜\ï\')\Z˜s?„\ìDl$aVHqÊ¦,\ÃY	\ìUW\éS	~8Ñ¨,\öKZÿ\",j\ë3—´\ö9%\ê'),(16,'DevicesDetection_types',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2´ªÎ´2°N´2†1,­ª‹­L­”r“Rs”¬A‚™VF@l\Ä\Æ@l\Ä&P\Úˆ-MÍ¤T¥9”64„j11\0‹Ô‚x‰VVÕµ cü¬kk¿ù#X'),(16,'Events_action_category',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Events_action_name',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Events_category_action',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Events_category_name',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Events_name_action',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Events_name_category',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Goals_ItemsCategory',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Goals_ItemsCategory_Cart',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Goals_ItemsName',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Goals_ItemsName_Cart',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Goals_ItemsSku',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Goals_ItemsSku_Cart',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Referrers_keywordByCampaign',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Referrers_keywordBySearchEngine',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Referrers_searchEngineByKeyword',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Referrers_type',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5ŒAÀ ÿ\â¤j­\Ëúš\ô`\â­G\Ãß‹\r=³,\Â\ìˆ,Hh˜\nÂ\ë;\È\Ø\Ü\É8Œ\ì.F+\Õ\æÎ«\ŞQ\İD^\É\ñ»\è\ÚS×›“U_ÀR#Y'),(16,'Referrers_urlByAIAssistant',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Referrers_urlBySocialNetwork',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Referrers_urlByWebsite',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'Resolution_configuration',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5Œ;\n€0D\ï’d53[‰N\ïÁ\"`—F¹»‰\Å\Û\Ù˜I \Ô\Í	\óÿ\Ôu§\óº˜}\İ8F&\ã\õ¬Sœ1	$\Ì\Â\"˜¡V\Ö\Ëu\Ü3üP¢Q1úKZw	\Zµ\õ™ƒ[{Iş\'\Ñ'),(16,'Resolution_resolution',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5ŒK\nÀ D\ï\â	’úŸÜ¡w°Ğ…\à\ÎMA¼{c±‹7Ÿ@¦€1*H\n\ì2F‡‡iåº›‘\Ã.Ò“}0Rq(¬X%)n»W²ªA\ÖRE\ÜÎ¼_}—¹Za\Ì5sÊœ/\"€%\Ğ'),(16,'UserCountry_city',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5ŒAÀ ÿ\Â¤\ÖZ—?\ô4\éÁÄ›G\Ãß‹=»0\nÆ¨¢ˆ)	\Ô\ô~\ZIG\0‘Tl;\Ñ9}erJ\Ê>™†Š¼’y½\ì\á»\Ø\Ü\Ô}Ã¦\æ³`#\à'),(16,'UserCountry_country',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5ŒK€ D\ï\ÒP‘\é¼&.H\ØW¤w·\\¼ù4\é0F…“‚\ğ‡Œ\ÑA­\\w#\éğ §“Txƒ`Æ¶<\Z9&\Ó]\æFEZÎ¼^6\÷]t¶‡¡s\æ\Õ{$\Ê'),(16,'UserCountry_region',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5ŒAÀ ÿ\Â¤\ÖZ—?\ô4\éÁÄ›G\Ãß‹=»0\nÆ¨¢ˆ)	\Ô\ô~\ZIG\0‘Tl;\Ñ9}erJ\Ê>™†Š¼’y½\ì\á»\Ø\Ü\Ô}Ã¦\æ³`#\à'),(16,'UserId_users',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(16,'UserLanguage_language',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ5ŒA\nÀ ÿâ½ Uk\Íş¡Ø‚Az‘Ä¿w{˜M60Z†&†ıMD«\ğP…\ïTMŸ\í­Š2vÁV8·\Ô\Ñ¹™Œ°Ô˜Uqz&}|\Ö\Ç\ÌE½ûø%\Í'),(16,'VisitorInterest_daysSinceLastVisit',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ…\Ó=1\àÿRp4M?4\İ\\\Ünt•\n\n‡ƒ\'8\÷ß\Ãmš-/Jx\Û¯ƒ}mL{¼.œ\Ø\Í\í\ŞgW\Æ\Â\î\Òı\Ù\æ\Û\Ô\ß×±Œ\×\â\ê\à \ë\ö½\Z{^%Q\öÁ\Øy\ğ»\à\nÁP\È]ˆ–@@º,!BÔ…l		’.KÈu\áh	Š.œT!²;\Z‹@½¤’1­B½˜’	![ˆ\Ş\Í,•rK\Ñû)ek-zI\å1”\Ó!œ5eû\0\Ö\Ğ$­'),(16,'VisitorInterest_pageGap',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ…\Ñ;\Ã0\à» uD2\Ø$)l9@\ï\àJ,e\Ë\åî¥ƒ·\n¶_<¾ºR\Ñkh±®u\Ö\ëTQ8úûs€\ŞB\Ê\ö¹‡’\Ïù¦§j¯YFÎ„Š5j&4l±\Ğ2APbA2aÁ5–Ph\nR™ı%Ö\ğLş\Ï\ä[jr‰gf0=xŒûÒ£¾F'),(16,'VisitorInterest_timeGap',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ…\Ğ1\n\Ã0Ğ»:\n$\Ùqœ\ï­\è\\\èÈ–1\ä\îU‡Ğ¥µ¶’:Tp¬Ö‘®`8vL ­?_µ$¬Bm…µOÏ¹B½\ÑG=¥\ö¸\nÿ	Ïªœ\Ã\"#)—ÀHC£€Š\ßb’‡\È\ìÇ˜°\å@™\"\Å\Î\Ñ.%R\\\ğ¯\Ê).\ğ)u¨T¬\õ\Ë\èOf	\ß[Eov-s¾š·\Ã_'),(16,'VisitorInterest_visitsByVisitCount',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœ…\Ò=\n\Ã0\à»:\n$ù/‘· wp¡C [Æ»W²•§Á\æaÃ‡\Ş4)vn\ÆcZ¾ƒ\ÚyXµ´\Ï\÷gO\ã\ğ$$il¦>d\\¿i\Z\Û\é)×½\0%½ş+h$d\ÊXÈ‘P¨`¡DB¥Š…\Z	\ZZ$t\êXè‘°Ğ‚…\n\Å\ÒJ<\å\n	\ÏRIƒ\Ç\ÜK\ÏÚ¨r€\àj6ÿTo7G\n®g\÷û°†\î¨FYúD\Ê\õ\÷@c'),(16,'VisitTime_localTime',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœµ\Ö1ƒ0DÑ»pfm^\î;)]J\Ä\İÑºd¨¦ZkeùwO^Ü²\ï«\÷\ó\â©ª\ï_/\Şm\Ëû³u\óµ\\\İb¦˜9f‰9\Äc\íbÿ?\ç\ê|»\÷ı¸yµ\Å}¢ªÑª‰ª‰V“¨ši5‹ª…V‹¨:\Ğ\ê ª´:Šª­N¢j¥\Õ*ª‚\ã™N<©|\n*¡À‰‚\Ê(p¤ R\nœ)¨œ‡\n*©À©‚\Ê*p¬ \Ò\nœ+4¯\İ)ºStk\ï\Ê\àe\ãb™J,\ãb™\ìG\õ\ğ¥R‰e\\,Óˆuü\0a\á¼'),(16,'VisitTime_serverTime',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',_binary 'xœµ\Ö1ƒ0DÑ»p\Ï\Ú¼\Ü!w R\n$º”ˆ»¢¥d¨¦ZkeùwOİŠo‹§i\ö|šo_¯Ş­\óû³vÓ¹\\\Üb\æ˜%f\Ù\Çb\×\Å\ô?\ì\Ç\êx;ù¶Ÿ¼®\Å}¢ªÑª‰ª™V³¨Zhµˆª•V«¨\Ú\Ój/ª´:ˆª#­¢j£\Õ&ª‚\ã„K\'DwŒ\î\İV‡»2\Ê@©„\'\n*£À‘‚J)p¦ r\n*¨¤§\n*«À±‚J+p® \ò\n,¨\Ä2.–%U—{e²\ÕÃ—J\å•q¯L\ã\ÕşE\r¼'),(17,'Goals_ItemsCategory',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(17,'Goals_ItemsCategory_Cart',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(17,'Goals_ItemsName',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(17,'Goals_ItemsName_Cart',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(17,'Goals_ItemsSku',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş'),(17,'Goals_ItemsSku_Cart',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:34',_binary 'xœK´2°ª®\0Oş');
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
INSERT INTO `matomo_archive_numeric_2025_11` VALUES (12,'Actions_hits',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',8),(12,'Actions_nb_downloads',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'Actions_nb_hits_with_time_generation',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'Actions_nb_keywords',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',2),(12,'Actions_nb_outlinks',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'Actions_nb_pageviews',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',4),(12,'Actions_nb_searches',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',4),(12,'Actions_nb_uniq_downloads',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'Actions_nb_uniq_outlinks',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'Actions_nb_uniq_pageviews',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',1),(12,'Actions_sum_time_generation',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'bounce_count',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'done',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',1),(12,'max_actions',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',8),(12,'nb_actions',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',8),(12,'nb_uniq_visitors',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',1),(12,'nb_users',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'nb_visits',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',1),(12,'nb_visits_converted',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'PagePerformance_domcompletion_hits',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'PagePerformance_domcompletion_time',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'PagePerformance_domprocessing_hits',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',4),(12,'PagePerformance_domprocessing_time',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',105),(12,'PagePerformance_network_hits',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',4),(12,'PagePerformance_network_time',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',34),(12,'PagePerformance_onload_hits',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'PagePerformance_onload_time',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'PagePerformance_pageload_hits',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',4),(12,'PagePerformance_pageload_time',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',436),(12,'PagePerformance_server_hits',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',4),(12,'PagePerformance_servery_time',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',192),(12,'PagePerformance_transfer_hits',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',4),(12,'PagePerformance_transfer_time',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',105),(12,'Referrers_distinctAIAssistants',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'Referrers_distinctCampaigns',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'Referrers_distinctKeywords',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'Referrers_distinctSearchEngines',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'Referrers_distinctSocialNetworks',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'Referrers_distinctWebsites',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'Referrers_distinctWebsitesUrls',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(12,'sum_visit_length',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',957),(12,'UserCountry_distinctCountries',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',1),(13,'bounce_count',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(13,'done90a5a511e1974bca37613b6daec137ba.VisitsSummary',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',1),(13,'max_actions',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',8),(13,'nb_actions',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',8),(13,'nb_uniq_visitors',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',1),(13,'nb_users',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(13,'nb_visits',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',1),(13,'nb_visits_converted',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(13,'sum_visit_length',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',957),(14,'bounce_count',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(14,'donefea44bece172bc9696ae57c26888bf8a.VisitsSummary',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',1),(14,'max_actions',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(14,'nb_actions',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(14,'nb_uniq_visitors',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(14,'nb_users',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(14,'nb_visits',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(14,'nb_visits_converted',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(14,'sum_visit_length',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:33',0),(15,'Actions_hits',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',8),(15,'Actions_nb_downloads',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'Actions_nb_hits_with_time_generation',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'Actions_nb_keywords',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',2),(15,'Actions_nb_outlinks',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'Actions_nb_pageviews',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',4),(15,'Actions_nb_searches',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',4),(15,'Actions_nb_uniq_downloads',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'Actions_nb_uniq_outlinks',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'Actions_nb_uniq_pageviews',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',1),(15,'Actions_sum_time_generation',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'bounce_count',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'done',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',1),(15,'max_actions',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',8),(15,'nb_actions',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',8),(15,'nb_uniq_visitors',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',1),(15,'nb_users',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'nb_visits',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',1),(15,'nb_visits_converted',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'PagePerformance_domcompletion_hits',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'PagePerformance_domcompletion_time',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'PagePerformance_domprocessing_hits',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',4),(15,'PagePerformance_domprocessing_time',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',105),(15,'PagePerformance_network_hits',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',4),(15,'PagePerformance_network_time',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',34),(15,'PagePerformance_onload_hits',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'PagePerformance_onload_time',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'PagePerformance_pageload_hits',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',4),(15,'PagePerformance_pageload_time',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',436),(15,'PagePerformance_server_hits',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',4),(15,'PagePerformance_servery_time',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',192),(15,'PagePerformance_transfer_hits',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',4),(15,'PagePerformance_transfer_time',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',105),(15,'Referrers_distinctAIAssistants',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'Referrers_distinctCampaigns',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'Referrers_distinctKeywords',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'Referrers_distinctSearchEngines',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'Referrers_distinctSocialNetworks',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'Referrers_distinctWebsites',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'Referrers_distinctWebsitesUrls',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(15,'sum_visit_length',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',957),(15,'UserCountry_distinctCountries',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',1),(16,'Actions_hits',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',8),(16,'Actions_nb_downloads',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'Actions_nb_hits_with_time_generation',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'Actions_nb_keywords',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',2),(16,'Actions_nb_outlinks',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'Actions_nb_pageviews',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',4),(16,'Actions_nb_searches',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',4),(16,'Actions_nb_uniq_downloads',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'Actions_nb_uniq_outlinks',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'Actions_nb_uniq_pageviews',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',1),(16,'Actions_sum_time_generation',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'bounce_count',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'done',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',1),(16,'max_actions',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',8),(16,'nb_actions',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',8),(16,'nb_uniq_visitors',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',1),(16,'nb_users',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'nb_visits',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',1),(16,'nb_visits_converted',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'PagePerformance_domcompletion_hits',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'PagePerformance_domcompletion_time',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'PagePerformance_domprocessing_hits',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',4),(16,'PagePerformance_domprocessing_time',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',105),(16,'PagePerformance_network_hits',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',4),(16,'PagePerformance_network_time',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',34),(16,'PagePerformance_onload_hits',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'PagePerformance_onload_time',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'PagePerformance_pageload_hits',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',4),(16,'PagePerformance_pageload_time',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',436),(16,'PagePerformance_server_hits',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',4),(16,'PagePerformance_servery_time',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',192),(16,'PagePerformance_transfer_hits',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',4),(16,'PagePerformance_transfer_time',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',105),(16,'Referrers_distinctAIAssistants',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'Referrers_distinctCampaigns',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'Referrers_distinctKeywords',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'Referrers_distinctSearchEngines',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'Referrers_distinctSocialNetworks',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'Referrers_distinctWebsites',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'Referrers_distinctWebsitesUrls',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(16,'sum_visit_length',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',957),(16,'UserCountry_distinctCountries',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',1),(17,'done90a5a511e1974bca37613b6daec137ba.Goals',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:34',1),(18,'bounce_count',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(18,'done90a5a511e1974bca37613b6daec137ba.VisitsSummary',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',1),(18,'max_actions',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',8),(18,'nb_actions',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',8),(18,'nb_uniq_visitors',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',1),(18,'nb_users',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(18,'nb_visits',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',1),(18,'nb_visits_converted',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(18,'sum_visit_length',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',957),(19,'bounce_count',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(19,'donefea44bece172bc9696ae57c26888bf8a.VisitsSummary',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',1),(19,'max_actions',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(19,'nb_actions',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(19,'nb_uniq_visitors',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(19,'nb_users',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(19,'nb_visits',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(19,'nb_visits_converted',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(19,'sum_visit_length',2,'2025-11-10','2025-11-16',2,'2025-11-10 19:03:34',0),(20,'donefea44bece172bc9696ae57c26888bf8a.Goals',2,'2025-11-10','2025-11-10',1,'2025-11-10 19:03:34',1),(21,'bounce_count',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(21,'done90a5a511e1974bca37613b6daec137ba.VisitsSummary',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',1),(21,'max_actions',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',8),(21,'nb_actions',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',8),(21,'nb_uniq_visitors',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',1),(21,'nb_users',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(21,'nb_visits',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',1),(21,'nb_visits_converted',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(21,'sum_visit_length',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',957),(22,'bounce_count',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(22,'donefea44bece172bc9696ae57c26888bf8a.VisitsSummary',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',1),(22,'max_actions',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(22,'nb_actions',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(22,'nb_uniq_visitors',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(22,'nb_users',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(22,'nb_visits',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(22,'nb_visits_converted',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0),(22,'sum_visit_length',2,'2025-11-01','2025-11-30',3,'2025-11-10 19:03:34',0);
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_log_action`
--

LOCK TABLES `matomo_log_action` WRITE;
/*!40000 ALTER TABLE `matomo_log_action` DISABLE KEYS */;
INSERT INTO `matomo_log_action` VALUES (1,'Zoo Search',177128507,4,NULL),(2,'search.zoo/',2958132702,1,2),(3,'sdds',3750575543,8,NULL),(4,'sdasadsa',3074289517,8,NULL);
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
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_log_link_visit_action`
--

LOCK TABLES `matomo_log_link_visit_action` WRITE;
/*!40000 ALTER TABLE `matomo_log_link_visit_action` DISABLE KEYS */;
INSERT INTO `matomo_log_link_visit_action` VALUES (1,2,_binary 'Unb\İ@x ',1,0,0,NULL,1,'2025-11-10 18:47:30','dSu4Vr',1,2,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,49,4,NULL,10,52,NULL,NULL,NULL,NULL,NULL,NULL),(2,2,_binary 'Unb\İ@x ',1,2,1,NULL,2,'2025-11-10 18:57:44','Qit3n4',1,2,NULL,NULL,614,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,40,12,NULL,114,0,NULL,NULL,NULL,NULL,NULL,NULL),(3,2,_binary 'Unb\İ@x ',1,2,1,NULL,3,'2025-11-10 19:01:48','RdwNGo',1,2,NULL,NULL,244,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,6,0,NULL,62,0,NULL,NULL,NULL,NULL,NULL,NULL),(4,2,_binary 'Unb\İ@x ',1,2,1,NULL,4,'2025-11-10 19:02:07','qyfD5C',3,NULL,'',NULL,19,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(5,2,_binary 'Unb\İ@x ',1,NULL,3,NULL,5,'2025-11-10 19:02:27','FlKpko',1,2,NULL,NULL,20,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,10,18,NULL,6,53,NULL,NULL,NULL,NULL,NULL,NULL),(6,2,_binary 'Unb\İ@x ',1,2,1,NULL,6,'2025-11-10 19:02:29','MzBjv4',4,NULL,'',NULL,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(7,2,_binary 'Unb\İ@x ',1,NULL,4,NULL,7,'2025-11-10 19:03:22','xbcl89',4,NULL,'',NULL,53,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(8,2,_binary 'Unb\İ@x ',1,NULL,4,NULL,8,'2025-11-10 19:03:26','isoCDy',4,NULL,'',NULL,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(9,2,_binary 'Unb\İ@x ',1,NULL,4,NULL,9,'2025-11-10 19:03:37','B5IWXQ',4,NULL,'',NULL,11,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
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
INSERT INTO `matomo_log_visit` VALUES (1,2,_binary 'Unb\İ@x ','2025-11-10 19:03:37',_binary '\ØÁ@{•¦.}',_binary '¬\0\0',1,NULL,'2025-11-10 18:47:30',0,0,0,0,NULL,1,1,2,4,NULL,9,9,5,NULL,NULL,1,'','en-us','Gecko','FF','139.0',1,'AP','generic desktop',0,'MAC','10.15',0,'19:47:30',0,'1470x956',1,0,0,0,0,0,0,0,968,NULL,'us',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
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
INSERT INTO `matomo_option` VALUES ('AIAssistantDefinitions','YToxNzp7czoxNToieWl5YW4uYmFpZHUuY29tIjtzOjg6IkJhaWR1IEFJIjtzOjEyOiJhaS5iYWlkdS5jb20iO3M6ODoiQmFpZHUgQUkiO3M6MTE6ImNoYXRncHQuY29tIjtzOjc6IkNoYXRHUFQiO3M6MTU6ImNoYXQub3BlbmFpLmNvbSI7czo3OiJDaGF0R1BUIjtzOjE1OiJsYWJzLm9wZW5haS5jb20iO3M6NzoiQ2hhdEdQVCI7czo5OiJjbGF1ZGUuYWkiO3M6NjoiQ2xhdWRlIjtzOjIxOiJjb3BpbG90Lm1pY3Jvc29mdC5jb20iO3M6NzoiQ29waWxvdCI7czoxMDoiY2hhdGdsbS5jbiI7czo3OiJDaGF0R0xNIjtzOjE3OiJjaGF0LmRlZXBzZWVrLmNvbSI7czo4OiJEZWVwc2VlayI7czoxNzoiZ2VtaW5pLmdvb2dsZS5jb20iO3M6NjoiR2VtaW5pIjtzOjE1OiJiYXJkLmdvb2dsZS5jb20iO3M6NjoiR2VtaW5pIjtzOjg6Imdyb2suY29tIjtzOjQ6Ikdyb2siO3M6NzoiaWFzay5haSI7czo0OiJpQXNrIjtzOjE1OiJjaGF0Lm1pc3RyYWwuYWkiO3M6NzoiTGUgQ2hhdCI7czo3OiJtZXRhLmFpIjtzOjc6Ik1ldGEgQUkiO3M6MTM6InBlcnBsZXhpdHkuYWkiO3M6MTA6IlBlcnBsZXhpdHkiO3M6NzoieW91LmNvbSI7czozOiJZb3UiO30=',0),('Feedback.nextFeedbackReminder.analytics_user','2026-05-10',0),('fingerprint_salt_1_2025-11-08','{\"value\":\"fiumvbr568tyyyjbae88h1yjd62bikhb\",\"time\":1762783418}',0),('fingerprint_salt_1_2025-11-09','{\"value\":\"2ztjy7viffig60w9z4gllg0xpnf6wkam\",\"time\":1762783418}',0),('fingerprint_salt_1_2025-11-10','{\"value\":\"tuxz9ovfuy7wirmc0siimhb2iyr8rdhb\",\"time\":1762783418}',0),('fingerprint_salt_1_2025-11-11','{\"value\":\"dribspcf8uacnf60so8nojf64e5mmpzd\",\"time\":1762783418}',0),('fingerprint_salt_2_2025-11-08','{\"value\":\"2tj1sxoe5hnrigznjehi89ihwp7jub5f\",\"time\":1762800086}',0),('fingerprint_salt_2_2025-11-09','{\"value\":\"98wykku57ff8h0ynsmnb8dbz66x2isd2\",\"time\":1762800086}',0),('fingerprint_salt_2_2025-11-10','{\"value\":\"n57atcxm1cc437iegtk3frjnjpr12ga8\",\"time\":1762800086}',0),('fingerprint_salt_2_2025-11-11','{\"value\":\"5k1f1u9yg488b7wuoiz9bpz3upmpsnwj\",\"time\":1762800086}',0),('fingerprint_salt_3_2025-11-08','{\"value\":\"43trtntv7i9y0fg83aw54vefe4snnv1u\",\"time\":1762801267}',0),('fingerprint_salt_3_2025-11-09','{\"value\":\"uizcujpr78mn1ctyfwya0cjmlxpr1np5\",\"time\":1762801267}',0),('fingerprint_salt_3_2025-11-10','{\"value\":\"ylo2y678mirie91ed3p52n97lb449tpg\",\"time\":1762801267}',0),('fingerprint_salt_3_2025-11-11','{\"value\":\"lifj8xj56zdppvyuj75sxuaizk2c90ee\",\"time\":1762801267}',0),('geoip2.autosetup','1',0),('geoip2.loc_db_url','https://download.db-ip.com/free/dbip-city-lite-2025-11.mmdb.gz',0),('geoip2.updater_last_run_time','1762732800',0),('geoip2.updater_period','month',0),('install_mail_sent','1',0),('install_version','5.5.1',0),('InvalidatedOldReports_DatesWebsiteIds','a:2:{i:0;s:7:\"2025_11\";i:1;s:7:\"2025_01\";}',0),('JsTrackerInstallCheck_1','{\"df657c2c8d66026834bc94a7268d24ce\":{\"time\":1762786357,\"url\":\"https:\\/\\/snappymail.zoo\",\"isSuccessful\":false}}',0),('lastTrackerCronRun','1762800450',0),('MatomoUpdateHistory','5.5.1,',0),('MobileMessaging_DelegatedManagement','false',0),('piwikUrl','http://analytics.zoo/',1),('PrivacyManager.ipAnonymizerEnabled','1',0),('SitesManager_DefaultTimezone','America/Los_Angeles',0),('SitesManagerHadTrafficInPast_2','1',0),('SocialDefinitions','YToyMTA6e3M6OToiYmFkb28uY29tIjtzOjU6IkJhZG9vIjtzOjg6ImJlYm8uY29tIjtzOjQ6IkJlYm8iO3M6MTI6ImJpbGliaWxpLmNvbSI7czo4OiJiaWxpYmlsaSI7czoxNToiYmxhY2twbGFuZXQuY29tIjtzOjExOiJCbGFja1BsYW5ldCI7czo4OiJic2t5LmFwcCI7czo3OiJCbHVlc2t5IjtzOjExOiJza3lmZWVkLmFwcCI7czo3OiJCbHVlc2t5IjtzOjExOiJidXp6bmV0LmNvbSI7czo3OiJCdXp6bmV0IjtzOjE0OiJjbGFzc21hdGVzLmNvbSI7czoxNDoiQ2xhc3NtYXRlcy5jb20iO3M6MTg6Imdsb2JhbC5jeXdvcmxkLmNvbSI7czo3OiJDeXdvcmxkIjtzOjEwOiJkb3V5aW4uY29tIjtzOjY6IkRvdXlpbiI7czo5OiJkb3V5dS5jb20iO3M6NToiRG91eXUiO3M6MTQ6ImdhaWFvbmxpbmUuY29tIjtzOjExOiJHYWlhIE9ubGluZSI7czo4OiJnZW5pLmNvbSI7czo4OiJHZW5pLmNvbSI7czoxMDoiZ2l0aHViLmNvbSI7czo2OiJHaXRIdWIiO3M6MTU6InBsdXMuZ29vZ2xlLmNvbSI7czo5OiJHb29nbGUlMkIiO3M6MTQ6InVybC5nb29nbGUuY29tIjtzOjk6Ikdvb2dsZSUyQiI7czoyODoiY29tLmdvb2dsZS5hbmRyb2lkLmFwcHMucGx1cyI7czo5OiJHb29nbGUlMkIiO3M6MTA6ImRvdWJhbi5jb20iO3M6NjoiRG91YmFuIjtzOjEyOiJkcmliYmJsZS5jb20iO3M6ODoiRHJpYmJibGUiO3M6MTI6ImZhY2Vib29rLmNvbSI7czo4OiJGYWNlYm9vayI7czo1OiJmYi5tZSI7czo4OiJGYWNlYm9vayI7czoxNDoibS5mYWNlYm9vay5jb20iO3M6ODoiRmFjZWJvb2siO3M6MTQ6ImwuZmFjZWJvb2suY29tIjtzOjg6IkZhY2Vib29rIjtzOjExOiJmZXRsaWZlLmNvbSI7czo3OiJGZXRsaWZlIjtzOjEwOiJmbGlja3IuY29tIjtzOjY6IkZsaWNrciI7czoxMjoiZmxpeHN0ZXIuY29tIjtzOjg6IkZsaXhzdGVyIjtzOjExOiJmb3RvbG9nLmNvbSI7czo3OiJGb3RvbG9nIjtzOjE0OiJmb3Vyc3F1YXJlLmNvbSI7czoxMDoiRm91cnNxdWFyZSI7czoxOToiZnJpZW5kc3JldW5pdGVkLmNvbSI7czoxNjoiRnJpZW5kcyBSZXVuaXRlZCI7czoxNDoiZnJpZW5kc3Rlci5jb20iO3M6MTA6IkZyaWVuZHN0ZXIiO3M6NzoiZ3JlZS5qcCI7czo0OiJncmVlIjtzOjk6ImhhYmJvLmNvbSI7czo1OiJIYWJvbyI7czoyMDoibmV3cy55Y29tYmluYXRvci5jb20iO3M6MTE6IkhhY2tlciBOZXdzIjtzOjc6ImhpNS5jb20iO3M6MzoiaGk1IjtzOjg6Imh1eWEuY29tIjtzOjQ6Ikh1eWEiO3M6ODoiaHl2ZXMubmwiO3M6NToiSHl2ZXMiO3M6OToiaWRlbnRpLmNhIjtzOjk6ImlkZW50aS5jYSI7czoxMzoiaW5zdGFncmFtLmNvbSI7czo5OiJJbnN0YWdyYW0iO3M6MTU6ImwuaW5zdGFncmFtLmNvbSI7czo5OiJJbnN0YWdyYW0iO3M6MTA6ImxhbmctOC5jb20iO3M6NjoibGFuZy04IjtzOjc6Imxhc3QuZm0iO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0ucnUiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uZGUiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uZXMiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uZnIiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uaXQiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0uanAiO3M6NzoiTGFzdC5mbSI7czo5OiJsYXN0Zm0ucGwiO3M6NzoiTGFzdC5mbSI7czoxMzoibGFzdGZtLmNvbS5iciI7czo3OiJMYXN0LmZtIjtzOjk6Imxhc3RmbS5zZSI7czo3OiJMYXN0LmZtIjtzOjEzOiJsYXN0Zm0uY29tLnRyIjtzOjc6Ikxhc3QuZm0iO3M6MTI6ImxpbmtlZGluLmNvbSI7czo4OiJMaW5rZWRJbiI7czo3OiJsbmtkLmluIjtzOjg6IkxpbmtlZEluIjtzOjE2OiJsaW5rZWRpbi5hbmRyb2lkIjtzOjg6IkxpbmtlZEluIjtzOjE0OiJsaXZlam91cm5hbC5ydSI7czoxMToiTGl2ZUpvdXJuYWwiO3M6MTU6ImxpdmVqb3VybmFsLmNvbSI7czoxMToiTGl2ZUpvdXJuYWwiO3M6MTU6Im1hc3RvZG9uLnNvY2lhbCI7czo4OiJNYXN0b2RvbiI7czoxNDoibWFzdG9kb24uY2xvdWQiO3M6ODoiTWFzdG9kb24iO3M6MTk6Im1hc3RvZG9uLnRlY2hub2xvZ3kiO3M6ODoiTWFzdG9kb24iO3M6MTI6Im1hc3RvZG9uLnh5eiI7czo4OiJNYXN0b2RvbiI7czoxMToibWFzdG9kb24uYXQiO3M6ODoiTWFzdG9kb24iO3M6MTI6Im1hc3RvZG9uLmFydCI7czo4OiJNYXN0b2RvbiI7czo4OiJtYW1vdC5mciI7czo4OiJNYXN0b2RvbiI7czo5OiJwYXdvby5uZXQiO3M6ODoiTWFzdG9kb24iO3M6ODoibXN0ZG4uaW8iO3M6ODoiTWFzdG9kb24iO3M6ODoibXN0ZG4uanAiO3M6ODoiTWFzdG9kb24iO3M6MTI6ImZyaWVuZHMubmljbyI7czo4OiJNYXN0b2RvbiI7czoxOToicm8tbWFzdG9kb24ucHV5by5qcCI7czo4OiJNYXN0b2RvbiI7czo4OiJxdWV5Lm9yZyI7czo4OiJNYXN0b2RvbiI7czoxMjoiYm90c2luLnNwYWNlIjtzOjg6Ik1hc3RvZG9uIjtzOjE2OiJzb2NpYWwudGNobmNzLmRlIjtzOjg6Ik1hc3RvZG9uIjtzOjc6ImtuemsubWUiO3M6ODoiTWFzdG9kb24iO3M6MTM6Im1hc3RvZG9udC5jYXQiO3M6ODoiTWFzdG9kb24iO3M6MTg6ImJpdGNvaW5oYWNrZXJzLm9yZyI7czo4OiJNYXN0b2RvbiI7czoxMzoiZm9zc3RvZG9uLm9yZyI7czo4OiJNYXN0b2RvbiI7czoxMjoiY2hhb3Muc29jaWFsIjtzOjg6Ik1hc3RvZG9uIjtzOjExOiJjeWJyZS5zcGFjZSI7czo4OiJNYXN0b2RvbiI7czoxMDoidmlzLnNvY2lhbCI7czo4OiJNYXN0b2RvbiI7czoxMToidHlwby5zb2NpYWwiO3M6ODoiTWFzdG9kb24iO3M6MTY6ImZyb250LWVuZC5zb2NpYWwiO3M6ODoiTWFzdG9kb24iO3M6MTI6ImhhY2h5ZGVybS5pbyI7czo4OiJNYXN0b2RvbiI7czoxNToibWFzdG9kb24ub25saW5lIjtzOjg6Ik1hc3RvZG9uIjtzOjEzOiJuZXdzaWUuc29jaWFsIjtzOjg6Ik1hc3RvZG9uIjtzOjEyOiJtc3Rkbi5zb2NpYWwiO3M6ODoiTWFzdG9kb24iO3M6MTU6ImluZGlld2ViLnNvY2lhbCI7czo4OiJNYXN0b2RvbiI7czoxMToic2ZiYS5zb2NpYWwiO3M6ODoiTWFzdG9kb24iO3M6NjoibWFzLnRvIjtzOjg6Ik1hc3RvZG9uIjtzOjExOiJtc3Rkbi5wYXJ0eSI7czo4OiJNYXN0b2RvbiI7czo0OiJjLmltIjtzOjg6Ik1hc3RvZG9uIjtzOjE0OiJtYXN0b2RvbmFwcC51ayI7czo4OiJNYXN0b2RvbiI7czoxNjoidW5pdmVyc2VvZG9uLmNvbSI7czo4OiJNYXN0b2RvbiI7czoxODoic29jaWFsLnZpdmFsZGkubmV0IjtzOjg6Ik1hc3RvZG9uIjtzOjExOiJvaGFpLnNvY2lhbCI7czo4OiJNYXN0b2RvbiI7czoxNDoidG9vdC5jb21tdW5pdHkiO3M6ODoiTWFzdG9kb24iO3M6ODoibWFzdG8uYWkiO3M6ODoiTWFzdG9kb24iO3M6MTM6Im1hc3RvZG9uLnNjb3QiO3M6ODoiTWFzdG9kb24iO3M6MTQ6Im1hc3RvZG9uLndvcmxkIjtzOjg6Ik1hc3RvZG9uIjtzOjExOiJtYXN0b2Rvbi5ueiI7czo4OiJNYXN0b2RvbiI7czoxNToiZ3JhcGhpY3Muc29jaWFsIjtzOjg6Ik1hc3RvZG9uIjtzOjI0OiJvcmcuam9pbm1hc3RvZG9uLmFuZHJvaWQiO3M6ODoiTWFzdG9kb24iO3M6MTI6Im1hc3RvZG9uLmV1cyI7czo4OiJNYXN0b2RvbiI7czoxODoibWFzdG9kb24uamFsZ2kuZXVzIjtzOjg6Ik1hc3RvZG9uIjtzOjc6InRrbS5ldXMiO3M6ODoiTWFzdG9kb24iO3M6MTA6Im1laW52ei5uZXQiO3M6NjoiTWVpblZaIjtzOjEyOiJtaXNzZXZhbi5jb20iO3M6ODoiTWlzc0V2YW4iO3M6NzoibWl4aS5qcCI7czo0OiJNaXhpIjtzOjEwOiJtb2lrcnVnLnJ1IjtzOjEwOiJNb2lLcnVnLnJ1IjtzOjEyOiJtdWx0aXBseS5jb20iO3M6ODoiTXVsdGlwbHkiO3M6MTA6Im15Lm1haWwucnUiO3M6MTA6Im15Lm1haWwucnUiO3M6MTQ6Im15aGVyaXRhZ2UuY29tIjtzOjEwOiJNeUhlcml0YWdlIjtzOjk6Im15bGlmZS5ydSI7czo2OiJNeUxpZmUiO3M6MTE6Im15c3BhY2UuY29tIjtzOjc6Ik15c3BhY2UiO3M6MTQ6Im15eWVhcmJvb2suY29tIjtzOjEwOiJteVllYXJib29rIjtzOjU6Im5rLnBsIjtzOjE0OiJOYXN6YS1rbGFzYS5wbCI7czoxMDoibmV0bG9nLmNvbSI7czo2OiJOZXRsb2ciO3M6MTI6Im5pY292aWRlby5qcCI7czo4OiJOaWNvbmljbyI7czoxNjoib2Rub2tsYXNzbmlraS5ydSI7czoxMzoiT2Rub2tsYXNzbmlraSI7czo5OiJvcmt1dC5jb20iO3M6NToiT3JrdXQiO3M6MTI6InF6b25lLnFxLmNvbSI7czo1OiJPem9uZSI7czoxMToicGVlcGV0aC5jb20iO3M6NzoiUGVlcGV0aCI7czoxMzoicGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5jYSI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5jaCI7czo5OiJQaW50ZXJlc3QiO3M6MTU6InBpbnRlcmVzdC5jby51ayI7czo5OiJQaW50ZXJlc3QiO3M6MTY6InBpbnRlcmVzdC5jb20uYXUiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuZGUiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuZGsiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuZXMiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuZnIiO3M6OToiUGludGVyZXN0IjtzOjEyOiJwaW50ZXJlc3QuaWUiO3M6OToiUGludGVyZXN0IjtzOjE0OiJwaW50ZXJlc3QuaW5mbyI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5qcCI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5ueiI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5wdCI7czo5OiJQaW50ZXJlc3QiO3M6MTI6InBpbnRlcmVzdC5zZSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6ImF0LnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJjaC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoiY2wucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6ImNvLnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJkay5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoiZXMucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6Imh1LnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJpZC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoiaWUucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6ImluLnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJpdC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoia3IucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6Im14LnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJubC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoibnoucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6InBoLnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE2OiJwdC5waW50ZXJlc3QuY29tIjtzOjk6IlBpbnRlcmVzdCI7czoxNjoicnUucGludGVyZXN0LmNvbSI7czo5OiJQaW50ZXJlc3QiO3M6MTY6InNlLnBpbnRlcmVzdC5jb20iO3M6OToiUGludGVyZXN0IjtzOjE1OiJwaXhlbGZlZC5zb2NpYWwiO3M6ODoiUGl4ZWxmZWQiO3M6MTE6InBpeGVsZmVkLmRlIjtzOjg6IlBpeGVsZmVkIjtzOjk6InB4bG1vLmNvbSI7czo4OiJQaXhlbGZlZCI7czoxMjoibWV0YXBpeGwuY29tIjtzOjg6IlBpeGVsZmVkIjtzOjE0OiJwaXgudG9vdC53YWxlcyI7czo4OiJQaXhlbGZlZCI7czoxMjoicGl4ZWxmZWQudW5vIjtzOjg6IlBpeGVsZmVkIjtzOjk6InBpeGV5Lm9yZyI7czo4OiJQaXhlbGZlZCI7czo5OiJwbGF4by5jb20iO3M6NToiUGxheG8iO3M6MTA6InJlZGRpdC5jb20iO3M6NjoicmVkZGl0IjtzOjEzOiJucC5yZWRkaXQuY29tIjtzOjY6InJlZGRpdCI7czoxNDoicGF5LnJlZGRpdC5jb20iO3M6NjoicmVkZGl0IjtzOjIwOiJjb20ucmVkZGl0LmZyb250cGFnZSI7czo2OiJyZWRkaXQiO3M6MTA6InJlbnJlbi5jb20iO3M6NjoiUmVucmVuIjtzOjExOiJza3lyb2NrLmNvbSI7czo3OiJTa3lyb2NrIjtzOjEyOiJzbmFwY2hhdC5jb20iO3M6ODoiU25hcGNoYXQiO3M6MTA6InNvbmljby5jb20iO3M6MTA6IlNvbmljby5jb20iO3M6MTQ6InNvdW5kY2xvdWQuY29tIjtzOjEwOiJTb3VuZENsb3VkIjtzOjc6ImdhdGUuc2MiO3M6MTA6IlNvdW5kQ2xvdWQiO3M6MTc6InN0YWNrb3ZlcmZsb3cuY29tIjtzOjEzOiJTdGFja092ZXJmbG93IjtzOjExOiJzdHVkaXZ6Lm5ldCI7czo3OiJTdHVkaVZaIjtzOjE2OiJsb2dpbi50YWdnZWQuY29tIjtzOjY6IlRhZ2dlZCI7czoxMToidGFyaW5nYS5uZXQiO3M6ODoiVGFyaW5nYSEiO3M6MTY6IndlYi50ZWxlZ3JhbS5vcmciO3M6ODoiVGVsZWdyYW0iO3M6MjI6Im9yZy50ZWxlZ3JhbS5tZXNzZW5nZXIiO3M6ODoiVGVsZWdyYW0iO3M6MTE6InRocmVhZHMubmV0IjtzOjc6IlRocmVhZHMiO3M6MTM6ImwudGhyZWFkcy5uZXQiO3M6NzoiVGhyZWFkcyI7czoxMToidGhyZWFkcy5jb20iO3M6NzoiVGhyZWFkcyI7czoxMzoibC50aHJlYWRzLmNvbSI7czo3OiJUaHJlYWRzIjtzOjEwOiJ0aWt0b2suY29tIjtzOjY6IlRpa1RvayI7czoxMDoidHVlbnRpLmNvbSI7czo2OiJUdWVudGkiO3M6MTA6InR1bWJsci5jb20iO3M6NjoidHVtYmxyIjtzOjExOiJ0LnVtYmxyLmNvbSI7czo2OiJ0dW1ibHIiO3M6MTQ6InR3aXRjYXN0aW5nLnR2IjtzOjg6IlR3aXRjYXN0IjtzOjExOiJ0d2l0dGVyLmNvbSI7czo3OiJUd2l0dGVyIjtzOjQ6InQuY28iO3M6NzoiVHdpdHRlciI7czo1OiJ4LmNvbSI7czo3OiJUd2l0dGVyIjtzOjE1OiJzb3VyY2Vmb3JnZS5uZXQiO3M6MTE6IlNvdXJjZWZvcmdlIjtzOjE1OiJzdHVtYmxldXBvbi5jb20iO3M6MTE6IlN0dW1ibGVVcG9uIjtzOjY6InZrLmNvbSI7czo5OiJWa29udGFrdGUiO3M6MTI6InZrb250YWt0ZS5ydSI7czo5OiJWa29udGFrdGUiO3M6MTE6InlvdXR1YmUuY29tIjtzOjc6IllvdVR1YmUiO3M6ODoieW91dHUuYmUiO3M6NzoiWW91VHViZSI7czo4OiJ2MmV4LmNvbSI7czo0OiJWMkVYIjtzOjEwOiJ2aWFkZW8uY29tIjtzOjY6IlZpYWRlbyI7czo5OiJ2aW1lby5jb20iO3M6NToiVmltZW8iO3M6MTU6InZrcnVndWRydXplaS5ydSI7czoxNToidmtydWd1ZHJ1emVpLnJ1IjtzOjg6IndheW4uY29tIjtzOjQ6IldBWU4iO3M6OToid2VpYm8uY29tIjtzOjU6IldlaWJvIjtzOjQ6InQuY24iO3M6NToiV2VpYm8iO3M6MTI6IndlZXdvcmxkLmNvbSI7czo4OiJXZWVXb3JsZCI7czoxNDoibG9naW4ubGl2ZS5jb20iO3M6MTk6IldpbmRvd3MgTGl2ZSBTcGFjZXMiO3M6MTM6IndvcmtwbGFjZS5jb20iO3M6OToiV29ya3BsYWNlIjtzOjE1OiJsLndvcmtwbGFjZS5jb20iO3M6OToiV29ya3BsYWNlIjtzOjE2OiJsbS53b3JrcGxhY2UuY29tIjtzOjk6IldvcmtwbGFjZSI7czo5OiJ4YW5nYS5jb20iO3M6NToiWGFuZ2EiO3M6ODoieGluZy5jb20iO3M6NDoiWElORyI7fQ==',0),('TaskScheduler.timetable','a:32:{s:45:\"Piwik\\Plugins\\GeoIp2\\GeoIP2AutoUpdater.update\";i:1762819200;s:60:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.invalidateOutdatedArchives\";i:1762819231;s:59:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.deleteOldFingerprintSalts\";i:1762819231;s:55:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeOutdatedArchives\";i:1762819231;s:55:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeOrphanedArchives\";i:1763337631;s:51:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.updateSpammerList\";i:1763337631;s:61:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.checkSiteHasTrackedVisits_1\";i:1763172000;s:61:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.checkSiteHasTrackedVisits_2\";i:1763085600;s:49:\"Piwik\\Plugins\\Referrers\\Tasks.updateSearchEngines\";i:1763337631;s:43:\"Piwik\\Plugins\\Referrers\\Tasks.updateSocials\";i:1763337631;s:48:\"Piwik\\Plugins\\Referrers\\Tasks.updateAIAssistants\";i:1763337631;s:47:\"Piwik\\Plugins\\Login\\Tasks.cleanupBruteForceLogs\";i:1762819231;s:63:\"Piwik\\Plugins\\TwoFactorAuth\\Tasks.cleanupTwoFaCodesUsedRecently\";i:1762819231;s:53:\"Piwik\\Plugins\\UsersManager\\Tasks.cleanupExpiredTokens\";i:1762819231;s:63:\"Piwik\\Plugins\\UsersManager\\Tasks.setUserDefaultReportPreference\";i:1762819231;s:54:\"Piwik\\Plugins\\UsersManager\\Tasks.cleanUpExpiredInvites\";i:1762819231;s:85:\"Piwik\\Plugins\\UsersManager\\TokenNotifications\\TokenNotifierTask.dispatchNotifications\";i:1762819231;s:83:\"Piwik\\Plugins\\UsersManager\\UserNotifications\\UserNotifierTask.dispatchNotifications\";i:1764547231;s:49:\"Piwik\\Plugins\\CustomJsTracker\\Tasks.updateTracker\";i:1762801231;s:58:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeInvalidatedArchives\";i:1762819231;s:65:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeBrokenArchivesCurrentMonth\";i:1762819231;s:67:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.purgeInvalidationsForDeletedSites\";i:1762819231;s:51:\"Piwik\\Plugins\\PrivacyManager\\Tasks.deleteReportData\";i:1762819231;s:48:\"Piwik\\Plugins\\PrivacyManager\\Tasks.deleteLogData\";i:1762801231;s:52:\"Piwik\\Plugins\\PrivacyManager\\Tasks.anonymizePastData\";i:1762801231;s:63:\"Piwik\\Plugins\\PrivacyManager\\Tasks.deleteLogDataForDeletedSites\";i:1763337631;s:54:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.optimizeArchiveTable\";i:1764547231;s:57:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.cleanupTrackingFailures\";i:1762819231;s:56:\"Piwik\\Plugins\\CoreAdminHome\\Tasks.notifyTrackingFailures\";i:1763337631;s:65:\"Piwik\\Plugins\\CoreUpdater\\Tasks.sendNotificationIfUpdateAvailable\";i:1762819231;s:52:\"Piwik\\Plugins\\Marketplace\\Tasks.clearAllCacheEntries\";i:1762819231;s:66:\"Piwik\\Plugins\\Marketplace\\Tasks.sendNotificationIfUpdatesAvailable\";i:1762819231;}',0),('TransactionLevel.testOption','1',0),('UpdateCheck_LastCheckFailed','1',0),('UpdateCheck_LastTimeChecked','',1),('useridsalt','XfpJA2xDZNvCU5dCdMB5GzPXRZz_leRuan520CUl',1),('version_Actions','5.5.1',1),('version_Annotations','5.5.1',1),('version_API','5.5.1',1),('version_BulkTracking','5.5.1',1),('version_Contents','5.5.1',1),('version_core','5.5.1',1),('version_CoreAdminHome','5.5.1',1),('version_CoreConsole','5.5.1',1),('version_CoreHome','5.5.1',1),('version_CorePluginsAdmin','5.5.1',1),('version_CoreUpdater','5.5.1',1),('version_CoreVisualizations','5.5.1',1),('version_CoreVue','5.5.1',1),('version_CustomDimensions','5.5.1',1),('version_CustomJsTracker','5.5.1',1),('version_Dashboard','5.5.1',1),('version_DevicePlugins','5.5.1',1),('version_DevicesDetection','5.5.1',1),('version_Diagnostics','5.5.1',1),('version_Ecommerce','5.5.1',1),('version_Events','5.5.1',1),('version_FeatureFlags','5.5.1',1),('version_Feedback','5.5.1',1),('version_GeoIp2','5.5.1',1),('version_Goals','5.5.1',1),('version_Heartbeat','5.5.1',1),('version_ImageGraph','5.5.1',1),('version_Insights','5.5.1',1),('version_Installation','5.5.1',1),('version_Intl','5.5.1',1),('version_IntranetMeasurable','5.5.1',1),('version_JsTrackerInstallCheck','5.5.1',1),('version_LanguagesManager','5.5.1',1),('version_Live','5.5.1',1),('version_log_conversion.pageviews_before','SMALLINT UNSIGNED DEFAULT NULL',1),('version_log_conversion.revenue','float default NULL',1),('version_log_link_visit_action.idaction_content_interaction','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_content_name','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_content_piece','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_content_target','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_event_action','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_event_category','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idaction_name','INTEGER(10) UNSIGNED',1),('version_log_link_visit_action.idaction_product_cat','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_cat2','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_cat3','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_cat4','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_cat5','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_name','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_product_sku','INT(10) UNSIGNED NULL',1),('version_log_link_visit_action.idaction_url','INTEGER(10) UNSIGNED DEFAULT NULL',1),('version_log_link_visit_action.idpageview','CHAR(6) NULL DEFAULT NULL',1),('version_log_link_visit_action.product_price','DOUBLE NULL',1),('version_log_link_visit_action.search_cat','VARCHAR(200) NULL',1),('version_log_link_visit_action.search_count','INTEGER(10) UNSIGNED NULL',1),('version_log_link_visit_action.server_time','DATETIME NOT NULL',1),('version_log_link_visit_action.time_dom_completion','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_dom_processing','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_network','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_on_load','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_server','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_spent_ref_action','INTEGER(10) UNSIGNED NULL',1),('version_log_link_visit_action.time_transfer','MEDIUMINT(10) UNSIGNED NULL',1),('version_log_visit.config_browser_engine','VARCHAR(10) NULL',1),('version_log_visit.config_browser_name','VARCHAR(40) NULL1',1),('version_log_visit.config_browser_version','VARCHAR(20) NULL',1),('version_log_visit.config_client_type','TINYINT( 1 ) NULL DEFAULT NULL1',1),('version_log_visit.config_cookie','TINYINT(1) NULL',1),('version_log_visit.config_device_brand','VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL1',1),('version_log_visit.config_device_model','VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL1',1),('version_log_visit.config_device_type','TINYINT( 100 ) NULL DEFAULT NULL1',1),('version_log_visit.config_flash','TINYINT(1) NULL',1),('version_log_visit.config_java','TINYINT(1) NULL',1),('version_log_visit.config_os','CHAR(3) NULL',1),('version_log_visit.config_os_version','VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL',1),('version_log_visit.config_pdf','TINYINT(1) NULL',1),('version_log_visit.config_quicktime','TINYINT(1) NULL',1),('version_log_visit.config_realplayer','TINYINT(1) NULL',1),('version_log_visit.config_resolution','VARCHAR(18) NULL',1),('version_log_visit.config_silverlight','TINYINT(1) NULL',1),('version_log_visit.config_windowsmedia','TINYINT(1) NULL',1),('version_log_visit.location_browser_lang','VARCHAR(20) NULL',1),('version_log_visit.location_city','varchar(255) DEFAULT NULL1',1),('version_log_visit.location_country','CHAR(3) NULL1',1),('version_log_visit.location_latitude','decimal(9, 6) DEFAULT NULL1',1),('version_log_visit.location_longitude','decimal(9, 6) DEFAULT NULL1',1),('version_log_visit.location_region','char(3) DEFAULT NULL1',1),('version_log_visit.profilable','TINYINT(1) NULL',1),('version_log_visit.referer_keyword','VARCHAR(255) NULL1',1),('version_log_visit.referer_name','VARCHAR(255) NULL1',1),('version_log_visit.referer_type','TINYINT(1) UNSIGNED NULL1',1),('version_log_visit.referer_url','VARCHAR(1500) NULL',1),('version_log_visit.user_id','VARCHAR(200) NULL',1),('version_log_visit.visit_entry_idaction_name','INTEGER(10) UNSIGNED NULL',1),('version_log_visit.visit_entry_idaction_url','INTEGER(11) UNSIGNED NULL  DEFAULT NULL',1),('version_log_visit.visit_exit_idaction_name','INTEGER(10) UNSIGNED NULL',1),('version_log_visit.visit_exit_idaction_url','INTEGER(10) UNSIGNED NULL DEFAULT 0',1),('version_log_visit.visit_first_action_time','DATETIME NOT NULL',1),('version_log_visit.visit_goal_buyer','TINYINT(1) NULL',1),('version_log_visit.visit_goal_converted','TINYINT(1) NULL',1),('version_log_visit.visit_total_actions','INT(11) UNSIGNED NULL',1),('version_log_visit.visit_total_events','INT(11) UNSIGNED NULL',1),('version_log_visit.visit_total_interactions','MEDIUMINT UNSIGNED DEFAULT 0',1),('version_log_visit.visit_total_searches','SMALLINT(5) UNSIGNED NULL',1),('version_log_visit.visit_total_time','INT(11) UNSIGNED NOT NULL',1),('version_log_visit.visitor_count_visits','INT(11) UNSIGNED NOT NULL DEFAULT 01',1),('version_log_visit.visitor_localtime','TIME NULL',1),('version_log_visit.visitor_returning','TINYINT(1) NULL1',1),('version_log_visit.visitor_seconds_since_first','INT(11) UNSIGNED NULL1',1),('version_log_visit.visitor_seconds_since_last','INT(11) UNSIGNED NULL',1),('version_log_visit.visitor_seconds_since_order','INT(11) UNSIGNED NULL1',1),('version_Login','5.5.1',1),('version_Marketplace','5.5.1',1),('version_MobileMessaging','5.5.1',1),('version_Monolog','5.5.1',1),('version_Morpheus','5.5.1',1),('version_MultiSites','5.5.1',1),('version_Overlay','5.5.1',1),('version_PagePerformance','5.5.1',1),('version_PrivacyManager','5.5.1',1),('version_ProfessionalServices','5.5.1',1),('version_Proxy','5.5.1',1),('version_Referrers','5.5.1',1),('version_Resolution','5.5.1',1),('version_RssWidget','1.0',1),('version_ScheduledReports','5.5.1',1),('version_SegmentEditor','5.5.1',1),('version_SEO','5.5.1',1),('version_SitesManager','5.5.1',1),('version_Tour','5.5.1',1),('version_Transitions','5.5.1',1),('version_TwoFactorAuth','5.5.1',1),('version_UserCountry','5.5.1',1),('version_UserCountryMap','5.5.1',1),('version_UserId','5.5.1',1),('version_UserLanguage','5.5.1',1),('version_UsersManager','5.5.1',1),('version_VisitFrequency','5.5.1',1),('version_VisitorInterest','5.5.1',1),('version_VisitsSummary','5.5.1',1),('version_VisitTime','5.5.1',1),('version_WebsiteMeasurable','5.5.1',1),('version_Widgetize','5.5.1',1);
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
INSERT INTO `matomo_sequence` VALUES ('matomo_archive_numeric_2025_01',0),('matomo_archive_numeric_2025_11',22),('matomo_archive_numeric_2025_12',0);
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
INSERT INTO `matomo_session` VALUES ('006250188a551076a1c403e28fb4d79ce312321b645149801ada40fe740ed082330ab5d5628accff297d318f116874e01844b494e89465a897c82ea423a9938d',1762800867,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI3ZjY1Yjk3ZTg0YWUyNjY5ZTY0NjRkMGJmYWE3OTE2ZSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxNDY3O319fX0=\";}'),('025c25c31c57b3de9e136d285a7c6d658b7fb554c11b699c6faca7a71c58192dd9217f0d581715bbc99a256467a9b466d1d4a8cba497c71f975591816d435df4',1762788105,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJhOTI0NDI1ODgyOWFmYzNkMWI2YTc4OTI2MmI1NWIwNSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg4NzA1O319fX0=\";}'),('0432c8b14279eaa26c1cdb9490db36399d7f86985f25a64827d83659a51599bc82986b7b7b55cddff0eaf3d8402c5b6d816a27c2690d7c2a4ce60f1c5d7b0986',1762800022,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJlOWYxYzYyYmU0NjdhOTY1NjJmYjI5Mzc2YTgzYjczZCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAwNjIyO319fX0=\";}'),('090c9b31776f673b6d7b41dc00a78dca2e98e2f174a67034e39382c6139d1cfc2e5524799f9596fc559b13c786e3a54eac604fde4fc16c20890aa2bf0d6a6986',1762786143,1209600,'a:1:{s:4:\"data\";s:512:\"YTo2OntzOjQ6Il9fWkYiO2E6MTp7czoxMToiTG9naW4ubG9naW4iO2E6MTp7czo0OiJFTlZUIjthOjE6e3M6NToibm9uY2UiO2k6MTc2Mjc4NjM2Mzt9fX1zOjk6InVzZXIubmFtZSI7czoxNDoiYW5hbHl0aWNzX3VzZXIiO3M6MjI6InR3b2ZhY3RvcmF1dGgudmVyaWZpZWQiO2k6MDtzOjIwOiJ1c2VyLnRva2VuX2F1dGhfdGVtcCI7czozMjoiYzYzZjdmYTM4ZWVlOTEzMTRlMmJjNGQ0OTVhNzMxN2IiO3M6MTI6InNlc3Npb24uaW5mbyI7YTozOntzOjI6InRzIjtpOjE3NjI3ODU3Nzk7czoxMDoicmVtZW1iZXJlZCI7YjowO3M6MTA6ImV4cGlyYXRpb24iO2k6MTc2Mjc4OTc0Mzt9czoxMjoibm90aWZpY2F0aW9uIjthOjE6e3M6MTM6Im5vdGlmaWNhdGlvbnMiO2E6MDp7fX19\";}'),('14fa95d8b775baf9ca0b7e62a1ccfcf44bdb426f2c0ce7b1f4608e43fff7ae7a157ff7c3bbbc6ce0ff0f8bf5e2722d271e1cc1192080450116d669ae512ac6f7',1762785835,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJlN2U2ZTU5NmY4MzA1ODg0NTE3OWVlZjczZDJkYmM4YyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg2NDM1O319fX0=\";}'),('15465e20f43ff1dfe748f68c7501f99834e986caf7182f1a30591ec9827bee26fc38e715e53d127384a50002f4796c0a0475525f2c9cc2fe0a1ea99b545822b3',1762785895,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI3OTg3ZGI1ZGNiOWJmODlkZTIzNjA1MWU2Y2FkNzk4YSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg2NDk1O319fX0=\";}'),('1802d3ddc5b9d97784b70693e6fd92ca27ca1ae57aacba0479b47c4ba34c4b0c6d9748f20ae61cd66b00e3b2bd0630c0e2c6298d82456845aae4e4e6dc8de7d7',1762802138,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJlNzJkNjkzNmJjMDk1ODJmZWRhOGEwNmUzNzRjZGViZiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyNzM4O319fX0=\";}'),('1ba9d52a57d90f837889703d69091c58c3c2054b69baa2a86a5dc1fc25277e9745d93757ab797e75284d68fd569f321fd27ec4d95e2b09893dc09740e12a4488',1762796350,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIxZjlmM2M1ODI3ZTFlYWVmZWJhYmJjMDNkMjhiOTA2NSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk2OTUwO319fX0=\";}'),('1bc6dd1f872dd69142778a24bc3e0dc0cd81f2fec82684c0038e018046d7ce110114f7a946a6c12e142cde811205f12165e784e7ecb62827e615f79d310f9762',1762787563,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJhNjZhYTQ5NTg2YzZlNjllOTczZjE3MDE1NjFlNWE4NiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg4MTYzO319fX0=\";}'),('20e58b98f0a39377ed89d9962c4758b4428d5873791ee77493e15de0225a8a257a29b414a625e13c4e6b852142fc5d4a3a457bace3bd1b46c5f16b385867c79a',1762788226,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkNTY5YjZmOTNjNGNlZDA0MzgyZjQ4ZmNiZTNlNzFhZCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg4ODI2O319fX0=\";}'),('246c7a87e445ee4294cae0dd809e66517b4ba8dcdf06b9274ade1004460f974bd7bc68265c23d667783de54a7fc58701d91bef4b4ffd170c302301ad1ea92ff1',1762786498,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJjNThlNDRkOTBkMjg3MzZlOTE4ZGY1ODk3MWRlYWM5ZSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3MDk4O319fX0=\";}'),('25c2c425c9149cbfa760d3c9e836f91972b16c290375ace68164986cd3e7045427bf04bf28fb45d32fe51192690e4427673ab827db2280510ec23a9d47820c86',1762787623,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI2OTRjOWE5NmVkNWRhMmNjOGI5ZjRiOTViNDIyYmExYyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg4MjIzO319fX0=\";}'),('298b82c6a28b741c3d4589ea13afce943257cac72faf254df67e73b4757ff28cc43faebe08917a00a23e528e574bf2e641eead406b75f472671e4bcb3652436b',1762785956,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJlNzg0NjRlMDg0MGIyM2FkYzA0YjQxMmFmYmI3YmFmMSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg2NTU2O319fX0=\";}'),('29a1557db0c7ee6bac2d419df565807e43d42b4cc5bab4065686f7a3c57727b5671c6630b50ff645ace99dfb97152a04f0604b308d3efac902ab48d593f1fae0',1762787864,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJmMDdlM2IxMzJhYmY0N2YwNDFlMTc0MWNjY2RkYzFlOSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg4NDY0O319fX0=\";}'),('29efa93eab00e79e91d8c8ec962a3326005d1857898b7eda80e38ef32f3120994b799c62ef28ec726472cb6342042873ebb1acc3f3e1e6f496c8252a51d465e6',1762786016,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI5MGUyMzUwMDc3NmQ3YmIyMzg1NTJiNDNhZDBkNDA4MSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg2NjE2O319fX0=\";}'),('2d7fc090e2bc09b5bf563d3251e7754e6efaf6af56df6b244798408f1eecd38c154467b7bd2c93665ad481c60dd202ee708c1fbee83c60cc5d3ff23e089a2565',1762800988,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIxOGQ0OTIxOWY4Y2RlMTE0ZDgyMjEzNTJjMDA0OTk5ZSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxNTg4O319fX0=\";}'),('2e98cb27a4e70cf259775280d7835ef146a326a769a2aecaf40fecb914111df2b58aa5eb405717b2920b2d139751f1ac72355571b4fa4c92a3b5534c981c42ce',1762801957,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJmYjAxYTRkZGY2M2Y1YTIxMjBhYzBjZThiYzM3ODZjNCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyNTU3O319fX0=\";}'),('2f7675814deb4b360d0ef938b576ec9dbdd9a186772000b3775ee29ab818c35192d32dc9a0f8971fdb1aec2885b819d26cfb148821b6d9e41b01c9f2ad31fd2f',1762801776,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJlMmMzYTZhOTQwYWRiMmFlNjE3MmJkMzA5N2VkMzFmNyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyMzc2O319fX0=\";}'),('32f35bbf23722b0872bb074101f8eb789b4dad871a89cf6518b739ece8aa65ce881eebaeac096b081a286a1fdb68981a44c5e3068a7e477cb80a52b602100876',1762786369,1209600,'a:1:{s:4:\"data\";s:512:\"YTo2OntzOjQ6Il9fWkYiO2E6MTp7czoxMToiTG9naW4ubG9naW4iO2E6MTp7czo0OiJFTlZUIjthOjE6e3M6NToibm9uY2UiO2k6MTc2Mjc4Njc2NTt9fX1zOjk6InVzZXIubmFtZSI7czoxNDoiYW5hbHl0aWNzX3VzZXIiO3M6MjI6InR3b2ZhY3RvcmF1dGgudmVyaWZpZWQiO2k6MDtzOjIwOiJ1c2VyLnRva2VuX2F1dGhfdGVtcCI7czozMjoiNTIwOTA4NzJmY2U5MDI2ZmZhZGQ1NTJiNDJjYTkyZGEiO3M6MTI6InNlc3Npb24uaW5mbyI7YTozOntzOjI6InRzIjtpOjE3NjI3ODYxNzg7czoxMDoicmVtZW1iZXJlZCI7YjowO3M6MTA6ImV4cGlyYXRpb24iO2k6MTc2Mjc4OTk2OTt9czoxMjoibm90aWZpY2F0aW9uIjthOjE6e3M6MTM6Im5vdGlmaWNhdGlvbnMiO2E6MDp7fX19\";}'),('3458e466490ccdba9c4e39655abb927df94b1fae7e8e03afd7e0a06e0fa7a0b77323667a2e9eadf511c546fac58185119ff41d743b890aded7cc6c144ee689be',1762787284,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI2MDQ5MzMzNjc0OWYyYTE5MTc5MmU2ZjI5ZWVmMmZmNCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3ODg0O319fX0=\";}'),('36d13e422b7385ec376ce7180b85f84062c02c9c0c7303498e679bab974f0edf51c3588b1d0a10ea8f15d5dbea79784261a0e04c5dc42e0fbf11594e652f9402',1762800746,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI0Mjk4ZWE4ZjI1MDBiMjE2MmE4OTEyNzJhNDExMzFjMSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxMzQ2O319fX0=\";}'),('37840007650c31e0d9ba16f4ff5d5f6f3d9d49d09882fb17cc1c2b9a14011c095afa711d98f52f02fce52b47ccc7781753a7aca3cb421ec6a367e33490869ddd',1762786920,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkMTQ1ZGE0MDk4ZTFhNmE4NzMyMjdhOGI4YmI2NWY5NyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3NTIwO319fX0=\";}'),('3a9a1844f36704e2528942cf3330975fe7241d760c69c33cc1098b6cd2e5a7515ee3dfc82a08ceb1bda5863244021e7d06a1356cf1c7ebb8927ec730baab69e4',1762797347,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIyYjk3ZDEzOTQ2ZWZjYmIyMWZlY2RhNWQ0OTI5ZDVjZCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3OTQ3O319fX0=\";}'),('3c07a8185f39febf3ae99c129b313efd54d6dce6c7e4648f2357b050ee1d0810fcad4e63940f13e100d955057fe22485d2133e372d1442b66417c10e4080aee1',1762802264,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJmYjA5MGQ2YTlhN2U0YjNhZTQ5ZDM0NTMwZWY5ZTczOCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyODYzO319fX0=\";}'),('3d509b1146f0f65a6578d65db653b97ce4498bbb74f85bbf1d341997bc88c1741c5d09d00d59218f0e4d57450faf9a0e92eb164876300e21e553ee407efad9b1',1762786076,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI5ZjBmMWFhZWFmYjZmM2NlNWYxYTk3NTlhNDRhMTM2NSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg2Njc2O319fX0=\";}'),('3f1e28e2d7dd3ca8ea0dbb4edb0a909f2d2d32f97dc81b38fbd544357400330512ee10fea7b86579d3305a458fa9e2bc76ad9579269a94319fdb02fb8c8ddb72',1762797468,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIxMzA0NTgxNTgxMmMwY2VmZjU0YjJiMzllZGJmNDc0NCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk4MDY4O319fX0=\";}'),('3fede14ea82e84c4ba630233b49628ac3e937fba602700e47e449fb99e4364acd5e147d2d1aac1cb1d89a573a0867f744cdae17f75b72afe613fc923b52f855b',1762801897,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIwOWZlNjFjZWE4NzE0YTNmOGY2NTVjOTk1MGI0YzZiOSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyNDk3O319fX0=\";}'),('43d9726448d5d24cc2fc31c4185a6c32bb8670cafd6e3e2e6e20976c49dc0d5cbdf54567f304b596fa498fffd8cd92c03269059795bb4e0d5ec553b41455113d',1762787744,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI5MTIwMzE0OWI3MmEzYTEzNjM3YzkzMjQzYzIyYTQ5MSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg4MzQ0O319fX0=\";}'),('43fba447eba377912427eb0b592c68679dedecfdf62d11615bb18de3aac3d2cc1f39fb36e81b5ba10f7f204c89ee8a31ef82f75f894eef9a8c3c5b14e3c3d7a3',1762796707,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkN2RhMTI1MTg1YjU0ODJiMjJjMjQ0NzExZGE0MjNkZiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3MzA3O319fX0=\";}'),('4551472769a16b9a07380d33011c0dd7ade08cc1c85f1f0edb3200060a88627d8f9b25d633dcdb5de0efeaab41592f229213173019275ead912703dfbe7b17e3',1762800445,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJiNWQ3MDE2NzBhMzM2MjJkYjYwYmEzNjJmZTcxMTY2NCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxMDQ1O319fX0=\";}'),('468142a4c7db30295cc7553b2c9e969a0377c734a1aa51e544c62688404fb72a0eb49fa5eed7bd485bab0305afc70a05cbd9ffe6a4d85b5d5c4b580f1c434ad7',1762800083,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI2ODU4NWY3NDZjMjY2MGM2N2RmOTRhOTE1NDhiOTRmMyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAwNjgzO319fX0=\";}'),('48d12c53a8110cb73522fe51c6d851eedb1380c28077e412a70b101dee1d763cb7a697d406ae58275353ef0bb1545f610c907799a10494892d5a2d2208ca1a2a',1762801289,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIyNTZlNDcxNmVmMDI3ZmU2OThlOTlkYmRmYzZmNjQ1YyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxODg5O319fX0=\";}'),('4d64f83c2eb03db88ad65fe877f3e9deff2aedaf51487079c24f6bb2e5bdaf16a619c1b6c560aa8899d2b11f6074e7bdceefae0513e150b656293a7ee42b3f34',1762787683,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJjNGEyYjdkMTg0Mjg0OTVhNzExMGFmMjMzMGE1NTM1YyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg4MjgzO319fX0=\";}'),('4ebd06d57a3531a5e575657f358c54f4f885f58bd44104b06eeddfdc80f21f7d537855b01f2b81d7f54a72612c72eba17666bac49e2d3d084bdc44cea6a9fdd5',1762797009,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJhM2ZkZGMxODRhZjk4ZmEyYjU0MzllNGJjYWEzMDVhNCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3NjA5O319fX0=\";}'),('4ec04ea3e6b2546960c4fc30dba7242a72142ff11ced10aee376503f3b4619d6723ce413e6084084640784494b445b417cba187e751790afcb2331891f7ad8dc',1762796828,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIwZTVmZmVjZDYyZWY0MTc5YmY0ZGRmZDMxMzkwNjliNyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3NDI4O319fX0=\";}'),('4f60120533a65a1b680bad00b9a09ac3e9d4a288c92989afcdde86163e150bb7e34d037653c11c38c3f87cdffa1ffa90b1b1660a7f91351a570406de639b6b4d',1762786197,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI0MzZkMzhlZDc1ZGZmODVlYmYyNzcwZDY1ZjA0NWYwZiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg2Nzk3O319fX0=\";}'),('5027e35b5b60c483f988acbbaa169cc018d461e412fa9e4102f54993a732b6b54a6a7e1e6ae3b630427eaaff29f2118ba22afb523878535283a8e80200db3a34',1762802199,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJlZTc0MjUyMDVmZTljYjFkMDQ4YzhmM2ExNzUyZjFkZSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyNzk5O319fX0=\";}'),('50bec50932fb7c854761ab4b195aafa7b0a6776dfc5fcefc54530910bd799972426250f77beabc5075b1e209356018b466201b7969ed41f5186c8e18e5da3540',1762802329,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkZDk5NjZlYWM0MzAxYzJlNWI1NjBjNjE0Zjk1YzUwOCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyOTI5O319fX0=\";}'),('50c0a5b558e6d7b4a52f44c10648f06b28e315eb5751feceeb790cafbf227f7a9df55544a96d1d89c5297db20fefad1200960c4cab86663e51bce8cd9ced3e58',1762801109,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkZDUyMjYxYjljODJiNzRjNzJhMzdkNWJhNjBkOWZkNyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxNzA5O319fX0=\";}'),('599ffb4f3f115e04f5b3d41a51b46ac59192dce227c520f8b830cae5950078a72fe1753b4014db19feb17d10b4cffba9d534cf9da4bffc78200fecae9530f121',1762801229,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJmNWM5Nzk0ZDZkMDA3ZGFhOTgxM2Y0ZWY1YmYwYjBmZSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxODI5O319fX0=\";}'),('5c2f0d64a5d0d47c81552c46a10ad63f3c51e10cc3e120ab102650d8eb96fc480b0b10e99f547038b7efe62eb7b87df8ec421164696c1fc0ae9fb797d0db50c3',1762785775,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJmMTgzNzZhMGM5NzM4NTMxMWQzZDdjNDhhYzY5ZTA0NCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg2Mzc1O319fX0=\";}'),('5ef4943530aa81086d992e8e216fc19f14354d60c54ca48439d01f66f54995dcd269549bd553f0b34fc06c9eed60bdb8aed51921c2753bca83d50e4df0e87828',1762800686,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI5YjM3YTcxMjk0YzQ1MzUzZThjNDgzYzM4Y2RjMzU2NiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxMjg2O319fX0=\";}'),('684920987ea8805f12d41e3af1a34556bcc62f740e1339d4e9dbd0d3922ee0b39219ad835a6166413219e580e5f335fe7e3509c884054e0e99b867526ab1197a',1762801591,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI5YzFhNzAzMjM2MTg4NDdkN2NlYjZhYjJiMThmNmI5NSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyMTkxO319fX0=\";}'),('6b0c90cabdff75ce3f639f37d7955d176987df2035f5ede8f8c96424494a27dd14f1fe7b9b11e4547da4cfc81aceb33bb2e1e4a21a649720826766c12478a8b9',1762801350,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI0ODkxNDEwN2ZhOGZlNWYzNWVlZjI2ZTJkN2ZjODJmZSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxOTUwO319fX0=\";}'),('6ce31f3597712841962da8e5fc19fee088fb33a47b08b46588337a6c84e806145197a63ab6ad50665e2ddfe6b5f1ea2f6e21cbd055c5c680b0cf37bf030b9b2e',1762796411,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI4NDBjMmM0MmU0YjcxNjkzYmM3ZGQzOGE1NTc3OThhYyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3MDExO319fX0=\";}'),('6f820c172c7da389841b2399c3a6d88ae852efb4daf59278d054f93aaf89107d4987f428817e7092bca41bce411cefa87b3128d142d05db9532c747322fdab9c',1762786860,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI1YTRlOWNjZGYxMmNjMzA0OGY1NTYwZmYzMjRkNjQ5YSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3NDYwO319fX0=\";}'),('70896847d4ff73774f07cd8c85213d989700554201e8237536b27cceadce70af9481e90c941892ebc83954b70cc9336c995a9fd59ad5453bb14b124d1378fc2d',1762786679,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIzZGRiZDA2YTRhNTU2YWJiMGJiYjg0ZjA5Y2QzZDMxMCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3Mjc5O319fX0=\";}'),('71319fe26d73af25f64398cf63404de6116ffdd38a941d2f881e1c37458a1cdb3b0233536b47cc8c59eed8311235d2e4ddda8237a360598edf4c65c5e3548150',1762797287,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI3OWYyMGRkZWE2MGYzODc2NThjZDRlOTU1NWY0M2NkNSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3ODg2O319fX0=\";}'),('749e431d905bad198912183b7578a704ad77bd8ca3f5f4a0c18ad90b535e19bde298038bd1fcb05a07159b3366f2d80c39829434421325033a826b0a479f18f7',1762800324,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI2YTc2ZjIzZDc4ZjQ5ZDI0NjU4ZTMzM2U1NmVhNGI0NyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAwOTI0O319fX0=\";}'),('7900c09ae7359aaee4256fbff8899541f8325b1835da4fe492e53abcb72969badee8c7cc2e239320bfb370be4f12db850960ebfe899dbad1419241ce8b65dbbc',1762786981,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJiOGM4OWNhOThmOTZlNDU3Y2NjMmUyNzYzOGI4Mzc2YiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3NTgxO319fX0=\";}'),('7be539f4cd7b602823ef7c521e9cc17bbe736cab01040f72d0ae38bf034c2e4837c34b697d8475a1c081e8113202b8128a0a33ea649ad1441a033ee095e9d3ec',1762786800,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIwMjQyZWI1YWQ3YjYwMDFlMWJlNDdjNmJkYjI0ODdmMSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3NDAwO319fX0=\";}'),('7e4f8a34babfd949b21fdb2f838935a4694eb86e11b7baeafb1411c88ac9a0197f01a8ebfb49951829e0b278a4a7a00e2fe53149eaba83a237484e6fd995296f',1762797709,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI3NGMwMmRmMmI4YjA2ZGE5NTQxNDcyNjVhZDQwMjkzNyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk4MzA5O319fX0=\";}'),('7e64cecdf8806bffe60a491679cd394cb5bcfa383a251f136d94814397d90c8b29ce5c3eba4778a8fe4fd6d99e0d016dca650b9be15292343aaeb893dc3ad469',1762800110,1209600,'a:1:{s:4:\"data\";s:400:\"YTo1OntzOjk6InVzZXIubmFtZSI7czoxNDoiYW5hbHl0aWNzX3VzZXIiO3M6MjI6InR3b2ZhY3RvcmF1dGgudmVyaWZpZWQiO2k6MDtzOjIwOiJ1c2VyLnRva2VuX2F1dGhfdGVtcCI7czozMjoiMzNhZDdlYzY5ZDBmYzRmZDU5MGZiNDdhMjhmMmZhNzMiO3M6MTI6InNlc3Npb24uaW5mbyI7YTozOntzOjI6InRzIjtpOjE3NjI3OTc0OTM7czoxMDoicmVtZW1iZXJlZCI7YjowO3M6MTA6ImV4cGlyYXRpb24iO2k6MTc2MjgwMzcxMDt9czoxMjoibm90aWZpY2F0aW9uIjthOjE6e3M6MTM6Im5vdGlmaWNhdGlvbnMiO2E6MDp7fX19\";}'),('7f04bf07dd66cd91e359141006d1788e9ca3dedb6490f8ebfcdffef66a5271b67bbcc44f54e05d0e3c899f5d780d0895846de427369a2464f9178636f979c927',1762787041,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIzYmM4YTQzMzEyYjI2MzZlYmNmOWQxMGQ4NDRmOTZmNiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3NjQxO319fX0=\";}'),('7f9a6505736e9c91fa73b04509fadbce10de6b968fc3bcf5fc0a135536af1cb2b646334c59ab4d7254d37f6fb5a6b52cfa17ac1daee7675c8de72a2a567f9d20',1762801837,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI3Njk3YzU5MWU0ZDliYTc3MjRiMTU1Yzc3YTFiN2M5ZCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyNDM3O319fX0=\";}'),('8610e0acf01f936b758bf9199b93d51194d5c019c9d77b95db55988811da6595bf1f73e74ebfbded1acb753c7669a67ac27b2b26070aaa25b8c896150599030b',1762786377,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkNmNlZTJhNjQ5Nzk2YzQwZmVmNmZiYzA5ZGJkYjBiYSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg2OTc3O319fX0=\";}'),('8883c0c4ed4f486907d04e4d8d1598ce2f5a61e754b2876b101df299cc3867a28bce1990524f258db6e268173d27f5d128dd11f7a93d6672dbcecf9211c26a27',1762786317,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI5NWU1NTUzYjA5M2E2YWQ4NjYxYTliNTMzYWZjNzNjOSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg2OTE3O319fX0=\";}'),('8db9d2f19b3fc5e1905b8354ead699b96de106bf38e44c64e87853e64ca196cd6a3c890e71935e2d9524ce196e6ef30f6bd07172de4b35dd0224f16d83850b18',1762800626,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIyYzE3YWQyZmI0YjhlZGJmMjAyZDVhMTQ3YzA4MDk4YyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxMjI2O319fX0=\";}'),('91f0b1278bd97db7cabc7c60d0a6e34854192a1626668e227744633c78b43ac6a555e959e12a9cceffaaba63e70223190b60149107e7c46afe804c14a2a3f8cf',1762801169,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI3NmQ2OGFjOGRiNTIyYjZkNTc4OWU0MjBiN2U2MzZiOSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxNzY5O319fX0=\";}'),('9296fd52a97bbcb9d6603f89c057616b3b7a6d36e833fcbd22dfd10435445c601bf257c574bd33ae349159e2071ff73b6b84cd5eb4d2e53f4154d06487c9810c',1762787925,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI2ZGRkZmI4NDg0YTJjODNhZWE3Y2RhMjRhM2EzMjE1MiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg4NTI0O319fX0=\";}'),('9391a55b446edec3593e0f95d0d56275f971fc736e44093836b671d851b204a6aff64737ed9c5000c4b12477a38facc591a5e510598b6046776510f8b456b208',1762796290,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJhYzEzZDFkODU3OGU4ZTdkODQ1YWQ4NDNiYjY1Yjg1MCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk2ODkwO319fX0=\";}'),('95ed3eb334e721280edbc604d9f43e79efcfe5e9071b6ec04fc965332099cb73bf9c385d46f2c1f979d9f73d457209d04bbf779c7cb9117829c0e52c853c5534',1762797408,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI1YTFlZTBhYjViN2EwZGUwY2U5YTJlMDZmNmQ5ZGQ3OSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk4MDA4O319fX0=\";}'),('96f08367f60d38267a3bde0c16fbb48c15b5e13480db99929d963eb45474d6eed4284a0084a0e5bbdc7ed3124309b8b33b375140eebba1fea5d6d0b5c0d0248a',1762801651,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJmY2QwNGI5ZjM0MmM5MmI2OTFmMzM3YTc3MWExM2M5YiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyMjUxO319fX0=\";}'),('97b69e8ede924f0c15d119f48e5fcc4664fc657b291c28191c0c9835d4fa7ed20b673d85507978a591e90e9822fe10411f87efd58ca62e71240ed3134c5d713e',1762801470,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI1ZThjMzE2Yjc5MjVkNjVjYjJmMWQ1NDhkN2MyZTgzMCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyMDcwO319fX0=\";}'),('9cea94e11d62233138553668f3f2a72b2a401d5d06a3140c5174a1dc134fa07cbf424cb60f696912f5632dd977b10b2d995bd55e59ab78bf2fe424643156c388',1762786558,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkMTBlZjc4N2Y0MWMwYjQyMzcxOTViYWUyYjgzNzk0MyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3MTU4O319fX0=\";}'),('9df03e8bd718bf4a0cf7d42e012db2a8558c370244610bfd966ef9f214e808ac331bccf4aaf57ca869c1b6088fa5af17222c1f6e1a9f291b8679a93669c7961f',1762797589,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI2YjIyODEyYWQzZWZjOTg0YzJlN2VlOGI3ZTQzMWFlOCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk4MTg5O319fX0=\";}'),('a2ba3476e6661fb1d2ee831698b5e2ef7cd7a8ae653ad601a579d7cb3b8f124bd9474a92d34906ea25087a0ff96c6cb756e842795deb077940ada244dc986974',1762800203,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI3OWM4MWFmNGM4NmVhMGIzODIwNGIyNDhiYzVmM2ZiYyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAwODAzO319fX0=\";}'),('a34a6dd3dd7680d2d72fb8e119a143064b7c967e1baa88a46d594ca90540da28b020c554118514ec65d42773b4e70c116006925c52d9468cb342cd5ffba9b984',1762800384,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIwMDhlNTE2YWYyMGZlNGNjYmExMDczZDUzNTBjNjM0MSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAwOTg0O319fX0=\";}'),('a5d7144003b0d3e6c66465f3a708ba1f844f980e624fff8443faa90447b6dcbff0abab801286bcd2897ab9f6dca9fe6ea00e04cdfb5367deb9229a04e67a687f',1762787161,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJjM2Q5MmI2NDZhMWM2N2Q3MWE1Nzg1OGM4OWMwMGM5NiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3NzYxO319fX0=\";}'),('a6f067113e0cce4ac2634c21966a578b2312059fa3172d89d47bcbdebcc25b153d14e29713044a61fd19be32fdd02c4e47897efb7e90ab5560b021f23d039604',1762800264,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIwNjY1NDgzNmRhODJmODlmZTk1YzNhMzc0NjIwMGRhOCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAwODY0O319fX0=\";}'),('ab7ae62ea267780a7bb7b4f9b00a6c5d0f23fda68a037748fad97ffaff0bde750d158653f83a07f1305c653b4a63236951a2335a68ef851aa317267785dc6479',1762796592,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJlNDJkNDY4MDFmYTY5ZWZmOTA1NmI1YzUwYWM0NWFlMiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3MTkyO319fX0=\";}'),('b03c2b6666861f12015ef90016c10774fe360355728ac754d8e064c4a0f20c7fc43a4e9f374af96a8dd0ba312cb0dff52c190b1d2e834bdf8f4f51d299887b47',1762802018,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI4NTk4NjRkMTRlZDg1Y2IwOThiYTllNTc1YjEwNWY5YSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyNjE4O319fX0=\";}'),('b0622e5b1642b08c55d0b24faf35cb51831e9298c6c6b12611652e691842f65433886d16c11db537b3a532e9503a423b2c48c68df24ca0a88d70613ba2ac1a94',1762796948,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkZGI1Njc5OGE2ZjFhZDI4MzIzY2MzNTEzNGUyYzBkZiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3NTQ4O319fX0=\";}'),('b072a7ad1ae848e778c4871bd35e7f24b845dc9809366e6f2036c5912bb4228afd20a6d5980d10432f9f1809c53f5fdfd236c61956ea45fc6583b6ae44a1978b',1762786619,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIxNTQ4NWQyNTRjOWQ2ZDE2MDg5ZThhMjhhNjUxZmI1NSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3MjE5O319fX0=\";}'),('b3776aa18cd47bdc78bd764813ddb1af050085f639ee1655fbedd686b4179435af165240f9c917d30d4c49718603211ea9590c68c32fe33e04a4cc3923b1a8cf',1762787503,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI1ZTQ0NjQ3ZDJhYWQwN2M3ZmM5MjFjYjJjNmIwODYyMSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg4MTAzO319fX0=\";}'),('bad32dfae17bd45a37879dde57741b31d8a83e71e8ecbf46b7fba19acc83ef74a4578299e3b8a0f918869c8ec7f4f3740caefec26ae1bc7526ea6ae94f3c3527',1762801531,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJjMjI3NTNiNjU1MDEwZGZhZmQ4MDIzMzU1YTI3YmM5MSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyMTMxO319fX0=\";}'),('bbede0e70e03b742a4f1eec7274ce0ed010f2d54a5439cc9c04228d6a3eaec05ac7f0ffcf2d8b7bafb83c3a563281b54bfc6f67e562981c8e3336f300e0931a1',1762796767,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI4NzJmOWMwNTk3ZjRjYjMyNDc3NDliZGY3MTEzYzczMCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3MzY3O319fX0=\";}'),('bc5bf5f4f57e25534effda68cecb4e452b7e16e74765003865e223f4fa9e5bd4e5550ddedfa09ca484658270a0b36fa8754da9651e6cdebe52ebe9dbeee0295e',1762787804,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJhMWJlODA1NmM1YzE5MDBiODMzMWJmNDdmZDIwNzQ0MyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg4NDA0O319fX0=\";}'),('bc719ea460a0f97fcec1d09062da9d30a61b6569afd52e64ba9f1b3c04355f853239abe84eb6799e16f234e1672f7551c7904ff89ea3469daba78c216dfcdd3f',1762802078,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkNjllYmQ0MDgxNWM3Mzc4MTU2YzNmOGUyZDMyNWY3NiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyNjc4O319fX0=\";}'),('bdf5c8da0d4cd51cb2eb8a143c985f459144eceb5be71adb2f6087edddd503b793e91887c942d042119f569d0152811ea045405969fb58b9da990b534fd579da',1762802068,1209600,'a:1:{s:4:\"data\";s:400:\"YTo1OntzOjk6InVzZXIubmFtZSI7czoxNDoiYW5hbHl0aWNzX3VzZXIiO3M6MjI6InR3b2ZhY3RvcmF1dGgudmVyaWZpZWQiO2k6MDtzOjIwOiJ1c2VyLnRva2VuX2F1dGhfdGVtcCI7czozMjoiYmJhODBhYjkxZDQzOTNhYTkxZjkwZGJjNTczZDVjNzgiO3M6MTI6InNlc3Npb24uaW5mbyI7YTozOntzOjI6InRzIjtpOjE3NjI4MDA0NzQ7czoxMDoicmVtZW1iZXJlZCI7YjowO3M6MTA6ImV4cGlyYXRpb24iO2k6MTc2MjgwNTY2ODt9czoxMjoibm90aWZpY2F0aW9uIjthOjE6e3M6MTM6Im5vdGlmaWNhdGlvbnMiO2E6MDp7fX19\";}'),('bf4713a36d47570598eeed229a9e234e8b99899f34fcde06fadb3ed898f314ba1ff70307ef1b0a83e9646704810d35a2035be5aa8804f082d5c790342bf0e3c4',1762800143,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI3Y2NiZmI5YTY3MzZlN2JhYTA2MWZhY2MwYmZjMGUwZCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAwNzQzO319fX0=\";}'),('bf6a45b03ac2717b12269cbc63a30c98bf90130e61824653098e6d9870870365fa22f0bb6831bfaf6c41f766c5411ed2ddfa8b8e5d5d29f89a4bdc623e6c6cca',1762787222,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkNGI5YmEzMjUxNTcwOGUxNDkwNmNiMzQwYjA3YTE5NyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3ODIyO319fX0=\";}'),('c2d59b2e788925d7957d2ba6dcd643fd5f7aaba84077fb10a4fa023cd9adb8cafe73507fc9750653bcda8441a4b301c9ccb23d7443b3b171bd73e5bc8d9920e4',1762797529,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIxYjkzZTQyOTUzMGU5Y2RmMTUwY2MzNTVjZTZmNGE1OCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk4MTI4O319fX0=\";}'),('c6fa4e1aa5d2d4148b30aa67af7400b98254da8cd7979a3915ce6bdc9531b6f9e60a42f4178388bc3393868e9080e06a43b28fe6fbf077ac5d5883b87645e4cc',1762797129,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI3ZTg3YmU3MzkzZjYwMDQ1ZDRlMjU3YzQyYTA1NWZmYyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3NzI5O319fX0=\";}'),('c7a1d9f3f81ed14a6bedd4bd0e5606a3137f814c92e7cc948dd74bc9a3eaa1681c7960f8c16f6e5f379f8a543142aa50ab9f8b59aedfa7a749a413d8ea263ed9',1762800927,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI5MTU0YzBkZWQzM2VmZDY3MTBkNWIyNWZlODJjNWFmZCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxNTI3O319fX0=\";}'),('c88f72763ffb0391bba14474c001f01be64a194d73602f9b8132bbfbd59f89e257d887b0a7ead772b00114c0d899dcc9eccbaa48040b03e4453de41c5ec8f0ce',1762797226,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJkZjJjMjNmZDAxMmVlNjNhZDIxOTNkMGZmODRjYzg3OSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3ODI2O319fX0=\";}'),('ca45e8a8e188993b0b6c6cb7cad3a42132f03c7bb4982d2261906a90bcf221ba44534c971a5196d76335bca2316846894b112cdb32be956385263440fceab020',1762801048,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI1Y2E5MGViNzY5ZWYzNzdkODAxNjRlZWRmM2ZmMDhhYiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxNjQ4O319fX0=\";}'),('cade43fbaab2a8802d7a73c16a20689d8c625383a1fb1d085d9887521987215b6c75220422f61e63c346716d70fbc5d7f3c9b18493bbb6a38d9624fe801007de',1762786136,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI0ODdlMjc4N2ExYWNhN2IzMmM2NTZiZGNkZTc1ZmU0MyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg2NzM2O319fX0=\";}'),('cd87dec0677501fc1203c2d2a685c36f5fa8c7bab4910437021ff2e35b1997710b7f590bcef58afd0a0628aeb6c90c8c474a27e1eccad1f464670bc6bb3b73c5',1762800565,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI2MTBlYTM1OWNjNWUxZjY2NjQ5NTdiNGM3ZWQ2YWY0NCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxMTY1O319fX0=\";}'),('cfbfdfa8e576c37d371ea36d51f9178d44ca85de0f9fc45138a61ece7397e695c4ad18c0f9a0e3c8abf1e4c1cdc5f1e608c8ee2af8b05ef6d920ddf2e05a899b',1762796471,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJmZjg1NWE3NzMwZWUxNzRlMTY2NWIyMTVmNzk2ZjJkNCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3MDcxO319fX0=\";}'),('d3453a12b342479028878eeb2171b5e7223ce4796e7e15fd37d02997cfeb51def0b4c4ecaa1010c7d6e5092c0901c0f6997f753c5983b90e908e91a61dc8fe21',1762786257,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI1ZDBiNjJiZGFiNmFkMGI1ZWM1NzBhZjU3ODFlZTA1ZCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg2ODU3O319fX0=\";}'),('d45b261662ab4bc2b2fde5edc6a68418a6c1299a3f270b2bce9d8a8fc6884ec3d8779c49def3773f1fb550db5533ff05513b650b4e16da35ee1ae286b41885a4',1762787101,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI0MDU3NDI4NDhhNzllYTVhMzg2YWI5ZDQxOTM0OWFjNSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3NzAxO319fX0=\";}'),('d67a40100e6a8b4ec877ea75364d1b50288f4260b22f1e3999cf76593b4dc265543b6968ba908a65b2ee6f2b06355fc2077ec385c4ff21e9fe02060e9f60739b',1762786438,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJmMWMyN2ZhODQzYjEwYmM0ODczNGM1YzIxMGQwY2Y0ZiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3MDM4O319fX0=\";}'),('d6932e614a54dbb56493d5392cc8f4506c46e2ad47704ef558829bf65f95e46538178b6977c0ad3358d60a222efd1ac6938d38d502709590e6083939abf5c4cd',1762797069,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIxNzI0OTZlYzhhNTgxZDFiNmZkYjQzZDQ1OWUwYjgzYyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3NjY5O319fX0=\";}'),('d98488c7b7180717c9471c75473d46f6265374c7311f44cd50cde5b95247815ad1bac5d4b28c0f17f16dda21b528f237a4792096a3e360e1fb40c7617ff6ad6e',1762802390,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJiYzliMWIwNzBlNjY2MDM0YmU4NGY1MTlkZGFkM2I5NiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyOTkwO319fX0=\";}'),('da94d5b5ac8e2d5e2b491e2bb0d300a5bbad35ba6e78003b552993d5656ec0db731fdf19c5d02b3547493584be8ba9511b88e12d578c7dcd9c645413ed825690',1762800505,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIxNjA0ZjRlOWY0MTY1OGUyMjE2MDkyOWU5MzA5M2Q1MiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxMTA1O319fX0=\";}'),('de8b230efa260b25a484a588bcc686ce7c9128f476c33e858b607be9fbb254a6fa2c5ce053e60ad19f84180f8ad5ea62676fedc4cfdc0c219e4f43d85d2f7fb2',1762800807,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIyNDY1OGNmNDY5MWE0Y2JhOTBlNDE1Y2M5Y2M5YzFkNyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAxNDA3O319fX0=\";}'),('e0ccfa64f2ba1b8478f1eaef248130dd8379d93bb6271b929782584bbc13ae876df7847230467a0a594dc1fb40ae7de7850adc9b4c830f187330d7b8f7c3d83e',1762796888,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI3MTYxYTUxN2I5ZmFhYzA5ZjE4NGNlODhiOTJjOTE0OCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3NDg4O319fX0=\";}'),('e6f1f72e5f1e74206000086a50f5eac3c7b00286d08f16a6420cad3b0822f171f7bf99182667f7b089f4a453adcc3586946c1e59f66f2d8d5371aed67ef3f45c',1762788166,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI4ZWE3NmY4YWU4YWE2N2U3ZWIxMmY2YjMyNjg2MDI0YSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg4NzY2O319fX0=\";}'),('eb604c7720e1403da9d01fa3c36ca81b8ed252f91985b8570ad378f6a62c568602004745feadec89b373a7189908dab5b75089bbba070c80bcef0f4f4b4e4489',1762801410,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI2ZmNlODhlMWU4ZjZmZWJjOWM5NDJkOGVkY2MwM2IwOSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAyMDEwO319fX0=\";}'),('f5a6d0695e42e84fe096e97fc37de12d4dd398a85bbbb00191dacf4550655a6c798c342179853091113ef99b3277b91ec72830d30be81372f6b1e988f289270d',1762797649,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiIyMTBmZGYxN2JlZjA2YjJmNmZjNzRiZjAwNGI5YWU1NyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk4MjQ5O319fX0=\";}'),('f9374e7f3e8d90970f2d1308c824cbebad7f634c61264ea6ff844ae51ac745818683521e2366803ccd144deff0547b71b485ce7f0bafdd39f5d4ec6ff1862385',1762787985,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJlOTMyNzlkZDYxMGVkNTNlYzMwZWQ0Yjk3MzcyNzg2MyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg4NTg1O319fX0=\";}'),('fa53493324f004dfb7857709f6a5163eb0e5969ba4fa02cfe38e6a1f346702039f941c813b3a04c32fe60a3cb2d0fbf3928436473c7b474f3171a267baa94e14',1762788045,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI4ZTNkODQ5ZjQxMjIyNmEyMzVjN2I5YTg1OTMwZGMzNyI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg4NjQ1O319fX0=\";}'),('fb484105e6e0e846473c0cecbc73bed4524f300d04690ba2d6a0b17ab861b58dabab4b94ac28ee63a006710fed034b555cb20e3baa202940aaf619296d8a52ae',1762796532,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI0MDI4ZWIyNzZlMGZhNzUyMmFjOGIwMWY1Yzg2ZmIwOSI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzk3MTMyO319fX0=\";}'),('fba09add5df5adeecedc97be69a0e46e298bc24e01096e3d83789d876f336816fc8faa8eadc152ce850770e72826a7900ec680859fdb650230953742aa431844',1762799898,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiI1MDJlNTQwOTUzN2EwNzYxZjAyM2NkOWJiMzhlNDkzMCI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyODAwNDk4O319fX0=\";}'),('fdb93962cd179ec969876a8aaf71cd5396472a6a98b1cffd29154b95a0ac3f7447dfad20f8ae32815d7c9bc17eee9261461982cb023e8a8dcc7c071d3a057d55',1762786739,1209600,'a:1:{s:4:\"data\";s:224:\"YToyOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjU6Im5vbmNlIjtzOjMyOiJjZTcyOTExYmJlMWU5OWJkMWFlYmI0MTk4Njc0NWNlMiI7fXM6NDoiX19aRiI7YToxOntzOjExOiJMb2dpbi5sb2dpbiI7YToxOntzOjQ6IkVOVlQiO2E6MTp7czo1OiJub25jZSI7aToxNzYyNzg3MzM5O319fX0=\";}');
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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_site`
--

LOCK TABLES `matomo_site` WRITE;
/*!40000 ALTER TABLE `matomo_site` DISABLE KEYS */;
INSERT INTO `matomo_site` VALUES (1,'snappymail','https://snappymail.zoo','2025-11-10 14:03:38',0,1,'','','America/Los_Angeles','USD',0,'','','','','','website',0,'anonymous'),(2,'search','http://search.zoo','2025-11-09 00:00:00',0,1,'','','America/Los_Angeles','USD',0,'','','','','','intranet',0,'analytics_user');
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
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matomo_site_setting`
--

LOCK TABLES `matomo_site_setting` WRITE;
/*!40000 ALTER TABLE `matomo_site_setting` DISABLE KEYS */;
INSERT INTO `matomo_site_setting` VALUES (1,'Live','disable_visitor_log','0',0,7),(1,'Live','disable_visitor_profile','0',0,8),(2,'Live','disable_visitor_log','0',0,15),(2,'Live','disable_visitor_profile','0',0,16);
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
INSERT INTO `matomo_site_url` VALUES (1,'http://snappymail.zoo');
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
INSERT INTO `matomo_user` VALUES ('analytics_user','$2y$12$NvXiJv0MkAwt2oCN/dnvEe6UeS7QEdPwCA0HT3VyoEqnl2zHFoGwK','analytics_user@snappymail.zoo','',1,'2025-11-10 12:28:53','2025-11-10 12:28:53',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2025-11-10 19:11:11',NULL),('anonymous','','anonymous@example.org','',0,'2025-11-10 12:28:17','2025-11-10 12:28:17',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
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
INSERT INTO `matomo_user_token_auth` VALUES (1,'anonymous','anonymous default token','99e6d1f0b8387a9b8cb1095f49a7ca6944b49d35efa8f65054debc2a9a34022dacc21ad248b3602b9b8ce31b7a1286508b68cf0d22e899c280e9add88d5ee1e9','sha512',0,'2025-11-10 19:19:50','2025-11-10 12:28:17',NULL,0,NULL,NULL);
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

-- Dump completed on 2025-11-10 19:20:07
