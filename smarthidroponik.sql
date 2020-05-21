/*
Navicat MySQL Data Transfer

Source Server         : denahardian
Source Server Version : 100129
Source Host           : localhost:3306
Source Database       : smarthidroponik

Target Server Type    : MYSQL
Target Server Version : 100129
File Encoding         : 65001

Date: 2018-01-21 09:08:08
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for alat
-- ----------------------------
DROP TABLE IF EXISTS `alat`;
CREATE TABLE `alat` (
  `id_alat` int(2) NOT NULL,
  `id_status` int(2) DEFAULT NULL,
  `id_tanaman` int(3) DEFAULT NULL,
  `user_raspi` enum('guru','siswa') DEFAULT NULL,
  `status` enum('tidakaktif','aktif') DEFAULT 'tidakaktif',
  PRIMARY KEY (`id_alat`),
  KEY `id_status` (`id_status`),
  KEY `id_tanaman` (`id_tanaman`),
  CONSTRAINT `alat_ibfk_1` FOREIGN KEY (`id_status`) REFERENCES `status` (`id_status`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `alat_ibfk_2` FOREIGN KEY (`id_tanaman`) REFERENCES `tanaman` (`id_tanaman`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for atur_sensor
-- ----------------------------
DROP TABLE IF EXISTS `atur_sensor`;
CREATE TABLE `atur_sensor` (
  `id_atur_sensor` int(6) NOT NULL AUTO_INCREMENT,
  `ec` float DEFAULT NULL,
  `ph` float DEFAULT NULL,
  `tanggal_waktu` datetime NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `id_kelompok` varchar(8) NOT NULL,
  PRIMARY KEY (`id_atur_sensor`),
  KEY `id_kelompok` (`id_kelompok`),
  CONSTRAINT `atur_sensor_ibfk_1` FOREIGN KEY (`id_kelompok`) REFERENCES `kelompok` (`id_kelompok`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for kelompok
-- ----------------------------
DROP TABLE IF EXISTS `kelompok`;
CREATE TABLE `kelompok` (
  `id_kelompok` varchar(8) NOT NULL,
  `nama_tanaman` varchar(15) DEFAULT NULL,
  `nip` varchar(20) DEFAULT NULL,
  `id_alat` int(2) DEFAULT NULL,
  PRIMARY KEY (`id_kelompok`),
  KEY `id_alat` (`id_alat`),
  KEY `nip` (`nip`),
  CONSTRAINT `kelompok_ibfk_1` FOREIGN KEY (`id_alat`) REFERENCES `alat` (`id_alat`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `kelompok_ibfk_2` FOREIGN KEY (`nip`) REFERENCES `user_guru` (`nip`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for log_sensor
-- ----------------------------
DROP TABLE IF EXISTS `log_sensor`;
CREATE TABLE `log_sensor` (
  `id_log` int(6) NOT NULL AUTO_INCREMENT,
  `id_atur_sensor` int(3) NOT NULL,
  `tanggal_waktu` datetime NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `ec` float DEFAULT NULL,
  `ph` float DEFAULT NULL,
  `nis` varchar(255) DEFAULT NULL,
  `id_kelompok` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_log`),
  KEY `id_sensor` (`id_atur_sensor`),
  CONSTRAINT `log_sensor_ibfk_1` FOREIGN KEY (`id_atur_sensor`) REFERENCES `sensor` (`id_sensor`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for sensor
-- ----------------------------
DROP TABLE IF EXISTS `sensor`;
CREATE TABLE `sensor` (
  `id_sensor` int(3) NOT NULL,
  `temp` float DEFAULT NULL,
  `ec` float DEFAULT NULL,
  `ph` float DEFAULT NULL,
  `id_alat` int(2) DEFAULT NULL,
  PRIMARY KEY (`id_sensor`),
  KEY `id_alat` (`id_alat`),
  CONSTRAINT `sensor_ibfk_1` FOREIGN KEY (`id_alat`) REFERENCES `alat` (`id_alat`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for status
-- ----------------------------
DROP TABLE IF EXISTS `status`;
CREATE TABLE `status` (
  `id_status` int(2) NOT NULL,
  `stat_ec` enum('ON','OFF') DEFAULT 'OFF',
  `stat_ph_up` enum('ON','OFF') DEFAULT 'OFF',
  `stat_ph_down` enum('ON','OFF') DEFAULT 'OFF',
  PRIMARY KEY (`id_status`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for tanaman
-- ----------------------------
DROP TABLE IF EXISTS `tanaman`;
CREATE TABLE `tanaman` (
  `id_tanaman` int(3) NOT NULL AUTO_INCREMENT,
  `nama_tanaman` varchar(15) DEFAULT NULL,
  `ec_min` float DEFAULT NULL,
  `ec_max` float DEFAULT NULL,
  `ph_min` float DEFAULT NULL,
  `ph_max` float DEFAULT NULL,
  PRIMARY KEY (`id_tanaman`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for user_guru
-- ----------------------------
DROP TABLE IF EXISTS `user_guru`;
CREATE TABLE `user_guru` (
  `nip` varchar(20) NOT NULL,
  `nama_guru` varchar(30) DEFAULT NULL,
  `status` enum('pengelola','guru') DEFAULT 'guru',
  `password` varchar(20) DEFAULT NULL,
  `id_alat` int(2) DEFAULT NULL,
  PRIMARY KEY (`nip`),
  KEY `id_alat` (`id_alat`),
  CONSTRAINT `user_guru_ibfk_1` FOREIGN KEY (`id_alat`) REFERENCES `alat` (`id_alat`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for user_siswa
-- ----------------------------
DROP TABLE IF EXISTS `user_siswa`;
CREATE TABLE `user_siswa` (
  `nis` varchar(20) NOT NULL,
  `nama_siswa` varchar(30) NOT NULL,
  `kelas` enum('X','XI','XII','') NOT NULL DEFAULT 'X',
  `password` varchar(20) NOT NULL,
  `id_kelompok` varchar(8) DEFAULT NULL,
  `stat_kelompok` enum('pending','diterima','non_aktif') NOT NULL DEFAULT 'non_aktif',
  `status` enum('siswa') DEFAULT 'siswa',
  PRIMARY KEY (`nis`),
  KEY `id_kelompok` (`id_kelompok`),
  CONSTRAINT `user_siswa_ibfk_1` FOREIGN KEY (`id_kelompok`) REFERENCES `kelompok` (`id_kelompok`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- View structure for v_login
-- ----------------------------
DROP VIEW IF EXISTS `v_login`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER  VIEW `v_login` AS SELECT nip AS no_induk, nama_guru AS nama, status, password FROM user_guru
UNION
SELECT nis AS no_induk, nama_siswa AS nama, status, password FROM user_siswa ;

-- ----------------------------
-- View structure for v_monitoring_guru
-- ----------------------------
DROP VIEW IF EXISTS `v_monitoring_guru`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost`  VIEW `v_monitoring_guru` AS SELECT
user_guru.nip,
alat.id_alat,
sensor.temp,
sensor.ec,
sensor.ph
FROM
user_guru
INNER JOIN alat ON user_guru.id_alat = alat.id_alat
INNER JOIN sensor ON sensor.id_alat = alat.id_alat ;

-- ----------------------------
-- View structure for v_monitoring_siswa
-- ----------------------------
DROP VIEW IF EXISTS `v_monitoring_siswa`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost`  VIEW `v_monitoring_siswa` AS SELECT
kelompok.id_kelompok,
alat.id_alat,
sensor.temp,
sensor.ec,
sensor.ph,
user_siswa.nis
FROM
user_siswa
INNER JOIN kelompok ON user_siswa.id_kelompok = kelompok.id_kelompok
INNER JOIN alat ON kelompok.id_alat = alat.id_alat
INNER JOIN sensor ON sensor.id_alat = alat.id_alat ;
