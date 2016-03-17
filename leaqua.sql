--
-- Database: `leaqua`
--

-- --------------------------------------------------------

--
-- Table structure for table `leaqua`
--

CREATE TABLE IF NOT EXISTS `leaqua` (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '고유 ID',
  `temp` varchar(4) DEFAULT NULL COMMENT '온도',
  `date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT '저장시간/날짜',
  `ph` varchar(5) DEFAULT NULL COMMENT 'PH 수치',
  `orp` varchar(6) NOT NULL COMMENT 'ORP 수치',
  `REL1` tinyint(1) NOT NULL COMMENT '릴레이 1 ON/OFF',
  `REL2` tinyint(1) NOT NULL COMMENT '릴레이 2 ON/OFF',
  `REL3` tinyint(1) NOT NULL COMMENT '릴레이 3 ON/OFF',
  `REL4` tinyint(1) NOT NULL COMMENT '릴레이 4 ON/OFF',
  `REL5` tinyint(1) NOT NULL COMMENT '릴레이 5 ON/OFF',
  `REL6` tinyint(1) NOT NULL COMMENT '릴레이 6 ON/OFF',
  `REL7` tinyint(1) NOT NULL COMMENT '릴레이 7 ON/OFF',
  `REL8` tinyint(1) NOT NULL COMMENT '릴레이 8 ON/OFF',
  PRIMARY KEY (`id`),
  KEY `date` (`date`),
  KEY `orp` (`orp`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `leaqua_maxmin`
--

CREATE TABLE IF NOT EXISTS `leaqua_maxmin` (
  `id` int(5) NOT NULL AUTO_INCREMENT,
  `temp` varchar(4) DEFAULT NULL,
  `ph` varchar(5) DEFAULT NULL,
  `orp` varchar(6) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `leaqua_users`
--

CREATE TABLE IF NOT EXISTS `leaqua_users` (
  `userID` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL DEFAULT '',
  `password` varchar(100) NOT NULL DEFAULT '',
  `email` varchar(150) NOT NULL DEFAULT '',
  `active` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`userID`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  KEY `active` (`active`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

