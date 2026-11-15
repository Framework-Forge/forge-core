-- PR Bridge SQL Backup
-- Mode: both
-- Tables: 168
SET FOREIGN_KEY_CHECKS=0;

-- Structure for `ar_prop_groups`
DROP TABLE IF EXISTS `ar_prop_groups`;
CREATE TABLE `ar_prop_groups` (
  `group_name` varchar(64) NOT NULL,
  `enabled` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`group_name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `ar_props`
DROP TABLE IF EXISTS `ar_props`;
CREATE TABLE `ar_props` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `model` varchar(64) NOT NULL,
  `pos_x` float NOT NULL,
  `pos_y` float NOT NULL,
  `pos_z` float NOT NULL,
  `quat_x` float NOT NULL DEFAULT 0,
  `quat_y` float NOT NULL DEFAULT 0,
  `quat_z` float NOT NULL DEFAULT 0,
  `quat_w` float NOT NULL DEFAULT 1,
  `group_name` varchar(64) NOT NULL,
  `render_distance` float NOT NULL DEFAULT 200,
  `expires_at` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_group` (`group_name`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `ar_props_player_access`
DROP TABLE IF EXISTS `ar_props_player_access`;
CREATE TABLE `ar_props_player_access` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(64) NOT NULL,
  `name` varchar(64) NOT NULL,
  `groups` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `zones` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `max_expiry` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_identifier` (`identifier`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `bank_accounts_new`
DROP TABLE IF EXISTS `bank_accounts_new`;
CREATE TABLE `bank_accounts_new` (
  `id` varchar(50) NOT NULL,
  `amount` int(11) DEFAULT 0,
  `transactions` longtext DEFAULT NULL,
  `auth` longtext DEFAULT NULL,
  `isFrozen` int(11) DEFAULT 0,
  `creator` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Data for `bank_accounts_new`
INSERT INTO `bank_accounts_new` (`id`, `amount`, `transactions`, `auth`, `isFrozen`, `creator`) VALUES
('bcso', 0, '[]', '[]', 0, NULL),
('cardealer', 0, '[]', '[]', 0, NULL),
('bus', 0, '[]', '[]', 0, NULL),
('reporter', 0, '[]', '[]', 0, NULL),
('vineyard', 0, '[]', '[]', 0, NULL),
('lawyer', 0, '[]', '[]', 0, NULL),
('taxi', 0, '[]', '[]', 0, NULL),
('mechanic', 0, '[]', '[]', 0, NULL),
('tow', 0, '[]', '[]', 0, NULL),
('realestate', 0, '[]', '[]', 0, NULL),
('unemployed', 0, '[]', '[]', 0, NULL),
('hotdog', 0, '[]', '[]', 0, NULL),
('trucker', 0, '[]', '[]', 0, NULL),
('judge', 0, '[]', '[]', 0, NULL),
('ambulance', 205000, '[]', '[]', 0, NULL),
('sasp', 0, '[]', '[]', 0, NULL),
('police', 42942, '[{"trans_type":"deposit","time":1783548387,"issuer":"Forge Core","amount":19800,"receiver":"Policia","trans_id":"c48c2a8e-b28e-4b23-8940-3d586547f697","title":"Venda da loja","message":"forge-core:shop-sale"},{"trans_type":"deposit","receiver":"Policia","title":"Venda da loja","amount":3200,"issuer":"Forge Core","trans_id":"0cdeb631-a611-4bed-8ef3-cb55601fd29a","time":1783460832,"message":"forge-core:shop-sale"},{"trans_type":"withdraw","receiver":"Pierre Mkz","title":"Personal Account / police","amount":833,"issuer":"Pierre Mkz","trans_id":"95c3787c-e9d2-4040-998f-e1ead956670a","time":1783460810,"message":"Pierre Mkz has withdrawed $833"},{"trans_type":"deposit","receiver":"Policia","time":1783263652,"title":"Venda da loja","issuer":"Forge Core","trans_id":"ac1df8cd-5687-4fa8-ac5a-509b8ee39c74","amount":832,"message":"forge-core:shop-sale"},{"trans_type":"deposit","receiver":"Pierre Mkz","time":1783263613,"title":"Personal Account / police","issuer":"Pierre Mkz","trans_id":"f24b6476-6e74-4357-a0e1-c7dc05dc58a0","amount":1,"message":"Pierre Mkz has deposited $1"},{"trans_type":"withdraw","receiver":"Pierre Mkz","time":1783263602,"title":"Personal Account / police","issuer":"Pierre Mkz","trans_id":"9b0eae90-b9a0-44b7-8cbb-b187727ece72","amount":60,"message":"Pierre Mkz has withdrawed $60"},{"trans_type":"deposit","receiver":"Policia","issuer":"Forge Core","title":"Venda da loja","amount":20040,"trans_id":"ef4cbe21-9a9c-45a2-993e-ccd120cf2d19","time":1783260882,"message":"forge-core:shop-sale"},{"trans_type":"deposit","receiver":"Policia","issuer":"Forge Core","title":"Venda da loja","amount":20,"trans_id":"b07fe719-2cef-4897-aaa4-8caf45977221","time":1783260868,"message":"forge-core:shop-sale"},{"trans_type":"withdraw","receiver":"Pierre Mkz","issuer":"Pierre Mkz","title":"Personal Account / police","amount":9300,"trans_id":"defc7e4d-711f-4473-a3bc-8b132a6d058a","time":1783260828,"message":"Pierre Mkz has withdrawed $9300"},{"trans_type":"deposit","receiver":"Policia","issuer":"Forge Core","title":"Venda da loja","time":1783258451,"trans_id":"4bf43d13-4189-4b2f-9818-85553e8a3dd6","amount":9300,"message":"forge-core:shop-sale"}]', '[]', 0, NULL),
('garbage', 0, '[]', '[]', 0, NULL),
('triads', 0, '[]', '[]', 0, NULL),
('families', 0, '[]', '[]', 0, NULL),
('none', 0, '[]', '[]', 0, NULL),
('lostmc', 0, '[]', '[]', 0, NULL),
('ballas', 0, '[]', '[]', 0, NULL),
('vagos', 0, '[]', '[]', 0, NULL),
('cartel', 0, '[]', '[]', 0, NULL),
('teste_mei', 1351356, '[{"message":"Pierre Mkz has transfered $811799","title":"Personal Account / ETK100KY","trans_id":"79b9303a-fb24-41b0-92f2-e220a6807dc1","issuer":"Pierre Mkz","receiver":"Teste MEI","time":1782176054,"trans_type":"deposit","amount":811799},{"message":"Pierre Mkz has transfered $500000","title":"Personal Account / ETK100KY","trans_id":"125bf6c7-2f5e-4beb-8f0e-b1986c880096","issuer":"Pierre Mkz","receiver":"Teste MEI","time":1782176037,"trans_type":"deposit","amount":500000},{"message":"Pierre Mkz has deposited $39557","title":"Personal Account / teste_mei","trans_id":"3788014a-4867-4b5b-8393-4ab6919437a0","issuer":"Pierre Mkz","receiver":"Pierre Mkz","time":1782175891,"trans_type":"deposit","amount":39557}]', '[]', 0, NULL),
('government', 0, '[]', '[]', 0, NULL),
('firefighter', 0, '[]', '[]', 0, NULL),
('yacuza', 0, '[]', '[]', 0, NULL);

-- Structure for `bans`
DROP TABLE IF EXISTS `bans`;
CREATE TABLE `bans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `license` varchar(50) DEFAULT NULL,
  `discord` varchar(50) DEFAULT NULL,
  `ip` varchar(50) DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `expire` int(11) DEFAULT NULL,
  `bannedby` varchar(255) NOT NULL DEFAULT 'LeBanhammer',
  PRIMARY KEY (`id`),
  KEY `license` (`license`),
  KEY `discord` (`discord`),
  KEY `ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `bodycam_recordings`
DROP TABLE IF EXISTS `bodycam_recordings`;
CREATE TABLE `bodycam_recordings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` varchar(50) NOT NULL,
  `recording` longtext NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_cid` (`cid`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `character_slots`
DROP TABLE IF EXISTS `character_slots`;
CREATE TABLE `character_slots` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license` varchar(255) NOT NULL,
  `license2` varchar(255) DEFAULT NULL,
  `slots` int(11) NOT NULL DEFAULT 3,
  PRIMARY KEY (`id`),
  UNIQUE KEY `license` (`license`),
  KEY `license2` (`license2`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `codem_adminmenu`
DROP TABLE IF EXISTS `codem_adminmenu`;
CREATE TABLE `codem_adminmenu` (
  `identifier` varchar(50) DEFAULT NULL,
  `permissiondata` longtext DEFAULT NULL,
  `historydata` longtext DEFAULT NULL,
  `bandata` longtext DEFAULT NULL,
  `profiledata` longtext DEFAULT NULL,
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Data for `codem_adminmenu`
INSERT INTO `codem_adminmenu` (`identifier`, `permissiondata`, `historydata`, `bandata`, `profiledata`) VALUES
('RE036OYR', '{"kick":true,"offlineban":true,"spectate":true,"noclip":true,"kill":true,"ban":true,"playername":true,"takescreenshot":true,"bannedplayers":true,"cleararea":true,"godmode":true,"allpermission":true,"freeze":true,"revive":true,"clearinventory":true,"openinventory":true,"weather":true,"repairvehicle":true,"copyxyz":true,"heal":true,"adminduty":true,"gastank":true,"sendpm":true,"givevehicle":true,"copyvector3":true,"announcement":true,"showcoords":true,"giveclothingmenu":true,"giveitem":true,"armor":true,"playerinfo":true,"goto":true,"changejob":true,"addvehicletoplayer":true,"clearvehicle":true,"allkick":true,"bring":true,"copyheading":true,"devlaser":true,"giveperm":true,"addmoney":true,"servertime":true,"copyvector4":true,"invisible":true}', '[]', '[]', '{"steam":"","token":"4:f90a77a760d736074cdf5ecb840fadb14462e7da6bfeeb52dda6fde653605fc8","identifier":"RE036OYR","avatar":"https://cdn.discordapp.com/attachments/983471660684423240/1147567519712940044/example-pp.png","license":"license2:96d348f246a7b8d3624f6d7190ec5355d126076d","name":"Pierre Moraes","discord":"<@340522406332465152>","ip":"192.168.1.8"}'),
('M6YW58XY', '{"sendpm":false,"adminduty":false,"giveclothingmenu":false,"armor":false,"takescreenshot":false,"copyvector3":false,"showcoords":false,"copyheading":false,"allkick":false,"noclip":false,"clearvehicle":false,"goto":false,"giveitem":false,"kill":false,"bannedplayers":false,"devlaser":false,"weather":false,"giveperm":false,"repairvehicle":false,"addmoney":false,"heal":false,"gastank":false,"addvehicletoplayer":false,"invisible":false,"bring":false,"playername":false,"ban":false,"copyvector4":false,"givevehicle":false,"changejob":false,"servertime":false,"godmode":false,"copyxyz":false,"announcement":false,"revive":false,"allpermission":false,"clearinventory":false,"spectate":false,"kick":false,"cleararea":false,"offlineban":false,"playerinfo":false,"freeze":false,"openinventory":false}', '[]', '[]', '{"discord":"<@340522406332465152>","identifier":"M6YW58XY","license":"license2:96d348f246a7b8d3624f6d7190ec5355d126076d","token":"4:f90a77a760d736074cdf5ecb840fadb14462e7da6bfeeb52dda6fde653605fc8","ip":"172.19.112.1","name":"Player Dev","steam":"","avatar":"https://cdn.discordapp.com/attachments/983471660684423240/1147567519712940044/example-pp.png"}');

-- Structure for `dealers`
DROP TABLE IF EXISTS `dealers`;
CREATE TABLE `dealers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL DEFAULT '0',
  `coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `time` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `createdby` varchar(50) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `ds_blipcreator`
DROP TABLE IF EXISTS `ds_blipcreator`;
CREATE TABLE `ds_blipcreator` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `data` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `engate_profiles`
DROP TABLE IF EXISTS `engate_profiles`;
CREATE TABLE `engate_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plate` varchar(12) NOT NULL,
  `type` varchar(16) NOT NULL DEFAULT 'hitch',
  `model` varchar(64) NOT NULL,
  `offset_x` float NOT NULL DEFAULT 0,
  `offset_y` float NOT NULL DEFAULT -1,
  `offset_z` float NOT NULL DEFAULT 0,
  `rot_x` float NOT NULL DEFAULT 0,
  `rot_y` float NOT NULL DEFAULT 0,
  `rot_z` float NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_plate_type` (`plate`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `forge_blip`
DROP TABLE IF EXISTS `forge_blip`;
CREATE TABLE `forge_blip` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `data` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Data for `forge_blip`
INSERT INTO `forge_blip` (`id`, `name`, `data`) VALUES
(1, 'Teste Blip', '{"scImg":"rgb(113, 203, 113)","tickb":false,"Sprite":43,"colors":0,"sRange":false,"scale":1,"bflash":false,"items":0,"outline":false,"SpriteImg":"https://docs.fivem.net/blips/radar_police_heli.png","ftimer":50000,"coords":{"x":121.26593780517578,"y":-161.024169921875,"z":67.107666015625},"hideb":false,"alpha":255,"sColor":2}');

-- Structure for `fox_engine_ac_logs`
DROP TABLE IF EXISTS `fox_engine_ac_logs`;
CREATE TABLE `fox_engine_ac_logs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `player_id` varchar(64) NOT NULL,
  `player_name` varchar(100) DEFAULT NULL,
  `item_name` varchar(100) DEFAULT NULL,
  `reason` varchar(100) DEFAULT NULL,
  `barcode` varchar(128) DEFAULT NULL,
  `detected_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_player` (`player_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `fox_engine_barcodes`
DROP TABLE IF EXISTS `fox_engine_barcodes`;
CREATE TABLE `fox_engine_barcodes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `barcode` varchar(128) NOT NULL,
  `player_id` varchar(64) NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `origin` varchar(50) NOT NULL DEFAULT 'system',
  `created_at` int(10) unsigned NOT NULL,
  `expiry` int(10) unsigned NOT NULL,
  `used` tinyint(1) NOT NULL DEFAULT 0,
  `invalidated` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `barcode` (`barcode`),
  KEY `idx_barcode` (`barcode`),
  KEY `idx_player` (`player_id`),
  KEY `idx_item` (`item_name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `fox_engine_config`
DROP TABLE IF EXISTS `fox_engine_config`;
CREATE TABLE `fox_engine_config` (
  `key` varchar(100) NOT NULL,
  `value` text NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`key`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `frkn_dispatch`
DROP TABLE IF EXISTS `frkn_dispatch`;
CREATE TABLE `frkn_dispatch` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category` varchar(50) NOT NULL,
  `map_data` longtext NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=330 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `frkn_dispatch_data`
DROP TABLE IF EXISTS `frkn_dispatch_data`;
CREATE TABLE `frkn_dispatch_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Unit` varchar(100) NOT NULL,
  `unitdata` longtext NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `profession` varchar(50) DEFAULT 'police',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `frkn_dispatch_drawing_permissions`
DROP TABLE IF EXISTS `frkn_dispatch_drawing_permissions`;
CREATE TABLE `frkn_dispatch_drawing_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `officer_id` varchar(50) NOT NULL,
  `officer_name` varchar(100) NOT NULL,
  `permission` tinyint(1) NOT NULL DEFAULT 0,
  `granted_by` varchar(100) NOT NULL,
  `granted_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `officer_profession` varchar(50) DEFAULT 'police',
  `granted_by_profession` varchar(50) DEFAULT 'police',
  PRIMARY KEY (`id`),
  UNIQUE KEY `officer_id` (`officer_id`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `frkn_evidence_scans`
DROP TABLE IF EXISTS `frkn_evidence_scans`;
CREATE TABLE `frkn_evidence_scans` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `evidence_id` varchar(32) NOT NULL,
  `type` varchar(32) NOT NULL,
  `container` varchar(16) NOT NULL,
  `street` varchar(120) NOT NULL,
  `created` int(10) unsigned NOT NULL,
  `citizenid` varchar(64) DEFAULT '',
  `victim` varchar(64) DEFAULT '',
  `shooter` varchar(64) DEFAULT '',
  `shot` varchar(64) DEFAULT '',
  `memo` text DEFAULT NULL,
  `source_identifier` varchar(64) DEFAULT '',
  `inserted_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `frkn_pd_cloth`
DROP TABLE IF EXISTS `frkn_pd_cloth`;
CREATE TABLE `frkn_pd_cloth` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `data` longtext NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `frkn_pd_job_grade_perms`
DROP TABLE IF EXISTS `frkn_pd_job_grade_perms`;
CREATE TABLE `frkn_pd_job_grade_perms` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job_grade_id` int(10) unsigned NOT NULL,
  `can_hire` tinyint(1) NOT NULL DEFAULT 0,
  `can_promote` tinyint(1) NOT NULL DEFAULT 0,
  `can_view_balance` tinyint(1) NOT NULL DEFAULT 0,
  `can_withdraw` tinyint(1) NOT NULL DEFAULT 0,
  `can_manage_evidence` tinyint(1) NOT NULL DEFAULT 0,
  `can_read_report` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_grade` (`job_grade_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Data for `frkn_pd_job_grade_perms`
INSERT INTO `frkn_pd_job_grade_perms` (`id`, `job_grade_id`, `can_hire`, `can_promote`, `can_view_balance`, `can_withdraw`, `can_manage_evidence`, `can_read_report`) VALUES
(1, 0, 1, 0, 0, 0, 0, 0),
(2, 1, 1, 0, 1, 1, 1, 1),
(3, 2, 0, 1, 0, 0, 0, 1),
(4, 3, 1, 1, 1, 1, 1, 1),
(5, 4, 1, 1, 1, 1, 1, 1);

-- Structure for `frkn_pd_job_grades`
DROP TABLE IF EXISTS `frkn_pd_job_grades`;
CREATE TABLE `frkn_pd_job_grades` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job_name` varchar(64) NOT NULL,
  `grade` int(10) unsigned NOT NULL,
  `label` varchar(64) NOT NULL,
  `payment` int(11) NOT NULL DEFAULT 0,
  `is_boss` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_job_grade` (`job_name`,`grade`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Data for `frkn_pd_job_grades`
INSERT INTO `frkn_pd_job_grades` (`id`, `job_name`, `grade`, `label`, `payment`, `is_boss`) VALUES
(1, 'police', 0, 'Recruit', 50, 1),
(2, 'police', 1, 'Officer', 75, 0),
(3, 'police', 2, 'Sergeant', 100, 0),
(4, 'police', 3, 'Lieutenant', 125, 0),
(5, 'police', 4, 'Chief', 150, 0);

-- Structure for `frkn_pd_reports`
DROP TABLE IF EXISTS `frkn_pd_reports`;
CREATE TABLE `frkn_pd_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job` varchar(100) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `report` text DEFAULT NULL,
  `anonymous` varchar(50) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `frkn_pd_vaults`
DROP TABLE IF EXISTS `frkn_pd_vaults`;
CREATE TABLE `frkn_pd_vaults` (
  `id` int(11) DEFAULT NULL,
  `station` int(11) DEFAULT NULL,
  `vault` int(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Data for `frkn_pd_vaults`
INSERT INTO `frkn_pd_vaults` (`id`, `station`, `vault`) VALUES
(1, 1, 11012100),
(1, 1, 11012100);

-- Structure for `frkn_pd_vaults_log`
DROP TABLE IF EXISTS `frkn_pd_vaults_log`;
CREATE TABLE `frkn_pd_vaults_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `station` int(11) DEFAULT NULL,
  `action` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `update_date` date DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `frkn_radio_channels`
DROP TABLE IF EXISTS `frkn_radio_channels`;
CREATE TABLE `frkn_radio_channels` (
  `channel_id` varchar(50) NOT NULL,
  `password` varchar(100) DEFAULT '',
  PRIMARY KEY (`channel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Data for `frkn_radio_channels`
INSERT INTO `frkn_radio_channels` (`channel_id`, `password`) VALUES
('1', ''),
('11', '11'),
('15', '15'),
('2', ''),
('22', '22'),
('3', ''),
('4', ''),
('8', '');

-- Structure for `frkn_radio_chat`
DROP TABLE IF EXISTS `frkn_radio_chat`;
CREATE TABLE `frkn_radio_chat` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel_id` varchar(50) NOT NULL,
  `identifier` varchar(100) NOT NULL,
  `message` text NOT NULL,
  `sent_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `avatar` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `channel_id` (`channel_id`),
  CONSTRAINT `frkn_radio_chat_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `frkn_radio_channels` (`channel_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `frkn_radio_members`
DROP TABLE IF EXISTS `frkn_radio_members`;
CREATE TABLE `frkn_radio_members` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel_id` varchar(50) NOT NULL,
  `identifier` varchar(100) NOT NULL,
  `name` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `channel_id` (`channel_id`),
  CONSTRAINT `frkn_radio_members_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `frkn_radio_channels` (`channel_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=72 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Data for `frkn_radio_members`
INSERT INTO `frkn_radio_members` (`id`, `channel_id`, `identifier`, `name`) VALUES
(71, '2', 'char1:cd85b26c02736aeda308a9908feca5aa10c7a9d2', 'FURKAN');

-- Structure for `fuel_stations`
DROP TABLE IF EXISTS `fuel_stations`;
CREATE TABLE `fuel_stations` (
  `location` int(11) NOT NULL,
  `owned` int(11) DEFAULT 0,
  `owner` varchar(50) DEFAULT '0',
  `fuel` int(11) DEFAULT 100000,
  `fuelprice` int(11) DEFAULT 3,
  `balance` int(255) DEFAULT 0,
  `label` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`location`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Data for `fuel_stations`
INSERT INTO `fuel_stations` (`location`, `owned`, `owner`, `fuel`, `fuelprice`, `balance`, `label`) VALUES
(1, 0, '0', 100000, 3, 0, 'Davis Avenue Ron'),
(2, 0, '0', 100000, 3, 0, 'Grove Street LTD'),
(3, 0, '0', 100000, 3, 0, 'Dutch London Xero'),
(4, 0, '0', 99961, 3, 76, 'Little Seoul LTD'),
(5, 1, 'ETK100KY', 99915, 3, 165, 'Strawberry Ave Xero'),
(6, 0, '0', 100000, 3, 0, 'Popular Street Ron'),
(7, 0, '0', 100000, 3, 0, 'Capital Blvd Ron'),
(8, 0, '0', 100000, 3, 0, 'Mirror Park LTD'),
(9, 0, '0', 100000, 3, 0, 'Clinton Ave Globe Oil'),
(10, 0, '0', 99925, 3, 146, 'North Rockford Ron'),
(11, 0, '0', 100000, 3, 0, 'Great Ocean Xero'),
(12, 0, '0', 100000, 3, 0, 'Paleto Blvd Xero'),
(13, 0, '0', 100000, 3, 0, 'Paleto Ron'),
(14, 0, '0', 100000, 3, 0, 'Paleto Globe Oil'),
(15, 0, '0', 100000, 3, 0, 'Grapeseed LTD'),
(16, 0, '0', 100000, 3, 0, 'Sandy Shores Xero'),
(17, 0, '0', 100000, 3, 0, 'Sandy Shores Globe Oil'),
(18, 0, '0', 99965, 3, 68, 'Senora Freeway Xero'),
(19, 0, '0', 100000, 3, 0, 'Harmony Globe Oil'),
(20, 0, '0', 100000, 3, 0, 'Route 68 Globe Oil'),
(21, 0, '0', 100000, 3, 0, 'Route 68 Workshop Globe Oil'),
(22, 0, '0', 100000, 3, 0, 'Route 68 Xero'),
(23, 0, '0', 100000, 3, 0, 'Route 68 Ron'),
(24, 0, '0', 100000, 3, 0, 'Rex''s Diner Globe Oil'),
(25, 0, '0', 100000, 3, 0, 'Palmino Freeway Ron'),
(26, 0, '0', 100000, 3, 0, 'North Rockford LTD'),
(27, 0, '0', 100000, 3, 0, 'Alta Street Globe Oil');

-- Structure for `gangs_metadata`
DROP TABLE IF EXISTS `gangs_metadata`;
CREATE TABLE `gangs_metadata` (
  `gang_name` varchar(50) NOT NULL,
  `level` int(11) NOT NULL DEFAULT 1,
  `xp` int(11) NOT NULL DEFAULT 0,
  `bank_money` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`gang_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Data for `gangs_metadata`
INSERT INTO `gangs_metadata` (`gang_name`, `level`, `xp`, `bank_money`) VALUES
('', 1, 0, 71694),
('ballas', 1, 50, 228864);

-- Structure for `houses`
DROP TABLE IF EXISTS `houses`;
CREATE TABLE `houses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(50) DEFAULT NULL,
  `object_id` int(11) DEFAULT NULL,
  `owner` varchar(120) DEFAULT NULL,
  `owner_name` varchar(80) DEFAULT NULL,
  `renter` varchar(120) DEFAULT NULL,
  `renter_name` varchar(80) DEFAULT NULL,
  `name` longtext DEFAULT '',
  `description` longtext DEFAULT NULL,
  `region` varchar(70) DEFAULT NULL,
  `address` varchar(50) DEFAULT NULL,
  `keys` longtext NOT NULL DEFAULT '[]',
  `permissions` longtext DEFAULT '[]',
  `metadata` longtext NOT NULL DEFAULT '[]',
  `sale` longtext DEFAULT '[]',
  `rental` longtext DEFAULT '[]',
  `last_enter` int(11) DEFAULT NULL,
  `creator` varchar(120) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Data for `houses`
INSERT INTO `houses` (`id`, `type`, `object_id`, `owner`, `owner_name`, `renter`, `renter_name`, `name`, `description`, `region`, `address`, `keys`, `permissions`, `metadata`, `sale`, `rental`, `last_enter`, `creator`) VALUES
(4, 'mlo', NULL, 'ETK100KY', 'Pierre Mkz', NULL, NULL, 'San', '', 'Rockford Hills', 'West Eclipse Boulevard', '["4-8842CTL950"]', '[]', '{"zone":{"area":5184,"minZ":57.8884872436525,"points":[{"x":-847.228271484375,"y":199.7530975341797},{"x":-848.6148071289063,"y":189.52615356445313},{"x":-849.6324462890625,"y":180.4040679931641},{"x":-850.3681030273438,"y":177.165283203125},{"x":-850.7940673828125,"y":166.4863433837891},{"x":-850.4741821289063,"y":162.48992919921876},{"x":-851.7238159179688,"y":151.66543579101566},{"x":-852.4869384765625,"y":136.64915466308598},{"x":-837.48974609375,"y":137.89212036132813},{"x":-821.378662109375,"y":138.57603454589845},{"x":-804.9777221679688,"y":138.95225524902345},{"x":-788.6331787109375,"y":138.61048889160157},{"x":-773.1882934570313,"y":136.35008239746098},{"x":-757.9296264648438,"y":134.17202758789066},{"x":-758.6867065429688,"y":147.7122802734375},{"x":-761.9442138671875,"y":162.12408447265626},{"x":-764.411376953125,"y":169.9064483642578},{"x":-765.4663696289063,"y":179.941650390625},{"x":-766.1890869140625,"y":189.2856597900391},{"x":-768.5701904296875,"y":194.5297088623047},{"x":-772.010498046875,"y":196.0338134765625},{"x":-775.2042846679688,"y":196.489486694336},{"x":-781.8535766601563,"y":196.6128387451172},{"x":-795.9019775390625,"y":195.84361267089845},{"x":-809.4251098632813,"y":196.23269653320313},{"x":-820.5989990234375,"y":196.983642578125},{"x":-832.9583740234375,"y":198.06317138671876}],"maxZ":90.3884872436516},"upgrades":{"furnitureLimit":4,"antiBurglaryDoors":true,"alarm":true,"smartPeephole":true},"storage":{"z":72.26616668701172,"weight":5000,"y":176.9177398681641,"x":-814.3535766601563,"slots":500},"locked":false,"interiorZone":{"area":475,"minZ":65.28758697509784,"points":[{"x":-817.0817260742188,"y":189.1156463623047},{"x":-814.7926025390625,"y":183.19497680664066},{"x":-818.6173095703125,"y":181.6650390625},{"x":-818.3244018554688,"y":180.5251617431641},{"x":-819.0863037109375,"y":180.0494842529297},{"x":-817.3388061523438,"y":175.45994567871098},{"x":-816.6951293945313,"y":175.5102691650391},{"x":-813.9591064453125,"y":169.30267333984376},{"x":-813.7455444335938,"y":168.7229461669922},{"x":-812.3372802734375,"y":165.29638671875},{"x":-811.73974609375,"y":163.67724609375},{"x":-810.9517211914063,"y":163.24057006835938},{"x":-808.4478149414063,"y":165.06985473632813},{"x":-804.9388427734375,"y":166.5851287841797},{"x":-804.3864135742188,"y":165.4729766845703},{"x":-802.5870971679688,"y":166.12240600585938},{"x":-802.3722534179688,"y":167.33456420898438},{"x":-797.3505249023438,"y":169.2357635498047},{"x":-797.2839965820313,"y":169.96737670898438},{"x":-798.7171630859375,"y":174.8843231201172},{"x":-796.60546875,"y":176.5712890625},{"x":-792.255615234375,"y":178.56967163085938},{"x":-792.7657470703125,"y":180.4597625732422},{"x":-793.6989135742188,"y":183.32891845703129},{"x":-796.3823852539063,"y":189.6204071044922},{"x":-796.578857421875,"y":189.8401641845703},{"x":-802.4082641601563,"y":187.67137145996098},{"x":-802.8182983398438,"y":188.72921752929688},{"x":-804.6535034179688,"y":188.2641754150391},{"x":-804.71240234375,"y":186.8296661376953},{"x":-806.0457763671875,"y":186.4417724609375},{"x":-808.30615234375,"y":192.4321441650391}],"maxZ":85.78758697509719},"allowFurnitureOutside":true,"deliveryType":"outside","doors":[{"distance":1.5,"type":"double","locked":true,"right":{"heading":111.00005340576172,"coords":{"z":73.04045104980469,"y":180.50746154785157,"x":-793.3943481445313},"model":-1454760130},"left":{"heading":111.00005340576172,"coords":{"z":73.04045104980469,"y":182.56800842285157,"x":-794.185302734375},"model":1245831483}},{"distance":1.5,"type":"double","locked":true,"right":{"heading":21.00005722045898,"coords":{"z":73.04045104980469,"y":177.22137451171876,"x":-796.565673828125},"model":-1454760130},"left":{"heading":21.00005722045898,"coords":{"z":73.04045104980469,"y":178.0123748779297,"x":-794.505126953125},"model":1245831483}},{"distance":1.5,"type":"single","heading":201.00006103515626,"coords":{"z":72.6240463256836,"y":186.0246124267578,"x":-806.28173828125},"model":-1563640173,"locked":false},{"distance":1.5,"type":"single","heading":264.80224609375,"coords":{"z":70.02470397949219,"y":179.307861328125,"x":-848.934326171875},"model":-1568354151,"locked":true},{"distance":1.5,"type":"double","locked":false,"right":{"heading":291.0000610351563,"coords":{"z":72.82737731933594,"y":177.5108642578125,"x":-816.1068115234375},"model":-1686014385},"left":{"heading":291.0000610351563,"coords":{"z":72.82737731933594,"y":179.09796142578126,"x":-816.7160034179688},"model":159994461}},{"distance":8.5,"type":"slide_gate","heading":90.00019836425781,"coords":{"z":66.03221130371094,"y":155.9619140625,"x":-844.051025390625},"model":-2125423493,"locked":true},{"distance":1.5,"type":"single","heading":270.8851318359375,"coords":{"z":74.50686645507813,"y":186.28439331054688,"x":-814.4754028320313},"model":30769481,"locked":false}],"keysLimit":"50","allowFurnitureInside":true,"delivery":{"z":71.22785949707031,"y":167.4048614501953,"x":-812.54296875,"w":334.9999694824219},"lightState":false,"permissionsLimit":"500","menu":{"z":72.95234680175781,"y":177.85316467285157,"x":-805.0667114257813,"w":222.62188720703129},"wardrobe":{"z":72.15331268310547,"y":181.79974365234376,"x":-807.767822265625},"lastCadastralPeriod":"07:2026"}', '{"defaultActive":true,"price":0,"defaultPrice":0,"active":false}', '{"defaultActive":false,"price":0,"defaultPrice":0,"active":false}', NULL, 'ETK100KY'),
(5, 'mlo', NULL, 'ETK100KY', 'Pierre Mkz', NULL, NULL, 'Frank', 'Frank testing', 'Vinewood Hills', 'Whispymound Drive', '["5-7781FNZ719"]', '[]', '{"zone":{"area":2232,"points":[{"x":25.56678390502929,"y":558.5527954101563},{"x":17.76389694213867,"y":555.00732421875},{"x":10.52248001098632,"y":550.95556640625},{"x":3.78646659851074,"y":546.5211181640625},{"x":-2.72556495666503,"y":542.10498046875},{"x":-9.23300457000732,"y":537.3796997070313},{"x":-18.25122833251953,"y":532.7930297851563},{"x":-28.44674301147461,"y":529.95703125},{"x":-36.59127807617187,"y":528.0884399414063},{"x":-42.15266036987305,"y":525.676025390625},{"x":-43.0806770324707,"y":523.4519653320313},{"x":-43.32772064208984,"y":518.943115234375},{"x":-36.99272155761719,"y":514.3787841796875},{"x":-34.09816360473633,"y":512.6665649414063},{"x":-26.40658187866211,"y":508.968505859375},{"x":-19.46204757690429,"y":506.0084533691406},{"x":-11.80324935913086,"y":503.4688415527344},{"x":-5.24563980102539,"y":503.4156494140625},{"x":-3.64881157875061,"y":500.6276550292969},{"x":3.71230173110961,"y":507.3938598632813},{"x":18.17940521240234,"y":514.187255859375},{"x":23.51732635498047,"y":516.1031494140625},{"x":31.57436943054199,"y":520.0103149414063},{"x":26.37322425842285,"y":535.3015747070313},{"x":30.34248352050781,"y":536.5180053710938},{"x":29.19848251342773,"y":540.1122436523438},{"x":29.7408447265625,"y":542.4677734375}],"minZ":161.3068206787116,"maxZ":183.10682067871088},"upgrades":[],"storage":{"weight":5000,"z":174.63467407226566,"y":524.989501953125,"x":0.40956988930702,"slots":500},"interiorZone":{"area":786,"points":[{"x":19.7711181640625,"y":550.427978515625},{"x":28.7563362121582,"y":545.5299682617188},{"x":24.72027969360351,"y":538.880615234375},{"x":17.13663101196289,"y":542.6168823242188},{"x":14.91331672668457,"y":541.4191284179688},{"x":16.32885360717773,"y":537.4956665039063},{"x":12.3976821899414,"y":535.5489501953125},{"x":16.17832565307617,"y":527.6624145507813},{"x":-0.9805679321289,"y":519.28515625},{"x":-5.90723371505737,"y":512.3631591796875},{"x":-11.4060640335083,"y":514.7759399414063},{"x":-17.08168411254882,"y":512.0847778320313},{"x":-19.68684577941894,"y":517.3473510742188},{"x":-25.41485595703125,"y":528.151123046875},{"x":4.75603914260864,"y":542.0880126953125},{"x":7.287850856781,"y":540.7120971679688},{"x":9.31550025939941,"y":538.7486572265625},{"x":14.80605411529541,"y":542.3734130859375},{"x":15.96952152252197,"y":543.5626220703125}],"minZ":163.60718688964898,"maxZ":178.20718688964866},"keysLimit":"50","allowFurnitureInside":true,"menu":{"z":176.35940551757813,"y":538.6968994140625,"x":8.87413597106933,"w":341.8242492675781},"permissionsLimit":"50","deliveryType":"outside","delivery":{"z":175.02825927734376,"y":541.5433349609375,"x":7.79232883453369,"w":284.99993896484377},"lightState":false,"doors":[{"distance":10.0,"type":"single","heading":268.56634521484377,"coords":{"z":177.64755249023438,"y":545.98193359375,"x":19.30018234252929},"model":2052512905,"locked":true},{"distance":2.5,"type":"single","heading":149.50445556640626,"coords":{"z":176.17764282226566,"y":539.52685546875,"x":7.51835823059082},"model":308207762,"locked":true}],"locked":false,"wardrobe":{"z":170.7650909423828,"y":528.8684692382813,"x":9.98526000976562},"allowFurnitureOutside":true}', '{"price":0,"active":false,"defaultPrice":0,"defaultActive":false}', '{"price":0,"active":false,"defaultPrice":0,"defaultActive":false}', NULL, 'ETK100KY');

-- Structure for `houses_bills`
DROP TABLE IF EXISTS `houses_bills`;
CREATE TABLE `houses_bills` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `house_id` int(11) NOT NULL,
  `period` varchar(50) NOT NULL DEFAULT '',
  `type` varchar(50) DEFAULT NULL,
  `total` float DEFAULT 0,
  `paid` tinyint(1) DEFAULT 0,
  `details` longtext NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_period_per_house_type` (`house_id`,`period`,`type`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Data for `houses_bills`
INSERT INTO `houses_bills` (`id`, `house_id`, `period`, `type`, `total`, `paid`, `details`) VALUES
(5, 4, '07:2026', 'services', 80, 0, '{"electricity":0,"water":0.0,"electricityUsage":0,"rateInfo":{"electricity":0.0115,"internet":80.0,"water":0.5},"internet":80,"waterUsage":0}'),
(6, 5, '07:2026', 'services', 80, 0, '{"electricity":0,"water":0.0,"rateInfo":{"electricity":0.0115,"water":0.5,"internet":80.0},"internet":80,"waterUsage":0,"electricityUsage":0}');

-- Structure for `houses_furniture`
DROP TABLE IF EXISTS `houses_furniture`;
CREATE TABLE `houses_furniture` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `house_id` int(11) NOT NULL,
  `position` longtext DEFAULT NULL,
  `model` varchar(70) DEFAULT NULL,
  `stored` int(11) DEFAULT 0,
  `metadata` longtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Data for `houses_furniture`
INSERT INTO `houses_furniture` (`id`, `house_id`, `position`, `model`, `stored`, `metadata`) VALUES
(13, 5, NULL, 'prop_pooltable_3b', 1, '[]'),
(14, 5, NULL, 'v_club_roc_eq2', 1, '[]'),
(15, 5, NULL, 'v_res_tre_bedsidetable', 1, '{"id":"house_storage-5-15","interactableName":"storage","slots":10,"weight":10000}'),
(16, 5, '{"yaw":-129.99998474121095,"pitch":0.0,"environment":"inside","x":1.78120326995849,"y":542.9180297851563,"roll":-0.0,"z":176.7076873779297}', 'prop_cctv_cam_06a', 0, '[]'),
(17, 5, '{"yaw":150.00006103515626,"pitch":0.0,"environment":"outside","x":7.34927368164062,"y":540.5464477539063,"roll":-0.0,"z":177.95236206054688}', 'prop_cctv_cam_05a', 0, '[]'),
(18, 5, '{"yaw":-70.0,"pitch":0.0,"environment":"outside","x":19.01968383789062,"y":552.4819946289063,"roll":0.0,"z":178.31842041015626}', 'prop_cctv_cam_04c', 0, '[]'),
(19, 4, '{"y":178.712158203125,"environment":"inside","yaw":-90.0,"roll":0.0,"pitch":0.0,"x":-819.0517578125,"z":75.1236343383789}', 'prop_cctv_cam_06a', 0, '[]'),
(20, 4, '{"y":189.7114715576172,"environment":"inside","yaw":-50.00000381469726,"roll":0.0,"pitch":0.0,"x":-817.416748046875,"z":75.11758422851563}', 'prop_cctv_cam_06a', 0, '[]'),
(21, 4, '{"y":156.8519744873047,"environment":"inside","yaw":-70.0,"roll":0.0,"pitch":0.0,"x":-810.2164916992188,"z":74.75546264648438}', 'prop_cctv_cam_06a', 0, '[]'),
(22, 4, NULL, 'prop_cctv_cam_04c', 1, '[]'),
(23, 4, NULL, 'sum_mp_h_yacht_bed_01', 1, '[]'),
(24, 4, '{"pitch":0.0,"roll":0.0,"yaw":-20.00001144409179,"environment":"inside","y":184.0126190185547,"x":-835.067138671875,"z":70.49519348144531}', 'hei_prop_yah_lounger', 0, '[]');

-- Structure for `houses_furniture_list`
DROP TABLE IF EXISTS `houses_furniture_list`;
CREATE TABLE `houses_furniture_list` (
  `model` varchar(80) NOT NULL,
  `label` varchar(80) DEFAULT NULL,
  `price` int(11) DEFAULT 0,
  `deliverySize` int(11) DEFAULT 1,
  `tag` varchar(50) DEFAULT NULL,
  `isOutdoor` int(11) DEFAULT 1,
  `isIndoor` int(11) DEFAULT 1,
  `interactableName` varchar(50) DEFAULT NULL,
  `metadata` longtext DEFAULT NULL,
  PRIMARY KEY (`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Data for `houses_furniture_list`
INSERT INTO `houses_furniture_list` (`model`, `label`, `price`, `deliverySize`, `tag`, `isOutdoor`, `isIndoor`, `interactableName`, `metadata`) VALUES
('apa_mp_h_acc_rugwooll_03', 'Wool Rug', 450, 2, 'decorations', 0, 1, NULL, NULL),
('apa_mp_h_bed_chestdrawer_02', 'Modern Chest of Drawers (Dark)', 7800, 3, 'storage', 0, 1, 'storage', '{"slots":10,"weight":10000}'),
('apa_mp_h_bed_double_09', 'Double Bed (Black Upholstered)', 3800, 1, 'bed', 0, 0, NULL, NULL),
('apa_mp_h_bed_wide_05', 'Wide Bed (Red Frame)', 2800, 3, 'bed', 0, 1, NULL, NULL),
('apa_mp_h_bed_with_table_02', 'Double Bed with Built-in Table', 4500, 3, 'bed', 0, 1, NULL, NULL),
('apa_mp_h_din_table_01', 'Glass Dining Table', 7000, 3, 'table', 1, 1, NULL, NULL),
('apa_mp_h_stn_chairarm_01', 'Modern Armchair (Mustard)', 2000, 2, 'chair', 0, 1, NULL, NULL),
('apa_mp_h_stn_chairstrip_03', 'Armchair (Red Fabric)', 2000, 3, 'chair', 0, 1, NULL, NULL),
('apa_mp_h_stn_chairstrip_08', 'Armchair (Cyan Fabric)', 2000, 3, 'chair', 0, 1, NULL, NULL),
('apa_mp_h_stn_sofacorn_01', 'Corner Sofa (L-Shaped, Cream)', 4950, 3, 'sofa', 1, 1, NULL, NULL),
('apa_mp_h_stn_sofacorn_08', 'Corner Sofa (Beige, Cushioned)', 4400, 3, 'sofa', 0, 1, NULL, NULL),
('apa_mp_h_stn_sofacorn_09', 'Corner Sofa (Dark, Modern)', 5500, 3, 'sofa', 0, 1, NULL, NULL),
('apa_mp_h_str_shelffloorm_02', 'Floor Standing Shelf (Wood & Black)', 8000, 3, 'storage', 0, 1, 'storage', '{"slots":10,"weight":10000}'),
('apa_mp_h_str_sideboardl_11', 'Low Sideboard (Dark Wood)', 10000, 3, 'storage', 0, 1, 'storage', '{"slots":10,"weight":10000}'),
('apa_mp_h_str_sideboardl_13', 'Low Sideboard (White & Gray)', 12000, 3, 'storage', 0, 1, 'storage', '{"slots":10,"weight":10000}'),
('apa_mp_h_str_sideboardl_14', 'Low Sideboard (White & Wood)', 11500, 3, 'storage', 0, 1, 'storage', '{"slots":10,"weight":10000}'),
('apa_mp_h_tab_sidelrg_02', 'Modern Curved Chaise Lounger', 3500, 2, 'table', 1, 1, NULL, NULL),
('bkr_prop_biker_chairstrip_01', 'Leather Club Armchair (Brown)', 650, 3, 'chair', 1, 1, NULL, NULL),
('bkr_prop_biker_garage_locker_01', 'Open Biker Locker', 4200, 3, 'storage', 1, 1, 'wardrobe', NULL),
('bkr_prop_gunlocker_01a', 'Gun Locker Cabinet', 9200, 3, 'storage', 1, 1, 'storage', '{"slots":10,"weight":10000}'),
('ex_mp_h_off_sofa_003', 'Executive Sofa (Charcoal)', 3200, 3, 'sofa', 0, 1, NULL, NULL),
('ex_mp_h_off_sofa_02', 'Executive Sofa (Gray)', 3200, 3, 'sofa', 1, 1, NULL, NULL),
('ex_prop_exec_bed_01', 'Executive Bed (Beige Upholstery)', 1100, 3, 'bed', 0, 1, NULL, NULL),
('gr_prop_gr_rsply_crate04a', 'Green Crate', 7200, 3, 'storage', 1, 1, 'storage', '{"weight":15000,"slots":8}'),
('h4_mp_h_yacht_sofa_01', 'Yacht Sofa (White & Brown)', 7500, 3, 'sofa', 0, 1, NULL, NULL),
('h4_mp_h_yacht_strip_chair_01', 'Yacht Lounge Chair (White)', 1400, 3, 'chair', 1, 1, NULL, NULL),
('h4_prop_h4_glass_disp_01a', 'Glass Display Pedestal', 1000, 2, 'decorations', 1, 1, NULL, NULL),
('hei_heist_bed_double_08', 'Modern Double Bed (Dark Gray)', 3700, 3, 'bed', 0, 1, NULL, NULL),
('hei_heist_din_chair_02', 'Dining Chair (Red Plastic)', 350, 2, 'chair', 1, 1, NULL, NULL),
('hei_heist_stn_sofacorn_05', 'Corner Sofa (Dark Blue)', 3900, 3, 'sofa', 0, 1, NULL, NULL),
('hei_heist_stn_sofacorn_06', 'Corner Sofa (Green Cushions)', 3700, 3, 'sofa', 0, 1, NULL, NULL),
('hei_prop_yah_lounger', 'Rattan Lounger (Dark Frame)', 600, 3, 'chair', 1, 1, NULL, NULL),
('hei_prop_yah_seat_01', 'Rattan Chair (Single, Narrow)', 650, 2, 'chair', 1, 1, NULL, NULL),
('hei_prop_yah_seat_02', 'Rattan Chair (Wide Seat)', 800, 2, 'chair', 1, 1, NULL, NULL),
('hei_prop_yah_seat_03', 'Rattan Chair (Armrests)', 950, 3, 'chair', 1, 1, NULL, NULL),
('hei_prop_yah_table_01', 'Yacht Dining Table (Wooden)', 500, 1, 'table', 1, 1, NULL, NULL),
('hei_prop_yah_table_02', 'Yacht Table (With Cloth)', 550, 2, 'table', 1, 1, NULL, NULL),
('hei_prop_yah_table_03', 'Yacht Table (Blue Legs)', 1000, 3, 'table', 1, 1, NULL, NULL),
('m23_2_prop_m32_weaponcrate_01a', 'Weapon Wooden Crate', 6800, 2, 'storage', 1, 1, 'storage', '{"weight":8000,"slots":7}'),
('p_dinechair_01_s', 'Ornate Wooden Chair (Carved)', 400, 2, 'chair', 1, 1, NULL, NULL),
('p_lestersbed_s', 'Worn Wooden Bed (Blanket)', 1500, 3, 'bed', 0, 1, NULL, NULL),
('p_new_j_counter_03', 'Store Counter', 9000, 2, 'storage', 1, 1, 'storage', '{"slots":10,"weight":10000}'),
('p_v_43_safe_s', 'Vault Safe (Industrial)', 40000, 3, 'storage', 1, 1, 'safe', '{"weight":30000,"slots":12}'),
('prop_airhockey_01', 'Air Hockey Table', 0, 3, 'recreation', 1, 1, NULL, NULL),
('prop_amp_01', 'Guitar Amplifier', 1200, 1, 'electronic', 1, 1, NULL, NULL),
('prop_armchair_01', 'Upholstered Armchair (Brown Fabric)', 650, 2, 'chair', 0, 1, NULL, NULL),
('prop_barbell_01', 'Dumbbell 30kg', 180, 1, 'recreation', 1, 1, NULL, NULL),
('prop_barbell_02', 'Barbell 110kg', 770, 2, 'recreation', 1, 1, NULL, NULL),
('prop_barbell_100kg', 'Barbell 100kg', 700, 2, 'recreation', 1, 1, NULL, NULL),
('prop_barbell_10kg', 'Barbell 10kg', 200, 1, 'recreation', 1, 1, NULL, NULL),
('prop_barbell_20kg', 'Barbell 20kg', 260, 1, 'recreation', 1, 1, NULL, NULL),
('prop_barbell_30kg', 'Barbell 30kg', 330, 1, 'recreation', 1, 1, NULL, NULL),
('prop_barbell_40kg', 'Barbell 40kg', 390, 2, 'recreation', 1, 1, NULL, NULL),
('prop_barbell_50kg', 'Barbell 50kg', 440, 1, 'recreation', 1, 1, NULL, NULL),
('prop_barbell_60kg', 'Barbell 60kg', 510, 2, 'recreation', 1, 1, NULL, NULL),
('prop_barbell_80kg', 'Barbell 80kg', 600, 2, 'recreation', 1, 1, NULL, NULL),
('prop_basketball_net', 'Basketball Hoop', 1850, 3, 'recreation', 1, 1, NULL, NULL),
('prop_bbq_1', 'BBQ', 4800, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bbq_3', 'Brick BBQ', 5500, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_bbq_4', 'BBQ', 900, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bbq_5', 'BBQ', 4500, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_beach_fire', 'Beach Campfire', 300, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_beach_lilo_02', 'Inflatable Pool Mattress', 240, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_beach_parasol_05', 'Beach Parasol (Striped)', 400, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_beach_ring_01', 'Inflatable Swim Ring', 200, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_beach_sandcas_04', 'Sandcastle', 100, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bench_01a', 'Metal Bench (Classic)', 440, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_bench_01b', 'Metal Bench (Classic Blue)', 460, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_bench_01c', 'Metal Bench (Green)', 420, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_bench_02', 'Metal Park Bench', 400, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_bench_03', 'Industrial Metal Bench', 550, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_bench_04', 'Wooden Bench', 850, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bench_06', 'Garden Bench (Slatted)', 600, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_bench_07', 'Minimalist Park Bench', 500, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_bench_08', 'Wooden Bench (Concrete legs)', 950, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_bench_10', 'Bus Stop Bench', 400, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_bench_11', 'Heavy Duty Bench', 500, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_beware_dog_sign', 'Dog Sign', 130, 1, 'decorations', 1, 0, NULL, NULL),
('prop_bin_01a', 'Standard Trash Can', 180, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_02a', 'Trash Can (Blue)', 120, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_03a', 'Black Garbage Bin', 10, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_04a', 'Commercial Trash Bin (Closed)', 300, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_05a', 'Dumpster Bin (Blue)', 280, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_06a', 'Industrial Garbage Bin', 180, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_07a', 'Metal Trash Can (Empty)', 300, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_07b', 'Metal Trash Can (Closed)', 300, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_07c', 'Trash Can (Half-closed)', 300, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_07d', 'Graffiti Trash Can', 200, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_08a', 'Tall Public Bin', 300, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_08open', 'Tall Public Bin (Open)', 300, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_09a', 'Tall Trash Can (With Lid)', 80, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_10a', 'Bin (Dark Blue)', 200, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_10b', 'Bin (Red)', 200, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_11a', 'Street Bin (Yellow)', 160, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_11b', 'Street Bin (Green)', 160, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_12a', 'City Trash Can (Metal Base)', 400, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_delpiero', 'Del Perro Promenade Trash Bin', 500, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_bin_delpiero_b', 'Del Perro Trash Bin (Decorative)', 400, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_cabinet_01', 'White Cabinet (Tall, Drawers)', 7000, 2, 'storage', 1, 1, 'storage', '{"slots":10,"weight":10000}'),
('prop_cabinet_02b', 'Filing Cabinet (3 Drawers, Beige)', 6000, 2, 'storage', 0, 1, 'storage', '{"slots":10,"weight":10000}');
INSERT INTO `houses_furniture_list` (`model`, `label`, `price`, `deliverySize`, `tag`, `isOutdoor`, `isIndoor`, `interactableName`, `metadata`) VALUES
('prop_cctv_cam_04c', 'CCTV Camera (Ceiling Dome)', 12000, 1, 'electronic', 1, 1, NULL, NULL),
('prop_cctv_cam_05a', 'CCTV Camera (Ceiling Tube)', 13000, 1, 'electronic', 1, 1, NULL, NULL),
('prop_cctv_cam_06a', 'CCTV Camera (Wall Box)', 14000, 1, 'electronic', 1, 1, NULL, NULL),
('prop_chair_01a', 'Metal Chair (Blue Frame)', 250, 2, 'chair', 1, 1, NULL, NULL),
('prop_chair_01b', 'Plastic Chair (Worn Red)', 280, 2, 'chair', 1, 1, NULL, NULL),
('prop_chair_02', 'Wicker Chair (Dark)', 380, 2, 'chair', 1, 1, NULL, NULL),
('prop_chair_03', 'Antique Dining Chair (Round Back)', 220, 2, 'chair', 1, 1, NULL, NULL),
('prop_chair_04a', 'Modern Chair (Striped Back)', 740, 2, 'chair', 1, 1, NULL, NULL),
('prop_chair_04b', 'Modern Chair (Flat Back)', 700, 2, 'chair', 1, 1, NULL, NULL),
('prop_chair_05', 'Classic Wicker Chair', 470, 2, 'chair', 1, 1, NULL, NULL),
('prop_chair_06', 'Dining Chair (Dark Red)', 290, 2, 'chair', 1, 1, NULL, NULL),
('prop_chair_07', 'Vintage Wooden Chair', 220, 2, 'chair', 1, 1, NULL, NULL),
('prop_chair_08', 'Plastic Chair (White Legs)', 200, 2, 'chair', 1, 1, NULL, NULL),
('prop_chair_09', 'Rattan Chair (Green Weave)', 300, 2, 'chair', 1, 1, NULL, NULL),
('prop_chair_10', 'Ornate Armchair (Vintage)', 300, 2, 'chair', 1, 1, NULL, NULL),
('prop_chateau_chair_01', 'Antique Chateau Armchair', 290, 2, 'chair', 1, 1, NULL, NULL),
('prop_clown_chair', 'Circus-Style Wooden Chair', 190, 1, 'chair', 1, 1, NULL, NULL),
('prop_copier_01', 'Office Copier (Open Tray)', 700, 3, 'electronic', 0, 1, NULL, NULL),
('prop_couch_01', 'Two-Seat Sofa (Pillows)', 1500, 3, 'sofa', 1, 0, NULL, NULL),
('prop_couch_03', 'Rustic Couch (Beige Cushions)', 1300, 3, 'sofa', 1, 0, NULL, NULL),
('prop_couch_lg_02', 'Modern Couch (Wood Trim)', 2500, 3, 'sofa', 1, 1, NULL, NULL),
('prop_couch_lg_05', 'Fabric Couch (Gray/Brown)', 2700, 3, 'sofa', 1, 0, NULL, NULL),
('prop_couch_lg_06', 'Vintage Couch (Red/Brown)', 1700, 3, 'sofa', 1, 0, NULL, NULL),
('prop_couch_lg_07', 'Couch with Pillows (Gray/Orange)', 2900, 3, 'sofa', 0, 1, NULL, NULL),
('prop_couch_lg_08', 'Modern Couch (Brown/Gray)', 4100, 3, 'sofa', 0, 1, NULL, NULL),
('prop_couch_sm_02', 'Compact Couch (Brown Fabric)', 720, 2, 'sofa', 1, 1, NULL, NULL),
('prop_couch_sm_05', 'Compact Couch (Beige Fabric)', 900, 3, 'sofa', 1, 1, NULL, NULL),
('prop_couch_sm_06', 'Compact Sofa (Gray)', 700, 3, 'sofa', 1, 1, NULL, NULL),
('prop_couch_sm_07', 'Vintage Leather Sofa', 2000, 3, 'sofa', 1, 1, NULL, NULL),
('prop_couch_sm1_07', 'L-Shaped Sofa (Left Side)', 490, 2, 'sofa', 0, 1, NULL, NULL),
('prop_couch_sm2_07', 'L-Shaped Sofa (Right Side)', 490, 2, 'sofa', 0, 1, NULL, NULL),
('prop_cs_keyboard_01', 'Keyboard (Black)', 480, 1, 'electronic', 1, 1, NULL, NULL),
('prop_cs_tv_stand', 'TV Stand with Screen', 2000, 3, 'electronic', 1, 1, NULL, NULL),
('prop_dart_bd_01', 'Dartboard (Wood Backing)', 400, 1, 'recreation', 1, 1, NULL, NULL),
('prop_dart_bd_cab_01', 'Dartboard with Cabinet', 550, 2, 'recreation', 1, 1, NULL, NULL),
('prop_doghouse_01', 'Wooden Doghouse', 750, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_dyn_pc', 'Desktop Computer (Tower)', 2000, 1, 'electronic', 0, 1, NULL, NULL),
('prop_exer_bike_01', 'Exercise Bike (Stationary)', 1600, 3, 'recreation', 1, 1, NULL, NULL),
('prop_fan_01', 'Oscillating Fan (Floor)', 400, 2, 'electronic', 1, 1, NULL, NULL),
('prop_fax_01', 'Office Fax Machine', 400, 1, 'electronic', 0, 1, NULL, NULL),
('prop_fbi3_coffee_table', 'Modern Coffee Table (White Frame)', 1200, 1, 'table', 1, 1, NULL, NULL),
('prop_ff_shelves_01', 'Warehouse Shelving Unit (Metal)', 10000, 3, 'storage', 1, 1, 'storage', '{"slots":10,"weight":10000}'),
('prop_fib_ashtray_01', 'FIB Ashtray (Wall-Mounted)', 25, 1, 'decorations', 1, 1, NULL, NULL),
('prop_flamingo', 'Pink Flamingo (Lawn Ornament)', 400, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_folder_02', 'Magazine Holder (Black)', 40, 1, 'decorations', 1, 1, NULL, NULL),
('prop_foodprocess_01', 'Blender / Food Processor', 170, 1, 'kitchen', 0, 1, NULL, NULL),
('prop_fountain2', 'Stone Fountain (Round)', 8500, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_fridge_03', 'Tall Fridge (Closed)', 8500, 3, 'kitchen', 0, 1, 'storage', '{"weight":8000,"slots":8}'),
('prop_game_clock_01', 'Wall Clock (White Face)', 100, 1, 'decorations', 0, 1, NULL, NULL),
('prop_game_clock_02', 'Wall Clock (Black Face)', 120, 1, 'decorations', 0, 1, NULL, NULL),
('prop_gazebo_01', 'Gazebo Tent (Open Sides)', 3800, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_gazebo_02', 'Gazebo Tent (Side Walls)', 3800, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_gazebo_03', 'Gazebo Tent (No Walls)', 3800, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_gc_chair02', 'Basic Chair (Plastic Seat)', 195, 2, 'chair', 1, 1, NULL, NULL),
('prop_ghettoblast_01', 'Boombox Radio (Retro)', 1500, 1, 'electronic', 1, 1, NULL, NULL),
('prop_gnome1', 'Garden Gnome (Smiling)', 300, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_gnome2', 'Garden Gnome (Lantern)', 300, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_gnome3', 'Garden Gnome (Digging)', 300, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_gravestones_10a', 'Gravestone Statue (Angel Wings)', 6000, 3, 'decorations', 1, 0, NULL, NULL),
('prop_handdry_01', 'Wall Cabinet (White, Small)', 60, 1, 'decorations', 1, 1, NULL, NULL),
('prop_hottub2', 'Wooden Hot Tub (Lid Closed)', 9000, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_inout_tray_02', 'Stacked Document Trays (3x)', 80, 1, 'decorations', 1, 1, NULL, NULL),
('prop_kayak_01b', 'Inflatable Kayak (Yellow)', 400, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_kettle', 'Electric Kettle (Silver)', 140, 1, 'kitchen', 0, 1, NULL, NULL),
('prop_keyboard_01a', 'Keyboard (White)', 480, 1, 'electronic', 1, 1, NULL, NULL),
('prop_kitch_juicer', 'Electric Juicer', 200, 1, 'kitchen', 0, 1, NULL, NULL),
('prop_kitch_pot_fry', 'Frying Pan (Shallow)', 60, 1, 'kitchen', 1, 1, NULL, NULL),
('prop_kitch_pot_lrg2', 'Cooking Pot (Large)', 80, 1, 'kitchen', 1, 1, NULL, NULL),
('prop_knife', 'Kitchen Knife (Used)', 50, 1, 'kitchen', 1, 1, NULL, NULL),
('prop_laptop_01a', 'Laptop (Open, Green Wallpaper)', 3200, 1, 'electronic', 1, 1, 'device', NULL),
('prop_ld_farm_table01', 'Low Farmhouse Table (Dark Wood)', 1500, 3, 'table', 1, 1, NULL, NULL),
('prop_ld_farm_table02', 'Low Farm Table (Dark Wood)', 1400, 2, 'table', 1, 1, NULL, NULL),
('prop_lime_jar', 'Jar of Lime', 35, 1, 'kitchen', 1, 1, NULL, NULL),
('prop_micro_01', 'Microwave (Basic, White)', 850, 1, 'electronic', 0, 1, NULL, NULL),
('prop_micro_02', 'Microwave (Digital, White)', 950, 1, 'electronic', 0, 1, NULL, NULL),
('prop_micro_04', 'Microwave (Wooden Casing)', 800, 1, 'electronic', 0, 1, NULL, NULL),
('prop_monitor_01c', 'Monitor (Windows XP Style)', 2000, 1, 'electronic', 0, 1, 'device', NULL),
('prop_monitor_01d', 'Monitor (Gameshow Display)', 2200, 1, 'electronic', 0, 1, 'device', NULL),
('prop_monitor_li', 'Monitor (Lifeinvader UI)', 2200, 1, 'electronic', 0, 1, 'device', NULL),
('prop_monitor_w_large', 'Wide Office Monitor', 3100, 1, 'electronic', 0, 1, 'device', NULL),
('prop_mouse_02', 'Mouse (Standard, Right)', 90, 1, 'electronic', 0, 1, NULL, NULL),
('prop_muscle_bench_01', 'Workout Bench (Flat)', 600, 2, 'recreation', 1, 1, NULL, NULL),
('prop_muscle_bench_03', 'Workout Bench (Inclined)', 1200, 3, 'recreation', 1, 1, NULL, NULL),
('prop_muscle_bench_05', 'Workout Machine (Arms & Pull)', 1500, 3, 'recreation', 1, 1, NULL, NULL),
('prop_off_chair_01', 'Office Chair (High Back)', 650, 2, 'chair', 1, 1, NULL, NULL),
('prop_off_chair_03', 'Office Chair (Padded, Gray)', 300, 2, 'chair', 1, 1, NULL, NULL),
('prop_off_chair_04', 'Office Chair (Worn Fabric)', 300, 2, 'chair', 1, 1, NULL, NULL),
('prop_off_chair_04b', 'Office Chair (Low Back, Gray)', 350, 2, 'chair', 1, 1, NULL, NULL),
('prop_off_chair_05', 'Office Chair (Mesh Armrests)', 450, 2, 'chair', 1, 1, NULL, NULL),
('prop_office_desk_01', 'Office Desk (Drawers, Gray)', 1850, 2, 'table', 1, 1, NULL, NULL),
('prop_office_phone_tnt', 'Office Telephone (TNT Model)', 200, 1, 'electronic', 0, 1, NULL, NULL),
('prop_old_deck_chair', 'Folding Lounge Chair (Blue)', 160, 2, 'chair', 1, 1, NULL, NULL),
('prop_old_wood_chair', 'Wooden Armchair (Gray, Aged)', 160, 2, 'chair', 1, 1, NULL, NULL),
('prop_old_wood_chair_lod', 'Old Wooden Chair (LOD)', 180, 2, 'chair', 1, 1, NULL, NULL),
('prop_palm_med_01a', 'Palm Tree (Tall, Full)', 3250, 3, 'plant', 1, 0, NULL, NULL),
('prop_palm_med_01b', 'Palm Tree (Tall, Curved)', 3100, 3, 'plant', 1, 0, NULL, NULL),
('prop_palm_med_01c', 'Palm Tree (Medium Height, Wide)', 3000, 3, 'plant', 1, 0, NULL, NULL),
('prop_palm_med_01d', 'Palm Tree (Leaning Right)', 2300, 3, 'plant', 1, 0, NULL, NULL),
('prop_palm_sm_01a', 'Palm Tree (Small Decorative)', 3000, 3, 'plant', 1, 0, NULL, NULL),
('prop_palm_sm_01d', 'Palm Tree (Small, Dense)', 2400, 3, 'plant', 1, 0, NULL, NULL);
INSERT INTO `houses_furniture_list` (`model`, `label`, `price`, `deliverySize`, `tag`, `isOutdoor`, `isIndoor`, `interactableName`, `metadata`) VALUES
('prop_palm_sm_01e', 'Palm Tree (Small, Thin)', 3000, 3, 'plant', 1, 0, NULL, NULL),
('prop_palm_sm_01f', 'Palm Tree (Small, Thick)', 2800, 3, 'plant', 1, 0, NULL, NULL),
('prop_parasol_01', 'Parasol (Light Gray Fabric)', 800, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_parasol_01_b', 'Parasol (Dark Blue Fabric)', 800, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_parasol_01_c', 'Parasol (Brown, Weathered)', 600, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_parasol_01_lod', 'Parasol (Light Gray, Lod Style)', 850, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_parasol_01b_lod', 'Parasol (Dark Base, Lod Style)', 800, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_parasol_02', 'Parasol (White, Tilted)', 800, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_parasol_02_b', 'Parasol (Green Fabric)', 800, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_parasol_02_c', 'Parasol (Dark Blue Fabric)', 800, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_parasol_03', 'Parasol (Blue, Wide)', 600, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_parasol_03_b', 'Parasol (Yellow with Branding)', 600, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_parasol_03_c', 'Parasol (Green with Branding)', 600, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_parasol_04c', 'Parasol (Red/White Sprunk Branding)', 600, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_parasol_04d', 'Parasol (Green/White Sprunk Branding)', 600, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_patio_lounger_2', 'Green Patio Lounger (Foldable)', 800, 3, 'chair', 1, 1, NULL, NULL),
('prop_patio_lounger_3', 'Patio Lounger (White)', 500, 3, 'chair', 1, 1, NULL, NULL),
('prop_patio_lounger1', 'Patio Lounger (Beige Cushion)', 900, 3, 'chair', 1, 1, NULL, NULL),
('prop_patio_lounger1_table', 'Patio Table (Wooden)', 900, 1, 'table', 1, 1, NULL, NULL),
('prop_patio_lounger1b', 'Patio Lounger (No Cushion)', 800, 2, 'chair', 1, 1, NULL, NULL),
('prop_pc_02a', 'Old PC Tower (Beige)', 1600, 1, 'electronic', 0, 1, NULL, NULL),
('prop_picnictable_01', 'Wooden Picnic Table (Standard)', 680, 3, 'table', 1, 1, NULL, NULL),
('prop_picnictable_01_lod', 'Wooden Picnic Table (LOD)', 500, 3, 'table', 1, 1, NULL, NULL),
('prop_picnictable_02', 'Wooden Picnic Table (Red Accents)', 900, 3, 'table', 1, 1, NULL, NULL),
('prop_plant_int_01a', 'Indoor Plant (Short, Round Pot)', 360, 3, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_01b', 'Indoor Plant (Tall, Brown Pot)', 340, 3, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_02a', 'Topiary Ball (Square Pot)', 420, 3, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_02b', 'Topiary Ball (Round Pot)', 460, 3, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_03a', 'Indoor Fern (Stone Pot)', 330, 3, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_03b', 'Indoor Plant (Tall, White Pot)', 285, 3, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_03c', 'Indoor Plant (Pointed, Tall)', 250, 3, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_04a', 'Wide Indoor Plant (Low Pot)', 310, 2, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_04b', 'Indoor Bush (Flat Base)', 340, 2, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_04c', 'Leafy Plant (Round Pot)', 120, 3, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_05a', 'Wicker Planter with Flowers', 590, 3, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_05b', 'Basket Plant (Rectangular)', 400, 3, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_06a', 'Rectangular Planter (Tall Grass)', 550, 3, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_06b', 'Planter with Dense Shrub', 700, 3, 'plant', 1, 1, NULL, NULL),
('prop_plant_int_06c', 'Boxwood Hedge Planter', 500, 3, 'plant', 1, 1, NULL, NULL),
('prop_plant_interior_05a', 'Rectangular Interior Planter', 600, 3, 'plant', 1, 1, NULL, NULL),
('prop_pooltable_02', 'Modern Pool Table (Gray Trim)', 3300, 3, 'recreation', 1, 1, NULL, NULL),
('prop_pooltable_3b', 'Pool Table (Purple)', 3600, 3, 'recreation', 1, 1, NULL, NULL),
('prop_portable_hifi_01', 'Portable Hi-Fi (Boombox)', 330, 1, 'electronic', 1, 1, NULL, NULL),
('prop_pot_03', 'Cooking Pot (Medium Size)', 60, 1, 'kitchen', 1, 1, NULL, NULL),
('prop_pot_plant_01a', 'Indoor Plant (White Pot, Small)', 200, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_01b', 'Indoor Plant (Dark Pot, Spiked Leaves)', 280, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_01c', 'Indoor Plant (Tall, Curved Leaves)', 290, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_01d', 'Fan Palm (Short, Black Pot)', 340, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_01e', 'Fan Palm (Small, Gray Pot)', 300, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_02a', 'Round Pot with Shrub (Stone)', 390, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_02b', 'Planter with Flowers (Round, Tall)', 450, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_02c', 'Planter with Pink Flowers (Round)', 450, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_02d', 'Small Shrub in Round Pot', 350, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_03a', 'Cone Topiary (White Pot)', 550, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_03b', 'Shrub in Terracotta Pot', 480, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_03c', 'Topiary (Pedestal Pot)', 430, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_04a', 'Window Box Planter (Shrubs)', 365, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_04b', 'Ornamental Plant (Yellow Pot)', 620, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_04c', 'Ornamental Palm (Wide Pot)', 500, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_05a', 'Long Thin Plant (White Base)', 220, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_05b', 'Tall Cone Topiary (Gray Pot)', 530, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_05c', 'Rectangular Marble Planter', 850, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_05d', 'Round Stone Planter (Decorative)', 800, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_05d_l1', 'Stone Planter with Flowers', 900, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_6a', 'Hanging Fern Basket', 600, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_bh1', 'Small Bush in Ceramic Pot', 330, 3, 'plant', 1, 1, NULL, NULL),
('prop_pot_plant_inter_03a', 'Indoor Tall Plant (Minimalist)', 360, 3, 'plant', 1, 1, NULL, NULL),
('prop_printer_01', 'Office Printer (Closed Lid)', 450, 1, 'electronic', 0, 1, NULL, NULL),
('prop_proxy_chateau_table', 'Wooden Round Table (Chateau Style)', 800, 3, 'table', 1, 1, NULL, NULL),
('prop_punch_bag_l', 'Punching Bag (Hanging)', 1800, 2, 'recreation', 1, 1, NULL, NULL),
('prop_recyclebin_01a', 'Recycle Bin (Blue)', 300, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_recyclebin_02a', 'Recycle Bin (Red – Mixed Plastic)', 300, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_recyclebin_02b', 'Recycle Bin (Yellow – Cans Only)', 300, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_recyclebin_03_a', 'Classic Bin', 200, 2, 'outdoor', 1, 0, NULL, NULL),
('prop_rub_binbag_01', 'Black Garbage Bag (Full)', 10, 2, 'decorations', 1, 1, NULL, NULL),
('prop_rub_cabinet02', 'Wooden Shelf (Open, Aged)', 6100, 3, 'storage', 1, 1, 'storage', '{"slots":10,"weight":10000}'),
('prop_rub_matress_01', 'Mattress (Old, Dirty)', 750, 2, 'bed', 1, 1, NULL, NULL),
('prop_rub_table_01', 'Old Wooden Table (Worn)', 350, 2, 'table', 1, 1, NULL, NULL),
('prop_rub_table_02', 'Rustic Wooden Table (Damaged)', 310, 3, 'table', 1, 1, NULL, NULL),
('prop_rus_olive', 'Bushy Olive Shrub', 430, 3, 'plant', 1, 1, NULL, NULL),
('prop_rus_olive_l2', 'Olive Tree (Large)', 800, 3, 'plant', 1, 0, NULL, NULL),
('prop_rus_olive_wint', 'Winter Olive Tree', 2200, 3, 'plant', 1, 0, NULL, NULL),
('prop_sapling_break_01', 'Young Sapling Tree (Thin)', 2100, 3, 'plant', 1, 0, NULL, NULL),
('prop_sapling_break_02', 'Tall Sapling (Pointed)', 2400, 2, 'plant', 1, 1, NULL, NULL),
('prop_shower_rack_01', 'Shower Rack (3 Shelves)', 80, 1, 'bathroom', 0, 1, NULL, NULL),
('prop_shrub_rake', 'Garden Rake (Green)', 90, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_sink_02', 'Metal Sink (Wall Mounted)', 300, 1, 'bathroom', 0, 1, NULL, NULL),
('prop_sink_05', 'Bathroom Sink (Rounded)', 280, 1, 'bathroom', 0, 1, NULL, NULL),
('prop_sink_06', 'Bathroom Sink (Tall Pedestal)', 250, 1, 'bathroom', 0, 1, NULL, NULL),
('prop_skid_chair_01', 'Camping Chair (Dark Green)', 430, 2, 'chair', 1, 1, NULL, NULL),
('prop_skid_chair_02', 'Camping Chair (Blue Fabric)', 430, 2, 'chair', 1, 1, NULL, NULL),
('prop_skid_chair_03', 'Camping Chair (Plaid)', 430, 2, 'chair', 1, 1, NULL, NULL),
('prop_skid_tent_01', 'Camping Tent (Folded)', 800, 3, 'outdoor', 1, 0, NULL, NULL),
('prop_soap_disp_01', 'Wall Soap Dispenser', 220, 1, 'bathroom', 0, 1, NULL, NULL),
('prop_sol_chair', 'Classic Armchair (Leather, Worn)', 1650, 3, 'chair', 1, 1, NULL, NULL),
('prop_speaker_01', 'Speaker Panel (Vertical, LED)', 1450, 1, 'electronic', 0, 1, NULL, NULL),
('prop_speaker_02', 'Tall Wooden Speaker (Hi-Fi)', 1200, 1, 'electronic', 0, 1, NULL, NULL),
('prop_speaker_06', 'Large Black Speaker', 2000, 1, 'electronic', 0, 1, NULL, NULL),
('prop_speaker_07', 'Party Speaker (Dual)', 550, 1, 'electronic', 1, 1, NULL, NULL),
('prop_speedball_01', 'Speedball Lamp (Modern)', 1400, 2, 'recreation', 1, 1, NULL, NULL);
INSERT INTO `houses_furniture_list` (`model`, `label`, `price`, `deliverySize`, `tag`, `isOutdoor`, `isIndoor`, `interactableName`, `metadata`) VALUES
('prop_sponge_01', 'Cleaning Sponge (Yellow)', 20, 1, 'decorations', 1, 1, NULL, NULL),
('prop_sports_clock_01', 'Wall Clock (Sport Design)', 130, 1, 'decorations', 0, 1, NULL, NULL),
('prop_stickbfly', 'Butterfly Decoration (Purple)', 90, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_stickhbird', 'Bird Decoration (Small, Brown)', 90, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_stoneshroom1', 'Mushroom Decoration (Purple Glow)', 120, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_stoneshroom2', 'Mushroom Decoration (Blue Glow)', 120, 1, 'outdoor', 1, 0, NULL, NULL),
('prop_stool_01', 'Bar Stool (Metal)', 280, 1, 'chair', 1, 1, NULL, NULL),
('prop_suitcase_01', 'Suitcase (Black)', 5500, 1, 'storage', 1, 1, 'storage', '{"weight":10000,"slots":5}'),
('prop_suitcase_01b', 'Suitcase (Brown)', 5500, 1, 'storage', 1, 1, 'storage', '{"weight":10000,"slots":5}'),
('prop_suitcase_01c', 'Suitcase (Red)', 5500, 1, 'storage', 1, 1, 'storage', '{"weight":10000,"slots":5}'),
('prop_suitcase_01d', 'Suitcase (Dark Gray)', 5500, 1, 'storage', 1, 1, 'storage', '{"weight":10000,"slots":5}'),
('prop_suitcase_02', 'Double Suitcase (Stacked)', 3500, 1, 'storage', 1, 1, 'storage', '{"weight":10000,"slots":5}'),
('prop_suitcase_03', 'Double Suitcase (Red + Black)', 3500, 1, 'storage', 1, 1, 'storage', '{"weight":10000,"slots":3}'),
('prop_suitcase_03b', 'Double Suitcase (Black)', 3500, 1, 'storage', 1, 1, 'storage', '{"weight":10000,"slots":3}'),
('prop_t_sofa_02', 'Double Bed (White Frame)', 2100, 3, 'bed', 1, 1, NULL, NULL),
('prop_table_01', 'Coffee Table (Wooden)', 3400, 3, 'table', 1, 1, NULL, NULL),
('prop_table_01_chr_a', 'Wooden Chair (With Armrests)', 350, 2, 'chair', 1, 1, NULL, NULL),
('prop_table_01_chr_b', 'Wooden Chair (No Armrests)', 320, 2, 'chair', 1, 1, NULL, NULL),
('prop_table_02', 'Round Table (Wood + Iron Base)', 1200, 3, 'table', 1, 1, NULL, NULL),
('prop_table_02_chr', 'Wooden Chair (Dark Wood)', 300, 2, 'chair', 1, 1, NULL, NULL),
('prop_table_03', 'Plastic Table (White)', 950, 3, 'table', 1, 1, NULL, NULL),
('prop_table_03_chr', 'Plastic Chair (Armrest, White)', 220, 2, 'chair', 1, 1, NULL, NULL),
('prop_table_03b', 'Plastic Table (Square, White)', 600, 3, 'table', 1, 1, NULL, NULL),
('prop_table_03b_chr', 'Plastic Chair (Wide Back, White)', 220, 2, 'chair', 1, 1, NULL, NULL),
('prop_table_03b_cs', 'Plastic Table (Square, White)', 600, 3, 'table', 1, 1, NULL, NULL),
('prop_table_04', 'Dining Bench (Dark Frame)', 3000, 3, 'table', 1, 1, NULL, NULL),
('prop_table_04_chr', 'Dining Chair (Metal Frame)', 380, 2, 'chair', 1, 1, NULL, NULL),
('prop_table_05', 'Round Dining Table (Wicker)', 720, 3, 'table', 1, 1, NULL, NULL),
('prop_table_05_chr', 'Wicker Chair (Dining)', 330, 2, 'chair', 1, 1, NULL, NULL),
('prop_table_06', 'Modern Dining Table (Metal Legs)', 1400, 3, 'table', 1, 1, NULL, NULL),
('prop_table_06_chr', 'Chair (Thin Metal Frame)', 650, 2, 'chair', 1, 1, NULL, NULL),
('prop_table_07', 'Round Table with Pole', 620, 2, 'table', 1, 1, NULL, NULL),
('prop_table_08', 'Old Wooden Table with Cover', 500, 3, 'table', 1, 1, NULL, NULL),
('prop_table_para_comb_01', 'Parasol Table (Wood, Red Canopy)', 1200, 3, 'table', 1, 1, NULL, NULL),
('prop_table_para_comb_03', 'Parasol Table (Blue Canopy)', 1200, 3, 'table', 1, 1, NULL, NULL),
('prop_table_para_comb_04', 'Parasol Table (Gray Fabric)', 1300, 3, 'table', 1, 1, NULL, NULL),
('prop_table_tennis', 'Table Tennis Table (Foldable)', 2100, 3, 'table', 1, 1, NULL, NULL),
('prop_tablesmall_01', 'Low Wooden Table (Small)', 2000, 2, 'table', 1, 1, NULL, NULL),
('prop_toaster_01', 'Toaster (Stainless)', 400, 1, 'kitchen', 0, 1, NULL, NULL),
('prop_toaster_02', 'Toaster (White)', 330, 1, 'kitchen', 0, 1, NULL, NULL),
('prop_toilet_01', 'Toilet (Standard)', 350, 1, 'bathroom', 0, 1, NULL, NULL),
('prop_toilet_02', 'Toilet (Modern)', 500, 1, 'bathroom', 0, 1, NULL, NULL),
('prop_toilet_brush_01', 'Toilet Brush (Holder)', 25, 1, 'bathroom', 0, 1, NULL, NULL),
('prop_toilet_soap_02', 'Toilet Soap (With Dish)', 30, 1, 'bathroom', 0, 1, NULL, NULL),
('prop_toilet_soap_04', 'Soap Dispenser (Pink)', 50, 1, 'bathroom', 0, 1, NULL, NULL),
('prop_toothpaste_01', 'Toothpaste Tube', 20, 1, 'bathroom', 0, 1, NULL, NULL),
('prop_towel_01', 'Towel Stack (White)', 40, 1, 'bathroom', 0, 1, NULL, NULL),
('prop_trev_tv_01', 'CRT TV (Wooden Frame)', 140, 1, 'electronic', 1, 1, NULL, NULL),
('prop_tv_01', 'TV (Black Screen)', 680, 1, 'electronic', 1, 1, NULL, NULL),
('prop_tv_02', 'TV', 550, 1, 'electronic', 1, 1, NULL, NULL),
('prop_tv_03', 'CRT TV (Dark Gray)', 150, 1, 'electronic', 1, 1, NULL, NULL),
('prop_tv_04', 'CRT TV (Retro, Gray)', 120, 1, 'electronic', 1, 1, NULL, NULL),
('prop_tv_05', 'Vintage TV (Antenna)', 700, 1, 'electronic', 1, 1, NULL, NULL),
('prop_tv_06', 'CRT TV (Angled Edges)', 200, 1, 'electronic', 1, 1, NULL, NULL),
('prop_tv_07', 'CRT TV (Beveled Frame)', 180, 1, 'electronic', 1, 1, NULL, NULL),
('prop_tv_cabinet_03', 'TV Cabinet (Open Shelves)', 6900, 2, 'storage', 1, 1, 'storage', '{"weight":10000,"slots":10}'),
('prop_tv_cabinet_04', 'TV Cabinet (Bookshelf Style)', 6400, 2, 'storage', 1, 1, 'storage', '{"weight":10000,"slots":10}'),
('prop_tv_cabinet_05', 'TV Cabinet (Curved Front)', 6200, 2, 'storage', 1, 1, 'storage', '{"slots":10,"weight":10000}'),
('prop_tv_flat_01', 'Flat TV (Modern, On Stand)', 3700, 2, 'electronic', 0, 1, NULL, NULL),
('prop_tv_flat_02', 'Flat TV (Modern, Wide)', 3000, 1, 'electronic', 0, 1, NULL, NULL),
('prop_tv_flat_02b', 'Flat TV (Wide, Black Frame)', 1300, 1, 'electronic', 0, 1, NULL, NULL),
('prop_tv_flat_03', 'Flat TV (Modern Stand)', 1500, 1, 'electronic', 0, 1, NULL, NULL),
('prop_tv_flat_03b', 'Flat TV (Stand, No Logo)', 4000, 1, 'electronic', 0, 1, NULL, NULL),
('prop_tv_flat_michael', 'Flat TV (Michael''s Room)', 3800, 1, 'electronic', 0, 1, NULL, NULL),
('prop_tv_stand_01', 'TV Stand (Trust Poster)', 2200, 3, 'electronic', 1, 1, NULL, NULL),
('prop_tv_test', 'Test TV (Boxy, Placeholder)', 900, 1, 'electronic', 1, 1, NULL, NULL),
('prop_ven_market_table1', 'Market Table (Foldable)', 1300, 2, 'table', 1, 1, NULL, NULL),
('prop_w_fountain_01', 'Public Sink (Stainless, Wide)', 180, 1, 'bathroom', 0, 1, NULL, NULL),
('prop_waiting_seat_01', 'Waiting Seat (Brown Leather)', 500, 2, 'chair', 1, 1, NULL, NULL),
('prop_wall_light_06a', 'Ceiling Light (Glass Dome)', 500, 1, 'light', 1, 1, NULL, NULL),
('prop_washer_02', 'Washing Machine (Modern)', 2400, 2, 'electronic', 0, 1, NULL, NULL),
('prop_washer_03', 'Washing Machine (Vintage)', 2000, 2, 'electronic', 0, 1, NULL, NULL),
('prop_watercooler', 'Water Cooler (Plastic Jug)', 1100, 1, 'kitchen', 1, 1, NULL, NULL),
('prop_weight_bench_02', 'Weight Bench (Barbell)', 1900, 3, 'recreation', 1, 1, NULL, NULL),
('prop_weight_rack_02', 'Weight Rack (Dumbbells)', 2400, 3, 'recreation', 1, 1, NULL, NULL),
('prop_weight_squat', 'Squat Rack (Weights)', 1100, 3, 'recreation', 1, 1, NULL, NULL),
('prop_yacht_table_01', 'Yacht Table (Dark Wicker)', 640, 1, 'table', 1, 1, NULL, NULL),
('prop_yacht_table_02', 'Yacht Table (Gray Wicker)', 550, 2, 'table', 1, 1, NULL, NULL),
('prop_yacht_table_03', 'Yacht Table (Black Wicker)', 1000, 3, 'table', 1, 1, NULL, NULL),
('prop_yaught_chair_01', 'Yacht Chair (Single, Black)', 850, 2, 'chair', 1, 1, NULL, NULL),
('prop_yaught_sofa_01', 'Yacht Sofa (2-Seat, Black)', 1900, 3, 'sofa', 1, 1, NULL, NULL),
('sf_mp_h_yacht_armchair_03', 'Yacht Armchair (White)', 1100, 2, 'chair', 1, 1, NULL, NULL),
('sf_prop_sf_bed_dog_01a', 'Dog Bed (Grey)', 340, 2, 'decorations', 0, 1, NULL, NULL),
('sf_prop_sf_bed_dog_01b', 'Dog Bed (Brown)', 330, 2, 'decorations', 0, 1, NULL, NULL),
('sum_mp_h_yacht_bed_01', 'Yacht Bed (Single, Brown)', 3600, 3, 'bed', 0, 1, NULL, NULL),
('sum_mp_h_yacht_bed_02', 'Yacht Bed (Double, Gray)', 4000, 3, 'bed', 0, 1, NULL, NULL),
('v_club_officechair', 'Office Chair (Boss Style)', 950, 2, 'chair', 1, 1, NULL, NULL),
('v_club_roc_eq1', 'Club Speaker (Wall Mount 1)', 300, 1, 'electronic', 1, 1, NULL, NULL),
('v_club_roc_eq2', 'Club Speaker (Wall Mount 2)', 450, 1, 'electronic', 1, 1, NULL, NULL),
('v_club_vu_bear', 'Teddy Bear (Pink, Plush)', 110, 1, 'recreation', 1, 1, NULL, NULL),
('v_corp_bk_chair3', 'Desk Chair (Gray, No Arms)', 200, 2, 'chair', 1, 1, NULL, NULL),
('v_corp_cd_chair', 'Desk Chair (Red)', 240, 1, 'chair', 1, 1, NULL, NULL),
('v_corp_offchair', 'Office Chair (Slim Back)', 800, 2, 'chair', 1, 1, NULL, NULL),
('v_ilev_liconftable_sml', 'Coffee Table (Modern, Black)', 8000, 3, 'table', 1, 1, NULL, NULL),
('v_ilev_m_sofa', 'L-Shaped Sofa (Modern)', 4500, 3, 'sofa', 1, 1, NULL, NULL),
('v_ind_rc_lowtable', 'Wooden Coffee Table (Low)', 800, 1, 'table', 1, 1, NULL, NULL),
('v_med_fabricchair1', 'Fabric Armchair (Green)', 590, 2, 'chair', 1, 1, NULL, NULL),
('v_res_cakedome', 'Decorative Cake Dome (Glass)', 75, 1, 'kitchen', 1, 1, NULL, NULL),
('v_res_d_bed', 'Iron Bed (Red Floral)', 1300, 3, 'bed', 0, 1, NULL, NULL),
('v_res_fh_bedsideclock', 'Alarm Clock (Black/White)', 100, 1, 'decorations', 0, 1, NULL, NULL);
INSERT INTO `houses_furniture_list` (`model`, `label`, `price`, `deliverySize`, `tag`, `isOutdoor`, `isIndoor`, `interactableName`, `metadata`) VALUES
('v_res_foodjara', 'Food Jar (Chilli)', 45, 1, 'kitchen', 1, 1, NULL, NULL),
('v_res_foodjarb', 'Food Jar (Rice)', 40, 1, 'kitchen', 1, 1, NULL, NULL),
('v_res_fridgemodsml', 'Fridge (Double Door, Water Dispenser)', 9900, 3, 'kitchen', 0, 1, 'storage', '{"weight":8000,"slots":8}'),
('v_res_m_armoire', 'Armoire (Classic, Closed)', 7000, 3, 'storage', 1, 1, 'wardrobe', NULL),
('v_res_m_armoirmove', 'Armoire (Single, Moveable)', 6200, 3, 'storage', 1, 1, 'wardrobe', NULL),
('v_res_m_l_chair1', 'Armchair (Vintage, Orange)', 640, 2, 'chair', 1, 1, NULL, NULL),
('v_res_mbath', 'Bathtub (Modern Oval)', 600, 3, 'bathroom', 0, 1, NULL, NULL),
('v_res_mbbed', 'Double Bed (Red Blanket)', 1800, 3, 'bed', 0, 1, NULL, NULL),
('v_res_mbdresser', 'Dresser (Ornate Wood)', 3100, 3, 'table', 1, 1, NULL, NULL),
('v_res_mbsink', 'Bathroom Sink (Wall Mount)', 400, 1, 'bathroom', 0, 1, NULL, NULL),
('v_res_mconsolemod', 'TV Console (Ornate Wood)', 5500, 3, 'storage', 1, 1, 'storage', '{"weight":20000,"slots":15}'),
('v_res_mdbed', 'Double Bed (Red Blanket)', 2300, 3, 'bed', 0, 1, NULL, NULL),
('v_res_mflowers', 'Flowers in Vase (White & Pink)', 520, 2, 'plant', 1, 1, NULL, NULL),
('v_res_mknifeblock', 'Knife Block (Wood)', 110, 1, 'kitchen', 1, 1, NULL, NULL),
('v_res_mmug', 'Mug (Stoneware)', 20, 1, 'kitchen', 1, 1, NULL, NULL),
('v_res_monitorsquare', 'Monitor (Square)', 2000, 1, 'electronic', 0, 1, 'device', NULL),
('v_res_monitorwidelarge', 'Monitor (Wide)', 3000, 1, 'electronic', 0, 1, 'device', NULL),
('v_res_mousemat', 'Mouse with Mat', 110, 1, 'electronic', 0, 1, NULL, NULL),
('v_res_mplatesml', 'Dinner Plate (Blue Border)', 20, 1, 'kitchen', 1, 1, NULL, NULL),
('v_res_msonbed', 'Single Bed (Dark, Unmade)', 1700, 3, 'bed', 0, 1, NULL, NULL),
('v_res_paperfolders', 'Stack of Folders', 45, 1, 'decorations', 1, 1, NULL, NULL),
('v_res_pcheadset', 'PC Headset (Lying)', 190, 1, 'electronic', 0, 1, NULL, NULL),
('v_res_pcspeaker', 'Tower Speaker (Standing)', 300, 1, 'electronic', 0, 1, NULL, NULL),
('v_res_pctower', 'PC Tower (Black)', 2000, 1, 'electronic', 0, 1, NULL, NULL),
('v_res_pestle', 'Mortar and Pestle (Stone)', 50, 1, 'kitchen', 1, 1, NULL, NULL),
('v_res_printer', 'Printer (Multifunction)', 550, 1, 'electronic', 0, 1, NULL, NULL),
('v_res_r_perfume', 'Perfume Bottle (Green)', 300, 1, 'decorations', 1, 1, NULL, NULL),
('v_res_tre_bed1', 'Double Bed (White Frame)', 2500, 3, 'bed', 0, 1, NULL, NULL),
('v_res_tre_bed1_messy', 'Double Bed (Messy Blanket)', 2200, 3, 'bed', 0, 1, NULL, NULL),
('v_res_tre_bedsidetable', 'Nightstand (Single Drawer)', 5500, 1, 'storage', 1, 1, 'storage', '{"slots":10,"weight":10000}'),
('v_res_tre_chair', 'Chair (White Wooden)', 400, 1, 'chair', 1, 1, NULL, NULL),
('v_res_tre_fridge', 'Fridge (Retro)', 7800, 2, 'kitchen', 0, 1, 'storage', '{"weight":8000,"slots":8}'),
('v_res_tre_lightfan', 'Ceiling Fan (Wooden)', 800, 2, 'light', 1, 1, NULL, NULL),
('v_res_tt_bed', 'Bed (Simple, Plaid)', 1200, 3, 'bed', 0, 1, NULL, NULL),
('v_res_tt_bowlpile02', 'Stack of Plates', 40, 1, 'kitchen', 1, 1, NULL, NULL),
('v_res_vacuum', 'Vacuum Cleaner (Upright)', 1250, 1, 'electronic', 0, 1, NULL, NULL),
('v_ret_gc_chair03', 'Office Chair (Black Leather)', 800, 2, 'chair', 1, 1, NULL, NULL),
('v_ret_gc_shred', 'Shredder (Office)', 480, 1, 'electronic', 0, 1, NULL, NULL),
('v_ret_mirror', 'Wall Mirror (Gold Frame)', 300, 1, 'decorations', 0, 1, NULL, NULL),
('v_ret_ps_flowers_01', 'Flowers in Vase (Yellow)', 550, 2, 'plant', 1, 1, NULL, NULL),
('v_ret_ps_flowers_02', 'Flowers in Vase (Pink)', 500, 2, 'plant', 1, 1, NULL, NULL),
('v_ret_ta_paproll', 'Toilet Paper Roll (Dark Texture)', 15, 1, 'decorations', 1, 1, NULL, NULL),
('xm_lab_chairarm_03', 'Office Chair (Wood Frame)', 550, 2, 'chair', 1, 1, NULL, NULL),
('xm_prop_lab_desk_02', 'Modern Desk (Black&Wooden)', 3600, 3, 'table', 1, 1, NULL, NULL),
('zprop_bin_01a_old', 'Classic Bin (Mesh)', 280, 2, 'outdoor', 1, 0, NULL, NULL);

-- Structure for `inventory_items`
DROP TABLE IF EXISTS `inventory_items`;
CREATE TABLE `inventory_items` (
  `uniqueId` int(11) NOT NULL AUTO_INCREMENT,
  `inventoryId` varchar(100) DEFAULT NULL,
  `data` longtext NOT NULL,
  `lastModified` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`uniqueId`),
  KEY `idx_inventoryId` (`inventoryId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `items`
DROP TABLE IF EXISTS `items`;
CREATE TABLE `items` (
  `name` varchar(100) NOT NULL,
  `category` varchar(100) DEFAULT NULL,
  `data` longtext NOT NULL,
  PRIMARY KEY (`name`),
  KEY `idx_category` (`category`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `jeff_presets`
DROP TABLE IF EXISTS `jeff_presets`;
CREATE TABLE `jeff_presets` (
  `citizenid` varchar(50) NOT NULL,
  `vehicle_name` varchar(100) NOT NULL,
  `preset_name` varchar(100) NOT NULL,
  `props` longtext NOT NULL,
  PRIMARY KEY (`citizenid`,`vehicle_name`,`preset_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `jeffresources`
DROP TABLE IF EXISTS `jeffresources`;
CREATE TABLE `jeffresources` (
  `conheceu` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `koja_crafting`
DROP TABLE IF EXISTS `koja_crafting`;
CREATE TABLE `koja_crafting` (
  `#` int(11) NOT NULL AUTO_INCREMENT,
  `playerid` varchar(50) DEFAULT NULL,
  `currentXP` int(11) DEFAULT NULL,
  PRIMARY KEY (`#`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Data for `koja_crafting`
INSERT INTO `koja_crafting` (`#`, `playerid`, `currentXP`) VALUES
(5, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 0);

-- Structure for `kq_emergency_presets`
DROP TABLE IF EXISTS `kq_emergency_presets`;
CREATE TABLE `kq_emergency_presets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '0',
  `description` text NOT NULL,
  `model` varchar(50) NOT NULL DEFAULT '0',
  `user` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`user`)),
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`data`)),
  `public` tinyint(4) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `kq_emergency_vehicles`
DROP TABLE IF EXISTS `kq_emergency_vehicles`;
CREATE TABLE `kq_emergency_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vehicle` varchar(50) NOT NULL DEFAULT '0',
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `vehicle` (`vehicle`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci ROW_FORMAT=DYNAMIC;

-- Structure for `kq_shellbuilder`
DROP TABLE IF EXISTS `kq_shellbuilder`;
CREATE TABLE `kq_shellbuilder` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` text NOT NULL,
  `user` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`user`)),
  `coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`coords`)),
  `settings` longtext DEFAULT NULL,
  `builder_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`builder_data`)),
  `spawn_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`spawn_data`)),
  `thumbnail` longtext DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `l2s_hotels`
DROP TABLE IF EXISTS `l2s_hotels`;
CREATE TABLE `l2s_hotels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hotel` text DEFAULT NULL,
  `name` text DEFAULT NULL,
  `citizenid` varchar(50) DEFAULT NULL,
  `price` int(11) NOT NULL DEFAULT 0,
  `room` int(11) DEFAULT NULL,
  `expire` datetime DEFAULT current_timestamp(),
  `cardnumber` text DEFAULT NULL,
  `stashType` int(11) DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=58 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `lapraces`
DROP TABLE IF EXISTS `lapraces`;
CREATE TABLE `lapraces` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `checkpoints` text DEFAULT NULL,
  `records` text DEFAULT NULL,
  `creator` varchar(50) DEFAULT NULL,
  `distance` int(11) DEFAULT NULL,
  `raceid` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `raceid` (`raceid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `management_outfits`
DROP TABLE IF EXISTS `management_outfits`;
CREATE TABLE `management_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `type` varchar(50) NOT NULL,
  `minrank` int(11) NOT NULL DEFAULT 0,
  `name` varchar(50) NOT NULL DEFAULT 'Cool Outfit',
  `gender` varchar(50) NOT NULL DEFAULT 'male',
  `model` varchar(50) DEFAULT NULL,
  `props` text DEFAULT NULL,
  `components` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mapeditor_audit`
DROP TABLE IF EXISTS `mapeditor_audit`;
CREATE TABLE `mapeditor_audit` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `license` varchar(100) NOT NULL,
  `player_name` varchar(100) NOT NULL,
  `action` varchar(50) NOT NULL,
  `object_id` int(10) unsigned DEFAULT NULL,
  `detail` longtext DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_object` (`object_id`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `mapeditor_categories`
DROP TABLE IF EXISTS `mapeditor_categories`;
CREATE TABLE `mapeditor_categories` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT 'New Category',
  `parent_id` int(10) unsigned DEFAULT NULL,
  `slot_limit` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `mapeditor_deleted_objects`
DROP TABLE IF EXISTS `mapeditor_deleted_objects`;
CREATE TABLE `mapeditor_deleted_objects` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `prop_hash` varchar(255) NOT NULL,
  `coords` longtext NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `mapeditor_exports`
DROP TABLE IF EXISTS `mapeditor_exports`;
CREATE TABLE `mapeditor_exports` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `mapeditor_object_categories`
DROP TABLE IF EXISTS `mapeditor_object_categories`;
CREATE TABLE `mapeditor_object_categories` (
  `object_id` int(10) unsigned NOT NULL,
  `category_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`object_id`),
  KEY `idx_category` (`category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `mapeditor_objects`
DROP TABLE IF EXISTS `mapeditor_objects`;
CREATE TABLE `mapeditor_objects` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `prop_hash` varchar(255) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `coords` longtext NOT NULL,
  `rotation` longtext NOT NULL,
  `properties` longtext DEFAULT NULL,
  `deleted` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_deleted` (`deleted`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `npcvoice_activities`
DROP TABLE IF EXISTS `npcvoice_activities`;
CREATE TABLE `npcvoice_activities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` enum('ITEM','INFO','EVENT') NOT NULL,
  `name` varchar(100) NOT NULL,
  `probability` decimal(5,4) DEFAULT 1.0000,
  `duration_days` int(11) DEFAULT NULL,
  `budget` int(11) DEFAULT NULL,
  `item_id` varchar(100) DEFAULT NULL,
  `item_count` int(11) DEFAULT 1,
  `info_text` text DEFAULT NULL,
  `event_name` varchar(100) DEFAULT NULL,
  `event_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`event_data`)),
  `event_side` enum('client','server') DEFAULT 'client',
  `instructions` text DEFAULT NULL,
  `active` tinyint(1) DEFAULT 1,
  `executions` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `expires_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_active` (`active`),
  KEY `idx_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `npcvoice_activity_logs`
DROP TABLE IF EXISTS `npcvoice_activity_logs`;
CREATE TABLE `npcvoice_activity_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `activity_id` int(11) DEFAULT NULL,
  `player_id` varchar(50) DEFAULT NULL,
  `executed_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_activity` (`activity_id`),
  KEY `idx_player` (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `npcvoice_conversation_logs`
DROP TABLE IF EXISTS `npcvoice_conversation_logs`;
CREATE TABLE `npcvoice_conversation_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` varchar(50) DEFAULT NULL,
  `npc_name` varchar(100) DEFAULT NULL,
  `location_x` float DEFAULT NULL,
  `location_y` float DEFAULT NULL,
  `location_z` float DEFAULT NULL,
  `messages` mediumtext DEFAULT NULL,
  `cost_stt` decimal(10,6) DEFAULT NULL,
  `cost_llm` decimal(10,6) DEFAULT NULL,
  `cost_tts` decimal(10,6) DEFAULT NULL,
  `cost_total` decimal(10,6) DEFAULT NULL,
  `duration_ms` int(11) DEFAULT NULL,
  `turns` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_player` (`player_id`),
  KEY `idx_created` (`created_at`),
  KEY `idx_cost` (`cost_total`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `npcvoice_player_history`
DROP TABLE IF EXISTS `npcvoice_player_history`;
CREATE TABLE `npcvoice_player_history` (
  `player_id` varchar(50) NOT NULL,
  `action_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`action_data`)),
  `last_reset` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `npwd_calls`
DROP TABLE IF EXISTS `npwd_calls`;
CREATE TABLE `npwd_calls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci DEFAULT NULL,
  `transmitter` varchar(255) NOT NULL,
  `receiver` varchar(255) NOT NULL,
  `is_accepted` tinyint(4) DEFAULT 0,
  `isAnonymous` tinyint(4) NOT NULL DEFAULT 0,
  `start` varchar(255) DEFAULT NULL,
  `end` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `npwd_darkchat_channel_members`
DROP TABLE IF EXISTS `npwd_darkchat_channel_members`;
CREATE TABLE `npwd_darkchat_channel_members` (
  `channel_id` int(11) NOT NULL,
  `user_identifier` varchar(255) NOT NULL,
  `is_owner` tinyint(4) NOT NULL DEFAULT 0,
  KEY `npwd_darkchat_channel_members_npwd_darkchat_channels_id_fk` (`channel_id`) USING BTREE,
  CONSTRAINT `npwd_darkchat_channel_members_npwd_darkchat_channels_id_fk` FOREIGN KEY (`channel_id`) REFERENCES `npwd_darkchat_channels` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `npwd_darkchat_channels`
DROP TABLE IF EXISTS `npwd_darkchat_channels`;
CREATE TABLE `npwd_darkchat_channels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel_identifier` varchar(191) NOT NULL,
  `label` varchar(255) DEFAULT '',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `darkchat_channels_channel_identifier_uindex` (`channel_identifier`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `npwd_darkchat_messages`
DROP TABLE IF EXISTS `npwd_darkchat_messages`;
CREATE TABLE `npwd_darkchat_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel_id` int(11) NOT NULL,
  `message` varchar(255) NOT NULL,
  `user_identifier` varchar(255) NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_image` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `darkchat_messages_darkchat_channels_id_fk` (`channel_id`) USING BTREE,
  CONSTRAINT `darkchat_messages_darkchat_channels_id_fk` FOREIGN KEY (`channel_id`) REFERENCES `npwd_darkchat_channels` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `npwd_marketplace_listings`
DROP TABLE IF EXISTS `npwd_marketplace_listings`;
CREATE TABLE `npwd_marketplace_listings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci DEFAULT NULL,
  `username` varchar(255) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `number` varchar(255) NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `description` varchar(255) NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `reported` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `npwd_match_profiles`
DROP TABLE IF EXISTS `npwd_match_profiles`;
CREATE TABLE `npwd_match_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci NOT NULL,
  `name` varchar(90) NOT NULL,
  `image` varchar(255) NOT NULL,
  `bio` varchar(512) DEFAULT NULL,
  `location` varchar(45) DEFAULT NULL,
  `job` varchar(45) DEFAULT NULL,
  `tags` varchar(255) NOT NULL DEFAULT '',
  `voiceMessage` varchar(512) DEFAULT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier_UNIQUE` (`identifier`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Data for `npwd_match_profiles`
INSERT INTO `npwd_match_profiles` (`id`, `identifier`, `name`, `image`, `bio`, `location`, `job`, `tags`, `voiceMessage`, `createdAt`, `updatedAt`) VALUES
(2, 'RE036OYR', 'Pierre Moraes', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, 1784934727000.0, 1784934727000.0),
(3, 'M6YW58XY', 'Player Dev', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, 1787637314000.0, 1787637314000.0);

-- Structure for `npwd_match_views`
DROP TABLE IF EXISTS `npwd_match_views`;
CREATE TABLE `npwd_match_views` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci NOT NULL,
  `profile` int(11) NOT NULL,
  `liked` tinyint(4) DEFAULT 0,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `match_profile_idx` (`profile`),
  KEY `identifier` (`identifier`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `npwd_messages`
DROP TABLE IF EXISTS `npwd_messages`;
CREATE TABLE `npwd_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `message` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci NOT NULL,
  `user_identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci NOT NULL,
  `conversation_id` varchar(512) NOT NULL,
  `isRead` tinyint(4) NOT NULL DEFAULT 0,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `visible` tinyint(4) NOT NULL DEFAULT 1,
  `author` varchar(255) NOT NULL,
  `is_embed` tinyint(4) NOT NULL DEFAULT 0,
  `embed` varchar(512) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `user_identifier` (`user_identifier`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `npwd_messages_conversations`
DROP TABLE IF EXISTS `npwd_messages_conversations`;
CREATE TABLE `npwd_messages_conversations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `conversation_list` varchar(225) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci NOT NULL,
  `label` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci DEFAULT '',
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_message_id` int(11) DEFAULT NULL,
  `is_group_chat` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `npwd_messages_participants`
DROP TABLE IF EXISTS `npwd_messages_participants`;
CREATE TABLE `npwd_messages_participants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `conversation_id` int(11) NOT NULL,
  `participant` varchar(225) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci NOT NULL,
  `unread_count` int(11) DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `message_participants_npwd_messages_conversations_id_fk` (`conversation_id`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `npwd_notes`
DROP TABLE IF EXISTS `npwd_notes`;
CREATE TABLE `npwd_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Data for `npwd_notes`
INSERT INTO `npwd_notes` (`id`, `identifier`, `title`, `content`) VALUES
(1, 'RE036OYR', 'forge-chat', '\nadd lembrar comandos recente\n\nadd mostrar comandos ao colocar ''/'' antes dos textos\n\nadd mostrar comandos admin, mod, staff apenas para quem tem permissao\n\nadd reposicionar chat\n\nadd ajuste de opacidade'),
(3, 'RE036OYR', 'forge-core', '\nAdd opçao de limpar dados de todos os Players ou de um player especifico.\n\nCorrigir: Ao criar um novo personagem ele abre o illenium appearence porem sobrepoe o seletor de spawn do personagem.'),
(4, 'RE036OYR', 'forge-core: Starter Pack', '\nprecisa corrigir o veiculo no ar.\n\no lammar ao entrar no veiculo ele precisa quebrar o vidro para entrar, precisa destrancar o carro e trancar imediatamente para ele entrar sem que o player possa sair do'),
(5, 'RE036OYR', 'illenium-appearance', '\nAo selecionar para criar o personagem esta bugando "nao aparece o ped quando muda de masculino para feminino".'),
(6, 'RE036OYR', 'pr_carkeys', '\ncorrigir erro de ao ligar o carro e estiver configurado na chave permanente do veiculo ligar junto (as vezes falha e o carro da uma acelerada e canta pneu).\n\nao sair do veiculo e deixar a chave na igniçao o motor deve'),
(7, 'RE036OYR', 'forge-garage', '\nimplementar no sistema de garagem a opçao de painel de gerenciamento da garagem ''visual, cores, etc de garagens IPL que tem''.');

-- Structure for `npwd_phone_contacts`
DROP TABLE IF EXISTS `npwd_phone_contacts`;
CREATE TABLE `npwd_phone_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `number` varchar(20) DEFAULT NULL,
  `display` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `npwd_phone_gallery`
DROP TABLE IF EXISTS `npwd_phone_gallery`;
CREATE TABLE `npwd_phone_gallery` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci DEFAULT NULL,
  `image` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `npwd_twitter_likes`
DROP TABLE IF EXISTS `npwd_twitter_likes`;
CREATE TABLE `npwd_twitter_likes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) NOT NULL,
  `tweet_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_combination` (`profile_id`,`tweet_id`),
  KEY `profile_idx` (`profile_id`),
  KEY `tweet_idx` (`tweet_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `npwd_twitter_profiles`
DROP TABLE IF EXISTS `npwd_twitter_profiles`;
CREATE TABLE `npwd_twitter_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_name` varchar(90) NOT NULL,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci NOT NULL,
  `avatar_url` varchar(255) DEFAULT 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png',
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `profile_name_UNIQUE` (`profile_name`),
  KEY `identifier` (`identifier`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Data for `npwd_twitter_profiles`
INSERT INTO `npwd_twitter_profiles` (`id`, `profile_name`, `identifier`, `avatar_url`, `createdAt`, `updatedAt`) VALUES
(2, 'Pierre_Moraes', 'RE036OYR', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', 1784934727000.0, 1784934727000.0),
(3, 'Player_Dev', 'M6YW58XY', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', 1787637314000.0, 1787637314000.0);

-- Structure for `npwd_twitter_reports`
DROP TABLE IF EXISTS `npwd_twitter_reports`;
CREATE TABLE `npwd_twitter_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) NOT NULL,
  `tweet_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_combination` (`profile_id`,`tweet_id`),
  KEY `profile_idx` (`profile_id`),
  KEY `tweet_idx` (`tweet_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `npwd_twitter_tweets`
DROP TABLE IF EXISTS `npwd_twitter_tweets`;
CREATE TABLE `npwd_twitter_tweets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `message` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `likes` int(11) NOT NULL DEFAULT 0,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci NOT NULL,
  `visible` tinyint(4) NOT NULL DEFAULT 1,
  `images` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci DEFAULT '',
  `retweet` int(11) DEFAULT NULL,
  `profile_id` int(11) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `npwd_twitter_tweets_npwd_twitter_profiles_id_fk` (`profile_id`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_bench_location_crafts`
DROP TABLE IF EXISTS `nxtgn_crafting_bench_location_crafts`;
CREATE TABLE `nxtgn_crafting_bench_location_crafts` (
  `location` varchar(36) NOT NULL,
  `user_id` varchar(255) DEFAULT NULL,
  `recipe` varchar(255) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `started_at` int(11) DEFAULT NULL,
  `completed_at` int(11) DEFAULT 0,
  `paused_at` int(11) DEFAULT NULL,
  `craft_id` varchar(50) NOT NULL,
  `removed_items` longtext DEFAULT NULL,
  `result_items` longtext DEFAULT NULL,
  UNIQUE KEY `craft_id` (`craft_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_bench_locations`
DROP TABLE IF EXISTS `nxtgn_crafting_bench_locations`;
CREATE TABLE `nxtgn_crafting_bench_locations` (
  `uuid` varchar(36) NOT NULL,
  `bench_type` varchar(36) NOT NULL,
  `loc_x` float NOT NULL DEFAULT 0,
  `loc_y` float NOT NULL DEFAULT 0,
  `loc_z` float NOT NULL DEFAULT 0,
  `loc_h` float NOT NULL DEFAULT 0,
  `is_portable` int(11) NOT NULL DEFAULT 0,
  `shared_levels` int(1) DEFAULT NULL,
  `shared_queue` int(1) DEFAULT NULL,
  `routing_bucket` int(11) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`uuid`),
  KEY `FK_nxtgn_crafting_bench_locations_nxtgn_crafting_bench_types` (`bench_type`) USING BTREE,
  CONSTRAINT `FK_nxtgn_crafting_bench_locations_nxtgn_crafting_bench_types` FOREIGN KEY (`bench_type`) REFERENCES `nxtgn_crafting_bench_types` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_bench_type_access`
DROP TABLE IF EXISTS `nxtgn_crafting_bench_type_access`;
CREATE TABLE `nxtgn_crafting_bench_type_access` (
  `bench_type` varchar(50) NOT NULL,
  `access` varchar(50) NOT NULL,
  `ranks` longtext DEFAULT NULL,
  UNIQUE KEY `bench_type` (`bench_type`,`access`),
  CONSTRAINT `FK__nxtgn_crafting_bench_types` FOREIGN KEY (`bench_type`) REFERENCES `nxtgn_crafting_bench_types` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_bench_type_categories`
DROP TABLE IF EXISTS `nxtgn_crafting_bench_type_categories`;
CREATE TABLE `nxtgn_crafting_bench_type_categories` (
  `uuid` varchar(36) NOT NULL,
  `bench_type` varchar(36) NOT NULL,
  `category` varchar(36) NOT NULL,
  `is_default_denied` int(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`uuid`),
  UNIQUE KEY `bench_type` (`bench_type`,`category`),
  KEY `FK_bench_type_categories_categories` (`category`),
  CONSTRAINT `FK_bench_type_categories_bench_types` FOREIGN KEY (`bench_type`) REFERENCES `nxtgn_crafting_bench_types` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `FK_bench_type_categories_categories` FOREIGN KEY (`category`) REFERENCES `nxtgn_crafting_categories` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_bench_type_category_recipes`
DROP TABLE IF EXISTS `nxtgn_crafting_bench_type_category_recipes`;
CREATE TABLE `nxtgn_crafting_bench_type_category_recipes` (
  `bench_type_category` varchar(36) NOT NULL,
  `recipe` varchar(36) NOT NULL,
  UNIQUE KEY `bench_type_category` (`bench_type_category`,`recipe`),
  KEY `FK_bench_type_category_recipes_recipes` (`recipe`),
  KEY `FK_bench_type_category_recipes_bench_types` (`bench_type_category`) USING BTREE,
  CONSTRAINT `FK_bench_type_category_recipes_bench_type_categories` FOREIGN KEY (`bench_type_category`) REFERENCES `nxtgn_crafting_bench_type_categories` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `FK_bench_type_category_recipes_recipes` FOREIGN KEY (`recipe`) REFERENCES `nxtgn_crafting_recipes` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_bench_type_levels`
DROP TABLE IF EXISTS `nxtgn_crafting_bench_type_levels`;
CREATE TABLE `nxtgn_crafting_bench_type_levels` (
  `bench_type` varchar(36) NOT NULL,
  `category` varchar(36) DEFAULT NULL,
  `level` float NOT NULL DEFAULT 1,
  UNIQUE KEY `bench_type_category` (`bench_type`,`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_bench_types`
DROP TABLE IF EXISTS `nxtgn_crafting_bench_types`;
CREATE TABLE `nxtgn_crafting_bench_types` (
  `uuid` varchar(36) NOT NULL,
  `name` varchar(50) NOT NULL,
  `model` varchar(50) DEFAULT NULL,
  `full_access` int(1) NOT NULL DEFAULT 0,
  `shared_levels` int(1) NOT NULL DEFAULT 0,
  `shared_queue` int(1) NOT NULL DEFAULT 0,
  `shared_queue_claim` varchar(10) NOT NULL DEFAULT 'anyone',
  `shared_queue_cancel` varchar(10) NOT NULL DEFAULT 'anyone',
  `created_by` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_blueprints`
DROP TABLE IF EXISTS `nxtgn_crafting_blueprints`;
CREATE TABLE `nxtgn_crafting_blueprints` (
  `uuid` varchar(36) NOT NULL,
  `label` varchar(50) NOT NULL,
  `description` text DEFAULT NULL,
  `uses` int(11) DEFAULT NULL,
  `item` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_categories`
DROP TABLE IF EXISTS `nxtgn_crafting_categories`;
CREATE TABLE `nxtgn_crafting_categories` (
  `uuid` varchar(36) NOT NULL,
  `title` varchar(50) NOT NULL,
  `description` text NOT NULL DEFAULT '',
  `icon` varchar(50) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_player_blueprints`
DROP TABLE IF EXISTS `nxtgn_crafting_player_blueprints`;
CREATE TABLE `nxtgn_crafting_player_blueprints` (
  `identifier` varchar(255) NOT NULL,
  `blueprint` varchar(36) NOT NULL,
  UNIQUE KEY `identifier` (`identifier`,`blueprint`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_player_history`
DROP TABLE IF EXISTS `nxtgn_crafting_player_history`;
CREATE TABLE `nxtgn_crafting_player_history` (
  `identifier` varchar(255) NOT NULL,
  `bench_type` varchar(36) NOT NULL,
  `bench_location` varchar(36) NOT NULL,
  `recipe` varchar(36) NOT NULL,
  `quantity` int(11) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_player_levels`
DROP TABLE IF EXISTS `nxtgn_crafting_player_levels`;
CREATE TABLE `nxtgn_crafting_player_levels` (
  `identifier` varchar(255) NOT NULL DEFAULT '0',
  `category` varchar(36) NOT NULL,
  `level` float NOT NULL DEFAULT 0,
  UNIQUE KEY `identifier` (`identifier`,`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_players`
DROP TABLE IF EXISTS `nxtgn_crafting_players`;
CREATE TABLE `nxtgn_crafting_players` (
  `identifier` varchar(255) NOT NULL,
  `level` float NOT NULL DEFAULT 1,
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_recipe_blueprints`
DROP TABLE IF EXISTS `nxtgn_crafting_recipe_blueprints`;
CREATE TABLE `nxtgn_crafting_recipe_blueprints` (
  `recipe_id` varchar(36) NOT NULL,
  `blueprint_id` varchar(36) NOT NULL,
  UNIQUE KEY `recipe_id` (`recipe_id`,`blueprint_id`) USING BTREE,
  KEY `FK_nxtgn_crafting_recipe_blueprints_nxtgn_crafting_blueprints` (`blueprint_id`),
  CONSTRAINT `FK_nxtgn_crafting_recipe_blueprints_nxtgn_crafting_blueprints` FOREIGN KEY (`blueprint_id`) REFERENCES `nxtgn_crafting_blueprints` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `FK_nxtgn_crafting_recipe_blueprints_nxtgn_crafting_recipes` FOREIGN KEY (`recipe_id`) REFERENCES `nxtgn_crafting_recipes` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci ROW_FORMAT=DYNAMIC;

-- Structure for `nxtgn_crafting_recipe_ingredients`
DROP TABLE IF EXISTS `nxtgn_crafting_recipe_ingredients`;
CREATE TABLE `nxtgn_crafting_recipe_ingredients` (
  `recipe_id` varchar(36) NOT NULL,
  `item` varchar(50) NOT NULL,
  `count` int(11) NOT NULL DEFAULT 1,
  UNIQUE KEY `recipe_id` (`recipe_id`,`item`),
  CONSTRAINT `FK_nxtgn_crafting_recipe_ingredients_nxtgn_crafting_recipes` FOREIGN KEY (`recipe_id`) REFERENCES `nxtgn_crafting_recipes` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_recipe_results`
DROP TABLE IF EXISTS `nxtgn_crafting_recipe_results`;
CREATE TABLE `nxtgn_crafting_recipe_results` (
  `recipe_id` varchar(36) NOT NULL,
  `item` varchar(50) NOT NULL,
  `count` int(11) NOT NULL DEFAULT 1,
  `metadata` longtext DEFAULT NULL,
  UNIQUE KEY `recipe_id` (`recipe_id`,`item`),
  CONSTRAINT `FK_nxtgn_crafting_recipe_results_nxtgn_crafting_recipes` FOREIGN KEY (`recipe_id`) REFERENCES `nxtgn_crafting_recipes` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `nxtgn_crafting_recipes`
DROP TABLE IF EXISTS `nxtgn_crafting_recipes`;
CREATE TABLE `nxtgn_crafting_recipes` (
  `uuid` varchar(36) NOT NULL,
  `title` varchar(50) NOT NULL,
  `description` text NOT NULL,
  `category` varchar(36) NOT NULL,
  `required_level` int(11) DEFAULT NULL,
  `required_category_level` int(11) DEFAULT NULL,
  `crafting_time` int(11) NOT NULL DEFAULT 10,
  `xp_reward` int(11) DEFAULT 25,
  `prop_model` varchar(50) DEFAULT NULL,
  `prop_rot_x` float DEFAULT NULL,
  `prop_rot_y` float DEFAULT NULL,
  `prop_rot_z` float DEFAULT NULL,
  `prop_offset_x` float DEFAULT NULL,
  `prop_offset_y` float DEFAULT NULL,
  `prop_offset_z` float DEFAULT NULL,
  `cooldown_limit` int(11) DEFAULT NULL,
  `cooldown_window` int(11) DEFAULT NULL,
  `order_index` int(11) DEFAULT NULL,
  `failure_chance` int(11) DEFAULT NULL,
  `failure_mode` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`uuid`),
  KEY `FK_nxtgn_crafting_recipes_nxtgn_crafting_categories` (`category`),
  CONSTRAINT `FK_nxtgn_crafting_recipes_nxtgn_crafting_categories` FOREIGN KEY (`category`) REFERENCES `nxtgn_crafting_categories` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `occasion_vehicles`
DROP TABLE IF EXISTS `occasion_vehicles`;
CREATE TABLE `occasion_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `seller` varchar(50) DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `description` longtext DEFAULT NULL,
  `plate` varchar(50) DEFAULT NULL,
  `model` varchar(50) DEFAULT NULL,
  `mods` text DEFAULT NULL,
  `occasionid` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `occasionId` (`occasionid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `ox_doorlock`
DROP TABLE IF EXISTS `ox_doorlock`;
CREATE TABLE `ox_doorlock` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `data` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Data for `ox_doorlock`
INSERT INTO `ox_doorlock` (`id`, `name`, `data`) VALUES
(8, 'Hangar Prologo', '{"auto":true,"holdOpen":true,"state":1,"coords":{"x":-495.6455078125,"y":6523.45654296875,"z":5.84265613555908},"doors":[{"heading":312,"coords":{"x":-494.7740173339844,"y":6522.49169921875,"z":5.84072160720825},"model":-687077553},{"heading":312,"coords":{"x":-496.51702880859377,"y":6524.42138671875,"z":5.84459018707275},"model":1093688222}],"maxDistance":2,"doorGroup":"Delegacia de Paleto"}'),
(9, 'ddd', '{"auto":true,"state":0,"coords":{"x":-443.5792541503906,"y":6016.140625,"z":31.86632919311523},"doors":[{"heading":135,"coords":{"x":-444.49847412109377,"y":6017.06005859375,"z":31.86632919311523},"model":-1501157055},{"heading":315,"coords":{"x":-442.6600341796875,"y":6015.2216796875,"z":31.86632919311523},"model":-1501157055}],"maxDistance":2,"doorGroup":"Delegacia de Paleto"}'),
(24, 'cofre 1', '{"heading":160,"closeSpeed":0.5,"doors":false,"doorType":"rotate","slideDirection":"left","model":961976194,"openAngle":90,"coords":{"x":255.22825622558595,"y":223.97601318359376,"z":102.39321899414063},"maxDistance":2,"openHeading":200,"slideDistance":2,"openSpeed":0.5,"state":1}'),
(26, 'teste', '{"doorType":"rotate","coords":{"x":-1047.684326171875,"y":-237.97084045410157,"z":44.1709976196289},"closedHeading":0,"maxDistance":2,"openHeading":180,"openAngle":90,"doorRate":2,"openSpeed":3,"doors":[{"heading":118,"coords":{"x":-1048.2850341796876,"y":-236.81707763671876,"z":44.1709976196289},"model":-1821777087},{"heading":298,"coords":{"x":-1047.083740234375,"y":-239.12460327148438,"z":44.1709976196289},"model":-1821777087}],"slideDirection":"left","slideDistance":2,"closeSpeed":3,"state":0}'),
(27, 'teste2', '{"doorType":"slide","coords":{"x":-1057.7672119140626,"y":-237.48397827148438,"z":43.02099990844726},"maxDistance":2,"model":969847031,"openAngle":90,"doorRate":2,"openSpeed":3,"doors":false,"slideDirection":"left","heading":28,"slideDistance":4,"closeSpeed":3,"state":0}'),
(28, 'teste3', '{"doorType":"slide","coords":{"x":-1063.842041015625,"y":-240.6463623046875,"z":43.02099990844726},"maxDistance":2,"model":969847031,"openAngle":90,"doorRate":2,"openSpeed":3,"doors":false,"slideDirection":"left","heading":28,"slideDistance":2,"closeSpeed":3,"state":0}'),
(29, 'ps_mloproperty1_1', '{"coords":{"x":-848.934326171875,"y":179.307861328125,"z":70.02470397949219},"characters":["RE036OYR","RE036OYR","RE036OYR","RE036OYR"],"maxDistance":2.5,"state":1,"model":-1568354151,"heading":265}'),
(30, 'ps_mloproperty1_7', '{"coords":{"x":-793.789794921875,"y":181.53773498535157,"z":73.04045104980469},"characters":["RE036OYR","RE036OYR","RE036OYR","RE036OYR"],"maxDistance":2.5,"state":0,"doors":[{"coords":{"x":-794.185302734375,"y":182.56800842285157,"z":73.04045104980469},"heading":111,"model":1245831483},{"coords":{"x":-793.3943481445313,"y":180.50746154785157,"z":73.04045104980469},"heading":111,"model":-1454760130}]}'),
(31, 'ps_mloproperty1_4', '{"coords":{"x":-816.411376953125,"y":178.30441284179688,"z":72.82737731933594},"characters":["RE036OYR","RE036OYR","RE036OYR","RE036OYR"],"maxDistance":2.5,"state":0,"doors":[{"coords":{"x":-816.7160034179688,"y":179.09796142578126,"z":72.82737731933594},"heading":291,"model":159994461},{"coords":{"x":-816.1068115234375,"y":177.5108642578125,"z":72.82737731933594},"heading":291,"model":-1686014385}]}'),
(32, 'ps_mloproperty1_3', '{"coords":{"x":-814.4789428710938,"y":186.28309631347657,"z":74.5057373046875},"characters":["RE036OYR","RE036OYR","RE036OYR","RE036OYR"],"maxDistance":2.5,"state":1,"model":30769481,"heading":271}'),
(33, 'ps_mloproperty1_2', '{"coords":{"x":-844.051025390625,"y":155.9619140625,"z":66.03221130371094},"characters":["RE036OYR","RE036OYR","RE036OYR","RE036OYR"],"maxDistance":2.5,"state":1,"model":-2125423493,"heading":90}'),
(34, 'ps_mloproperty1_6', '{"coords":{"x":-795.535400390625,"y":177.61688232421876,"z":73.04045104980469},"characters":["RE036OYR","RE036OYR","RE036OYR","RE036OYR"],"maxDistance":2.5,"state":0,"doors":[{"coords":{"x":-794.505126953125,"y":178.0123748779297,"z":73.04045104980469},"heading":21,"model":1245831483},{"coords":{"x":-796.565673828125,"y":177.22137451171876,"z":73.04045104980469},"heading":21,"model":-1454760130}]}'),
(35, 'ps_mloproperty1_5', '{"coords":{"x":-806.28173828125,"y":186.0246124267578,"z":72.6240463256836},"characters":["RE036OYR","RE036OYR","RE036OYR","RE036OYR"],"maxDistance":2.5,"state":1,"model":-1563640173,"heading":201}'),
(36, 'ps_mloproperty2_1', '{"coords":{"x":-355.0296936035156,"y":-135.15753173828126,"z":41.99063110351562},"characters":["RE036OYR","RE036OYR","RE036OYR"],"maxDistance":2.5,"state":1,"model":-550347177,"heading":269}'),
(38, 'ps_mloproperty4_1', '{"model":132154435,"characters":["RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR"],"coords":{"x":1972.7689208984376,"y":3815.365966796875,"z":33.66325759887695},"heading":30,"maxDistance":2.5,"state":1}'),
(39, 'ps_mloproperty4_2', '{"model":67910261,"characters":["RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR","RE036OYR"],"coords":{"x":1972.2210693359376,"y":3824.23388671875,"z":33.79093551635742},"heading":91,"maxDistance":2.5,"state":1}'),
(40, 'ps_mloproperty11_1', '{"state":1,"model":-607040053,"characters":["RE036OYR"],"coords":{"x":-1149.7088623046876,"y":-1521.087890625,"z":10.78267097473144},"maxDistance":2.5,"heading":35}'),
(41, 'ps_mloproperty11_3', '{"state":1,"model":-1128607325,"characters":["RE036OYR"],"coords":{"x":-1149.891845703125,"y":-1515.724365234375,"z":10.78082275390625},"maxDistance":2.5,"heading":305}'),
(42, 'ps_mloproperty11_2', '{"state":1,"model":1575804630,"characters":["RE036OYR"],"coords":{"x":-1150.157958984375,"y":-1518.768310546875,"z":10.78084850311279},"maxDistance":2.5,"heading":215}'),
(43, 'ps_mloproperty11_4', '{"state":1,"model":-1128607325,"characters":["RE036OYR"],"coords":{"x":-1148.666748046875,"y":-1515.7781982421876,"z":10.78082275390625},"maxDistance":2.5,"heading":216}'),
(44, 'ps_mloproperty14_1', '{"characters":["RE036OYR"],"state":1,"model":520341586,"heading":180,"maxDistance":2.5,"coords":{"x":-14.86892127990722,"y":-1441.18212890625,"z":31.1932258605957}}'),
(45, 'ps_mloproperty14_2', '{"characters":["RE036OYR"],"state":1,"model":703855057,"heading":360,"maxDistance":2.5,"coords":{"x":-25.27838134765625,"y":-1430.390625,"z":32.01632308959961}}'),
(46, 'ps_mloproperty14_3', '{"characters":["RE036OYR"],"state":1,"model":-610054759,"heading":90,"maxDistance":2.5,"coords":{"x":-15.98929214477539,"y":-1436.027587890625,"z":31.19914245605468}}'),
(47, 'ps_mloproperty14_4', '{"doors":[{"coords":{"x":-13.32437896728515,"y":-1434.3800048828126,"z":31.19468116760254},"heading":270,"model":1770281453},{"coords":{"x":-13.37053108215332,"y":-1431.78466796875,"z":31.19468116760254},"heading":90,"model":1770281453}],"state":1,"maxDistance":2.5,"coords":{"x":-13.34745502471923,"y":-1433.082275390625,"z":31.19468116760254},"characters":["RE036OYR"]}'),
(49, 'testeeee', '{"closed":{"coords":{"x":1574.559814453125,"y":3743.81298828125,"z":34.78893661499023},"rotation":{"x":0.0,"y":0.0,"z":79.7809829711914}},"open":{"coords":{"x":1575.8807373046876,"y":3746.6826171875,"z":34.92393112182617},"rotation":{"x":0.0,"y":0.0,"z":-26.21901321411132}},"heading":80,"maxDistance":4,"rotation":{"x":0.0,"y":0.0,"z":79.7809829711914},"doorGroup":"testeeee","coords":{"x":1574.559814453125,"y":3743.81298828125,"z":34.78893661499023},"doorOpened":true,"hideUi":true,"doors":false,"model":-1461908217,"state":1,"doorType":"rotate"}'),
(50, 'vec3(1574.071655, 3727.362793, 35.143925)', '{"closed":{"coords":{"x":1574.0716552734376,"y":3727.36279296875,"z":35.14392471313476},"rotation":{"x":0.0,"y":0.0,"z":75.98381805419922}},"open":{"coords":{"x":1574.87744140625,"y":3729.96044921875,"z":35.14392471313476},"rotation":{"x":0.0,"y":0.0,"z":-9.01618099212646}},"heading":76,"maxDistance":4,"rotation":{"x":0.0,"y":0.0,"z":75.98381805419922},"doorGroup":"testeeee","coords":{"x":1574.0716552734376,"y":3727.36279296875,"z":35.14392471313476},"doorOpened":false,"hideUi":true,"doors":false,"model":-1461908217,"state":1,"doorType":"rotate"}');

-- Structure for `ox_inventory`
DROP TABLE IF EXISTS `ox_inventory`;
CREATE TABLE `ox_inventory` (
  `owner` varchar(60) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `data` longtext DEFAULT NULL,
  `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  UNIQUE KEY `owner` (`owner`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Data for `ox_inventory`
INSERT INTO `ox_inventory` (`owner`, `name`, `data`, `lastupdated`) VALUES
('', 'property_13_furniture_13-287407-782495', '[{"name":"tablet","slot":1,"count":1}]', 1785713400000.0),
('', 'backpack_359021', '[{"count":1,"name":"burger","slot":1,"metadata":{"barcode":"1786831917-86718795"}},{"count":1,"name":"cola","slot":3,"metadata":{"barcode":"1786831924-77106854"}},{"count":1,"name":"cola","slot":6,"metadata":{"barcode":"1786831924-13719610"}},{"count":1,"name":"cola","slot":7,"metadata":{"barcode":"1786831923-77252642"}},{"count":1,"name":"cola","slot":8,"metadata":{"barcode":"1786831925-99249505"}}]', 1786834640000.0);

-- Structure for `pa_vehicleshop_player_level`
DROP TABLE IF EXISTS `pa_vehicleshop_player_level`;
CREATE TABLE `pa_vehicleshop_player_level` (
  `citizenid` varchar(50) NOT NULL,
  `level` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `pa_vehicleshop_showroom_vehicles`
DROP TABLE IF EXISTS `pa_vehicleshop_showroom_vehicles`;
CREATE TABLE `pa_vehicleshop_showroom_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dealershipId` int(11) DEFAULT NULL,
  `data` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `pa_vehicleshop_stocks`
DROP TABLE IF EXISTS `pa_vehicleshop_stocks`;
CREATE TABLE `pa_vehicleshop_stocks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dealershipId` int(11) DEFAULT NULL,
  `data` longtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `pinel-crafting`
DROP TABLE IF EXISTS `pinel-crafting`;
CREATE TABLE `pinel-crafting` (
  `craft_id` int(11) NOT NULL AUTO_INCREMENT,
  `craft_name` varchar(50) DEFAULT NULL,
  `crafting` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`crafting`)),
  `blipdata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`blipdata`)),
  `jobs` longtext DEFAULT NULL,
  PRIMARY KEY (`craft_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pinel-crafting-items`
DROP TABLE IF EXISTS `pinel-crafting-items`;
CREATE TABLE `pinel-crafting-items` (
  `craft_id` int(11) DEFAULT NULL,
  `item` varchar(50) DEFAULT NULL,
  `item_label` varchar(50) DEFAULT NULL,
  `recipe` longtext DEFAULT NULL,
  `time` int(11) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `model` longtext DEFAULT NULL,
  `anim` longtext DEFAULT NULL,
  `level` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pinel_blip`
DROP TABLE IF EXISTS `pinel_blip`;
CREATE TABLE `pinel_blip` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `data` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `pinel_core_staff`
DROP TABLE IF EXISTS `pinel_core_staff`;
CREATE TABLE `pinel_core_staff` (
  `citizenid` varchar(64) NOT NULL,
  `role` varchar(48) NOT NULL,
  `updated_at` bigint(20) NOT NULL,
  PRIMARY KEY (`citizenid`),
  KEY `idx_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pinel_whitelist`
DROP TABLE IF EXISTS `pinel_whitelist`;
CREATE TABLE `pinel_whitelist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen` varchar(50) NOT NULL,
  `fivem` varchar(80) DEFAULT NULL,
  `added_by` varchar(80) DEFAULT NULL,
  `discord` varchar(80) DEFAULT NULL,
  `name` varchar(120) DEFAULT NULL,
  `license` varchar(80) DEFAULT NULL,
  `whitelisted_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizen` (`citizen`)
) ENGINE=MyISAM AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Data for `pinel_whitelist`
INSERT INTO `pinel_whitelist` (`id`, `citizen`, `fivem`, `added_by`, `discord`, `name`, `license`, `whitelisted_at`) VALUES
(10, 'RE036OYR', NULL, 'RE036OYR', 'discord:340522406332465152', 'Pierre Moraes', 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 1784934771);

-- Structure for `pinel_whitelist_answers`
DROP TABLE IF EXISTS `pinel_whitelist_answers`;
CREATE TABLE `pinel_whitelist_answers` (
  `citizen` varchar(50) NOT NULL,
  `answers` longtext DEFAULT NULL,
  `submitted_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`citizen`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `pinel_whitelist_config`
DROP TABLE IF EXISTS `pinel_whitelist_config`;
CREATE TABLE `pinel_whitelist_config` (
  `id` int(11) NOT NULL,
  `config` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `player_groups`
DROP TABLE IF EXISTS `player_groups`;
CREATE TABLE `player_groups` (
  `citizenid` varchar(50) NOT NULL,
  `group` varchar(50) NOT NULL,
  `type` varchar(50) NOT NULL,
  `grade` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY (`citizenid`,`type`,`group`),
  CONSTRAINT `fk_citizenid` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Data for `player_groups`
INSERT INTO `player_groups` (`citizenid`, `group`, `type`, `grade`) VALUES
('RE036OYR', 'police', 'job', 5);

-- Structure for `player_jobs_activity`
DROP TABLE IF EXISTS `player_jobs_activity`;
CREATE TABLE `player_jobs_activity` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `job` varchar(255) NOT NULL,
  `last_checkin` int(11) NOT NULL,
  `last_checkout` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `id` (`id`) USING BTREE,
  KEY `last_checkout` (`last_checkout`) USING BTREE,
  KEY `citizenid_job` (`citizenid`,`job`) USING BTREE,
  CONSTRAINT `player_jobs_activity_ibfk_1` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `player_mails`
DROP TABLE IF EXISTS `player_mails`;
CREATE TABLE `player_mails` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `sender` varchar(50) DEFAULT NULL,
  `subject` varchar(50) DEFAULT NULL,
  `message` text DEFAULT NULL,
  `read` tinyint(4) DEFAULT 0,
  `mailid` int(11) DEFAULT NULL,
  `date` timestamp NULL DEFAULT current_timestamp(),
  `button` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `player_outfit_codes`
DROP TABLE IF EXISTS `player_outfit_codes`;
CREATE TABLE `player_outfit_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `outfitid` int(11) NOT NULL,
  `code` varchar(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `FK_player_outfit_codes_player_outfits` (`outfitid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `player_outfits`
DROP TABLE IF EXISTS `player_outfits`;
CREATE TABLE `player_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `outfitname` varchar(50) NOT NULL DEFAULT '0',
  `model` varchar(50) DEFAULT NULL,
  `props` text DEFAULT NULL,
  `components` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid_outfitname_model` (`citizenid`,`outfitname`,`model`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Data for `player_outfits`
INSERT INTO `player_outfits` (`id`, `citizenid`, `outfitname`, `model`, `props`, `components`) VALUES
(26, 'RE036OYR', 'Farda 1', 'mp_m_freemode_01', '[{"drawable":-1,"texture":-1,"prop_id":0},{"drawable":20,"texture":9,"prop_id":1},{"drawable":-1,"texture":-1,"prop_id":2},{"drawable":-1,"texture":-1,"prop_id":6},{"drawable":-1,"texture":-1,"prop_id":7}]', '[{"component_id":0,"texture":0,"drawable":0},{"component_id":1,"texture":13,"drawable":169},{"component_id":2,"texture":0,"drawable":0},{"component_id":3,"texture":0,"drawable":202},{"component_id":4,"texture":0,"drawable":123},{"component_id":5,"texture":0,"drawable":0},{"component_id":6,"texture":9,"drawable":32},{"component_id":7,"texture":0,"drawable":0},{"component_id":8,"texture":0,"drawable":170},{"component_id":9,"texture":0,"drawable":0},{"component_id":10,"texture":0,"drawable":0},{"component_id":11,"texture":3,"drawable":349}]'),
(27, 'RE036OYR', 'Farda 2', 'mp_m_freemode_01', '[{"drawable":-1,"texture":-1,"prop_id":0},{"drawable":20,"texture":9,"prop_id":1},{"drawable":-1,"texture":-1,"prop_id":2},{"drawable":-1,"texture":-1,"prop_id":6},{"drawable":-1,"texture":-1,"prop_id":7}]', '[{"drawable":0,"component_id":0,"texture":0},{"drawable":169,"component_id":1,"texture":13},{"drawable":3,"component_id":2,"texture":0},{"drawable":202,"component_id":3,"texture":0},{"drawable":123,"component_id":4,"texture":0},{"drawable":0,"component_id":5,"texture":0},{"drawable":32,"component_id":6,"texture":9},{"drawable":0,"component_id":7,"texture":0},{"drawable":169,"component_id":8,"texture":3},{"drawable":26,"component_id":9,"texture":6},{"drawable":70,"component_id":10,"texture":1},{"drawable":464,"component_id":11,"texture":0}]');

-- Structure for `player_transactions`
DROP TABLE IF EXISTS `player_transactions`;
CREATE TABLE `player_transactions` (
  `id` varchar(50) NOT NULL,
  `isFrozen` int(11) DEFAULT 0,
  `transactions` longtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Data for `player_transactions`
INSERT INTO `player_transactions` (`id`, `isFrozen`, `transactions`) VALUES
('RE036OYR', 0, '[{"issuer":"Pierre Moraes","receiver":"Pierre Moraes","message":"Teste Coco teimoso","trans_id":"74151e7b-054e-4f3e-a33f-3e218742d845","time":1785202801,"title":"Conta Pessoal / RE036OYR","amount":5000,"trans_type":"deposit"},{"issuer":"Pierre Moraes","receiver":"Pierre Moraes","message":"%s tem %s $%s","trans_id":"cd67e2a4-7b1e-494e-83a3-732d4840bdd9","time":1785202756,"title":"Conta Pessoal / RE036OYR","amount":900,"trans_type":"withdraw"}]');

-- Structure for `player_vehicles`
DROP TABLE IF EXISTS `player_vehicles`;
CREATE TABLE `player_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license` varchar(50) DEFAULT NULL,
  `citizenid` varchar(50) DEFAULT NULL,
  `vehicle` varchar(50) DEFAULT NULL,
  `hash` varchar(50) DEFAULT NULL,
  `mods` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `plate` varchar(15) NOT NULL,
  `fakeplate` varchar(50) DEFAULT NULL,
  `garage` varchar(50) DEFAULT NULL,
  `fuel` int(11) DEFAULT 100,
  `engine` float DEFAULT 1000,
  `body` float DEFAULT 1000,
  `state` int(11) DEFAULT 1,
  `depotprice` int(11) NOT NULL DEFAULT 0,
  `drivingdistance` int(50) DEFAULT NULL,
  `status` text DEFAULT NULL,
  `coords` text DEFAULT NULL,
  `glovebox` longtext DEFAULT NULL,
  `trunk` longtext DEFAULT NULL,
  `mileage` float NOT NULL DEFAULT 0,
  `balance` int(11) NOT NULL DEFAULT 0,
  `paymentamount` int(11) NOT NULL DEFAULT 0,
  `paymentsleft` int(11) NOT NULL DEFAULT 0,
  `financetime` int(11) NOT NULL DEFAULT 0,
  `vehicle_name` longtext DEFAULT NULL,
  `deformation` longtext DEFAULT NULL,
  `parking_coords` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate` (`plate`),
  UNIQUE KEY `UK_playervehicles_plate` (`plate`),
  KEY `FK_playervehicles_players` (`citizenid`),
  CONSTRAINT `FK_playervehicles_players` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `player_vehicles_ibfk_1` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=79 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Data for `player_vehicles`
INSERT INTO `player_vehicles` (`id`, `license`, `citizenid`, `vehicle`, `hash`, `mods`, `plate`, `fakeplate`, `garage`, `fuel`, `engine`, `body`, `state`, `depotprice`, `drivingdistance`, `status`, `coords`, `glovebox`, `trunk`, `mileage`, `balance`, `paymentamount`, `paymentsleft`, `financetime`, `vehicle_name`, `deformation`, `parking_coords`) VALUES
(64, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'jester4', '-1582061455', '{"pearlescentColor":5,"modRearBumper":-1,"model":-1582061455,"color2":36,"doors":[],"modDashboard":-1,"xenonColor":255,"modXenon":false,"modGrille":-1,"modLightbar":-1,"color1":20,"livery":-1,"modBrakes":-1,"modTank":-1,"paintType1":7,"plate":"5TS706NB","modFrontBumper":-1,"modNitrous":-1,"tyreSmokeColor":[255,255,255],"modOrnaments":-1,"modCustomTiresF":false,"modSmokeEnabled":false,"modSideSkirt":-1,"modSuspension":-1,"modDoorSpeaker":-1,"modHydrolic":-1,"modHydraulics":false,"tankHealth":998,"bodyHealth":994,"modDial":-1,"modTransmission":-1,"modTrimB":-1,"neonColor":[255,0,255],"plateIndex":0,"interiorColor":27,"modLivery":-1,"modSeats":-1,"wheelColor":134,"modTrimA":-1,"modRoof":-1,"modEngineBlock":-1,"modAerials":-1,"lockState":1,"modHood":-1,"modSteeringWheel":-1,"paintType2":7,"dashboardColor":156,"neonEnabled":[false,false,false,false],"modDoorR":-1,"modFrontWheels":-1,"modEngine":-1,"windows":[4,5],"modShifterLeavers":-1,"modFrame":-1,"modTrunk":-1,"dirtLevel":11,"modAPlate":-1,"wheelSize":1.0,"modArmor":-1,"modFender":-1,"driftTyres":false,"modTurbo":false,"modSpoilers":-1,"windowTint":-1,"modHorns":-1,"modSpeakers":-1,"modCustomTiresR":false,"extras":[],"modSubwoofer":false,"engineHealth":999,"modWindows":-1,"modBackWheels":-1,"modArchCover":-1,"modRightFender":-1,"wheels":1,"modStruts":-1,"modExhaust":-1,"modVanityPlate":-1,"tyres":[],"modRoofLivery":-1,"bulletProofTyres":1,"oilLevel":5,"modPlateHolder":-1,"modAirFilter":-1,"wheelWidth":1.0,"fuelLevel":92}', '5TS706NB', NULL, 'Tia do Franklin #14', 91, 998, 994, 1, 0, NULL, NULL, NULL, NULL, NULL, 1.02296, 0, 0, 0, 0, NULL, '[{"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.0},"damage":0.003},{"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0}]', '{"x":-23.45386886596679,"h":334.3494873046875,"z":30.0179443359375,"y":-1438.5184326171876}'),
(65, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'jester4', '-1582061455', '{"dirtLevel":0,"modCustomTiresF":false,"wheelWidth":0.59910613298416,"color1":[105,0,0],"modArchCover":2,"modFrontBumper":1,"modXenon":false,"modOrnaments":-1,"windows":[4,5],"modGrille":3,"modEngineBlock":1,"modSeats":1,"modAPlate":-1,"modRightFender":3,"modSmokeEnabled":false,"extras":[],"fuelLevel":21,"modRoof":2,"plateIndex":0,"modTrimA":1,"modNitrous":-1,"modSideSkirt":3,"modTrunk":-1,"tankHealth":1000,"modSpeakers":-1,"modHorns":1,"modTransmission":2,"modSpoilers":-1,"engineHealth":1000,"modCustomTiresR":false,"plate":"89KYG626","modDial":1,"modLightbar":-1,"modShifterLeavers":-1,"modFender":1,"paintType2":7,"modSubwoofer":1,"xenonColor":255,"modLivery":5,"modFrontWheels":3,"modFrame":3,"modRearBumper":3,"neonColor":[255,0,255],"modDashboard":-1,"modRoofLivery":-1,"modEngine":3,"modSuspension":-1,"oilLevel":5,"wheels":1,"modWindows":-1,"paintType1":7,"bodyHealth":910,"modExhaust":2,"wheelColor":88,"modHood":3,"windowTint":-1,"pearlescentColor":111,"color2":[250,250,250],"dashboardColor":156,"doors":[],"modTurbo":1,"tyreSmokeColor":[255,255,255],"modBrakes":2,"modHydraulics":1,"modBackWheels":-1,"modSteeringWheel":2,"modTrimB":-1,"modPlateHolder":-1,"modVanityPlate":-1,"interiorColor":27,"modTank":1,"modAerials":-1,"modDoorSpeaker":4,"wheelSize":0.69999998807907,"driftTyres":false,"lockState":1,"modDoorR":-1,"bulletProofTyres":1,"modHydrolic":-1,"modAirFilter":1,"neonEnabled":[false,false,false,false],"model":-1582061455,"livery":-1,"modStruts":4,"tyres":[],"modArmor":3}', '89KYG626', NULL, 'Garagem Bay City', 20, 1000, 910, 1, 0, NULL, NULL, NULL, '[{"name":"carkey_temp","count":1,"slot":1,"metadata":{"modelo":"89KYG626","code":"509073RYT872709","label":"Modelo: 89KYG626\\nPlaca: 89KYG626\\nSerial: 509073RYT872709","plate":"89KYG626","barcode":"509073RYT872709"}},{"name":"carkey_temp","count":1,"slot":6,"metadata":{"modelo":"66LRM325","code":"405851XXU496309","label":"Modelo: 66LRM325\\nPlaca: 66LRM325\\nSerial: 405851XXU496309","plate":"66LRM325","barcode":"405851XXU496309"}}]', NULL, 9.04415, 0, 0, 0, 0, NULL, '[{"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0}]', '{"y":-1674.8145751953126,"x":-1044.3143310546876,"h":186.40133666992188,"z":3.89958333969116}'),
(66, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'jester4', '-1582061455', '{"modEngineBlock":1,"tyreSmokeColor":[255,255,255],"modXenon":false,"modHorns":2,"modSmokeEnabled":false,"wheels":1,"modDial":-1,"modTank":2,"modLivery":6,"extras":[],"modDoorSpeaker":1,"modFrontWheels":1,"color2":[255,0,0],"wheelSize":0.69999998807907,"modDoorR":-1,"modRoofLivery":-1,"modArchCover":2,"modBackWheels":-1,"windowTint":-1,"modEngine":3,"modStruts":1,"modDashboard":3,"modOrnaments":-1,"modVanityPlate":-1,"interiorColor":27,"windows":[4,5],"dirtLevel":0,"tankHealth":999,"paintType2":7,"modSpoilers":-1,"modSubwoofer":1,"modHydrolic":-1,"modHood":4,"bulletProofTyres":1,"modNitrous":-1,"modPlateHolder":-1,"xenonColor":255,"neonEnabled":[false,false,false,false],"driftTyres":false,"neonColor":[255,0,255],"modExhaust":1,"plateIndex":0,"modShifterLeavers":-1,"modTransmission":1,"modTrimA":4,"modSeats":1,"modTurbo":1,"modBrakes":1,"wheelColor":134,"modFender":1,"modAPlate":-1,"modWindows":-1,"oilLevel":5,"modSuspension":3,"modAerials":-1,"model":-1582061455,"paintType1":7,"dashboardColor":156,"modSideSkirt":2,"modTrunk":-1,"plate":"45YRP591","modSpeakers":-1,"modRoof":3,"bodyHealth":976,"modTrimB":1,"lockState":1,"engineHealth":1000,"fuelLevel":40,"modGrille":1,"modArmor":4,"modSteeringWheel":4,"modCustomTiresR":false,"tyres":[],"modHydraulics":1,"livery":-1,"modRearBumper":1,"modRightFender":4,"modCustomTiresF":false,"pearlescentColor":5,"wheelWidth":0.59910613298416,"doors":[],"modFrontBumper":1,"modAirFilter":2,"color1":[0,0,0],"modLightbar":-1,"modFrame":3}', '45YRP591', NULL, 'Tribunal Parking', 40, 1000, 976, 1, 0, NULL, NULL, NULL, NULL, NULL, 10.9, 0, 0, 0, 0, NULL, '[{"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0}]', '{"x":241.54733276367188,"y":-371.218505859375,"z":43.67035293579101,"h":252.3243865966797}'),
(67, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'jester4', '-1582061455', '{"modRoofLivery":-1,"modBrakes":-1,"bulletProofTyres":true,"modDoorSpeaker":-1,"modSpeakers":-1,"modRearBumper":-1,"modDoorR":-1,"interiorColor":27,"modFrame":-1,"modOrnaments":-1,"modGrille":-1,"modFrontBumper":-1,"modHydraulics":false,"modDashboard":-1,"pearlescentColor":111,"wheelWidth":0.0,"neonColor":[255,0,255],"modVanityPlate":-1,"modCustomTiresF":false,"modTrimA":-1,"modHorns":-1,"modWindows":-1,"modTank":-1,"modSteeringWheel":-1,"dashboardColor":156,"driftTyres":false,"doors":[],"engineHealth":1000,"neonEnabled":[false,false,false,false],"windowTint":-1,"tyres":[],"modEngine":-1,"dirtLevel":2,"modCustomTiresR":false,"modSideSkirt":-1,"modRoof":-1,"modLightbar":-1,"modEngineBlock":-1,"color1":112,"modHood":-1,"modAerials":-1,"modLivery":-1,"wheels":1,"xenonColor":255,"tyreSmokeColor":[255,255,255],"modArmor":-1,"modTrimB":-1,"paintType2":0,"windows":[4,5],"modAPlate":-1,"modSeats":-1,"model":-1582061455,"modStruts":-1,"modFrontWheels":-1,"modShifterLeavers":-1,"wheelSize":0.0,"modSubwoofer":-1,"modSmokeEnabled":false,"modDial":-1,"modAirFilter":-1,"modNitrous":-1,"modFender":-1,"modTransmission":-1,"oilLevel":5,"modSpoilers":-1,"modPlateHolder":-1,"modArchCover":-1,"modRightFender":-1,"modSuspension":-1,"bodyHealth":1000,"wheelColor":88,"livery":-1,"plateIndex":0,"modBackWheels":-1,"modTurbo":false,"modExhaust":-1,"paintType1":0,"modXenon":false,"plate":"09QZC287","extras":[],"modHydrolic":-1,"color2":0,"fuelLevel":65,"lockState":1,"modTrunk":-1,"tankHealth":1000}', '09QZC287', NULL, 'Motel Parking', 64, 1000, 1000, 0, 0, NULL, NULL, NULL, '[{"name":"carkey_temp","count":1,"slot":1,"metadata":{"modelo":"45YRP591","code":"116465UHH188576","label":"Modelo: 45YRP591\\nPlaca: 45YRP591\\nSerial: 116465UHH188576","plate":"45YRP591","barcode":"116465UHH188576"}},{"name":"carkey_temp","count":1,"slot":6,"metadata":{"modelo":"09QZC287","code":"901612IIQ391792","label":"Modelo: 09QZC287\\nPlaca: 09QZC287\\nSerial: 901612IIQ391792","plate":"09QZC287","barcode":"901612IIQ391792"}}]', NULL, 0, 0, 0, 0, 0, NULL, '[{"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0}]', NULL),
(68, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'jester4', '-1582061455', '{"modFrontWheels":-1,"bulletProofTyres":1,"bodyHealth":994,"neonEnabled":[false,false,false,false],"modArchCover":-1,"modWindows":-1,"modFender":-1,"color2":0,"wheelColor":88,"modFrame":-1,"modArmor":-1,"paintType1":7,"pearlescentColor":111,"modLivery":-1,"modDoorR":-1,"modNitrous":-1,"modBackWheels":-1,"wheels":1,"fuelLevel":64,"modOrnaments":-1,"modTransmission":-1,"modDoorSpeaker":-1,"modGrille":-1,"modBrakes":-1,"modHydraulics":false,"wheelWidth":1.0,"xenonColor":255,"modAerials":-1,"modRoofLivery":-1,"modXenon":false,"modAPlate":-1,"modRearBumper":-1,"modTank":-1,"wheelSize":1.0,"modSmokeEnabled":false,"modAirFilter":-1,"modCustomTiresF":false,"modSideSkirt":-1,"modDashboard":-1,"neonColor":[255,0,255],"tankHealth":1000,"livery":-1,"model":-1582061455,"modStruts":-1,"modEngine":-1,"oilLevel":5,"modPlateHolder":-1,"plate":"86IDP629","dashboardColor":156,"extras":[],"tyreSmokeColor":[255,255,255],"color1":112,"modFrontBumper":-1,"modShifterLeavers":-1,"modRightFender":-1,"paintType2":7,"modDial":-1,"modEngineBlock":-1,"modRoof":-1,"modSubwoofer":false,"interiorColor":27,"modExhaust":-1,"engineHealth":1000,"modSeats":-1,"modCustomTiresR":false,"modSpeakers":-1,"modSuspension":-1,"modVanityPlate":-1,"modSpoilers":-1,"windowTint":-1,"modHorns":-1,"modTurbo":false,"driftTyres":false,"dirtLevel":0,"windows":[4,5],"modTrunk":-1,"modSteeringWheel":-1,"modHood":-1,"modTrimB":-1,"doors":[],"plateIndex":0,"tyres":[],"modHydrolic":-1,"modLightbar":-1,"modTrimA":-1,"lockState":1}', '86IDP629', NULL, 'Garagem Algonquin Boulevard #10', 64, 1000, 994, 1, 0, NULL, NULL, NULL, NULL, NULL, 7.4481, 0, 0, 0, 0, NULL, '[{"damage":0.0,"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.0}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":2.35999989509582,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":2.35999989509582,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.0}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.0}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":1.17999994754791,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":1.17999994754791,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.0}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":0.0,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":0.0,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.0}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":-1.17999994754791,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-1.17999994754791,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.0}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.0}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":-2.35999989509582,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-2.35999989509582,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.0}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604}}]', '{"y":3759.364013671875,"z":33.03298568725586,"h":173.8017120361328,"x":1784.322021484375}'),
(69, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'sultanrs', '-295689028', '{"modSubwoofer":false,"modArmor":-1,"modSpoilers":-1,"modRoofLivery":-1,"modStruts":-1,"modTrimA":-1,"wheelWidth":1.0,"modShifterLeavers":-1,"windowTint":-1,"modSpeakers":-1,"modXenon":false,"modEngine":-1,"plate":"41LGZ479","plateIndex":0,"wheels":0,"paintType1":7,"modCustomTiresR":false,"windows":[4,5],"modTank":-1,"modWindows":-1,"pearlescentColor":70,"modTurbo":false,"tyreSmokeColor":[255,255,255],"modTrunk":-1,"neonEnabled":[false,false,false,false],"modAerials":-1,"modSuspension":-1,"neonColor":[255,0,255],"modSideSkirt":-1,"modAirFilter":-1,"interiorColor":31,"modTransmission":-1,"modTrimB":-1,"modBackWheels":-1,"dirtLevel":0,"modLightbar":-1,"oilLevel":5,"wheelSize":1.0,"doors":[],"modVanityPlate":-1,"tyres":[],"fuelLevel":49,"modBrakes":-1,"modSmokeEnabled":false,"modRoof":-1,"modHorns":-1,"modHydraulics":false,"modFrontWheels":-1,"modDial":-1,"driftTyres":false,"color1":64,"modSeats":-1,"modRightFender":-1,"modHydrolic":-1,"lockState":1,"modRearBumper":-1,"livery":-1,"wheelColor":158,"model":-295689028,"paintType2":7,"modHood":-1,"modSteeringWheel":-1,"modOrnaments":-1,"modFrame":-1,"dashboardColor":134,"modNitrous":-1,"bulletProofTyres":1,"tankHealth":1000,"modFrontBumper":-1,"modAPlate":-1,"extras":[],"modFender":-1,"modDoorSpeaker":-1,"modDoorR":-1,"bodyHealth":1000,"modLivery":-1,"color2":64,"xenonColor":255,"modEngineBlock":-1,"modDashboard":-1,"modCustomTiresF":false,"modArchCover":-1,"modExhaust":-1,"engineHealth":1000,"modPlateHolder":-1,"modGrille":-1}', '41LGZ479', NULL, 'Motel Parking', 48, 1000, 1000, 0, 0, NULL, NULL, NULL, '[{"metadata":{"plate":"41LGZ479","barcode":"687310ZJA659331","label":"Modelo: 41LGZ479\\nPlaca: 41LGZ479\\nSerial: 687310ZJA659331","code":"687310ZJA659331","modelo":"41LGZ479"},"name":"carkey_temp","slot":1,"count":1}]', NULL, 2.94831, 0, 0, 0, 0, NULL, '[{"damage":0.0,"offset":{"x":-0.98000001907348,"y":2.4300000667572,"z":0.0}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":2.4300000667572,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.0,"y":2.4300000667572,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":2.4300000667572,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":2.4300000667572,"z":0.0}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":2.4300000667572,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":1.21000003814697,"z":0.0}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":1.21000003814697,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.0,"y":1.21000003814697,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":1.21000003814697,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":1.21000003814697,"z":0.0}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":1.21000003814697,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":0.0,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":0.0,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":-1.21000003814697,"z":0.0}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":-1.21000003814697,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.0,"y":-1.21000003814697,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-1.21000003814697,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":-1.21000003814697,"z":0.0}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":-1.21000003814697,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":-2.4300000667572,"z":0.0}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":-2.4300000667572,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.0,"y":-2.4300000667572,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-2.4300000667572,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":-2.4300000667572,"z":0.0}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":-2.4300000667572,"z":0.75999999046325}}]', NULL),
(70, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'jester4', '-1582061455', '{"tankHealth":996,"modShifterLeavers":-1,"modTransmission":-1,"modTank":2,"modPlateHolder":-1,"modOrnaments":-1,"modWindows":-1,"plate":"29SEZ734","modDashboard":3,"modDoorR":-1,"dashboardColor":156,"modFrontBumper":1,"modSubwoofer":1,"modRoofLivery":-1,"modRightFender":3,"neonEnabled":[false,false,false,false],"modNitrous":-1,"modTurbo":1,"modSuspension":2,"modBrakes":-1,"modArmor":2,"modLightbar":-1,"oilLevel":5,"modSeats":2,"wheelColor":134,"xenonColor":255,"engineHealth":1000,"tyres":[],"windows":[4,5],"paintType2":7,"color1":[0,0,0],"modHydrolic":-1,"lockState":1,"modFrame":3,"color2":[255,0,0],"modEngineBlock":2,"modCustomTiresF":1,"modTrunk":-1,"modHydraulics":1,"modAirFilter":2,"modFender":-1,"modTrimA":1,"driftTyres":false,"pearlescentColor":5,"modSideSkirt":4,"modTrimB":-1,"modSpeakers":-1,"bulletProofTyres":1,"modDial":2,"modDoorSpeaker":3,"extras":[],"modAerials":-1,"modRearBumper":4,"modStruts":1,"modSpoilers":-1,"modHorns":3,"modGrille":3,"livery":-1,"modArchCover":1,"interiorColor":27,"modEngine":1,"modXenon":false,"dirtLevel":1,"modSteeringWheel":2,"modVanityPlate":-1,"modCustomTiresR":false,"modLivery":4,"modBackWheels":-1,"modExhaust":4,"wheelSize":0.69999998807907,"modHood":3,"modAPlate":-1,"tyreSmokeColor":[255,255,255],"modSmokeEnabled":false,"neonColor":[255,0,255],"windowTint":-1,"model":-1582061455,"modFrontWheels":3,"modRoof":2,"bodyHealth":954,"paintType1":7,"doors":[],"wheelWidth":0.59616547822952,"fuelLevel":22,"plateIndex":0,"wheels":1}', '29SEZ734', NULL, 'Casino Garage IPL', 22, 1000, 953, 1, 0, NULL, NULL, NULL, NULL, NULL, 8.09476, 0, 0, 0, 0, NULL, '[{"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":2.35999989509582,"z":0.0},"damage":0.022},{"offset":{"x":0.0,"y":2.35999989509582,"z":0.66000002622604},"damage":0.01},{"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.0},"damage":0.005},{"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.66000002622604},"damage":0.002},{"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":1.17999994754791,"z":0.0},"damage":0.009},{"offset":{"x":0.0,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0}]', '{"z":-65.35404205322266,"h":203.88595581054688,"x":2524.648681640625,"y":-270.23736572265627}'),
(71, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'sultanrs', '-295689028', '{"neonColor":[255,0,255],"modTrunk":-1,"modArchCover":3,"modHorns":2,"modLivery":-1,"modTrimB":-1,"fuelLevel":45,"modSuspension":2,"interiorColor":31,"xenonColor":255,"modAerials":-1,"modCustomTiresR":false,"modBrakes":1,"modCustomTiresF":false,"windows":[4,5],"modStruts":3,"plateIndex":0,"model":-295689028,"modTurbo":1,"modBackWheels":-1,"tyres":[],"modFrontWheels":4,"modAPlate":-1,"modEngine":2,"modHydrolic":-1,"modTrimA":-1,"modSteeringWheel":4,"pearlescentColor":70,"modDashboard":1,"modDoorSpeaker":3,"dirtLevel":1,"color2":64,"wheelWidth":0.5913336277008,"modHood":3,"extras":[],"wheels":0,"engineHealth":999,"modRearBumper":1,"modGrille":2,"modSpoilers":-1,"modSideSkirt":-1,"modRightFender":-1,"modFrame":3,"color1":64,"modNitrous":-1,"modRoof":1,"modSmokeEnabled":false,"modSeats":2,"paintType1":7,"modVanityPlate":-1,"modEngineBlock":3,"driftTyres":false,"wheelColor":158,"modRoofLivery":-1,"modOrnaments":3,"plate":"63AVE439","tankHealth":999,"tyreSmokeColor":[255,255,255],"modXenon":false,"modAirFilter":1,"dashboardColor":134,"modSpeakers":-1,"modDial":1,"windowTint":-1,"modFrontBumper":1,"wheelSize":0.64839601516723,"neonEnabled":[false,false,false,false],"bulletProofTyres":1,"modPlateHolder":-1,"modExhaust":2,"oilLevel":5,"modDoorR":-1,"modLightbar":-1,"bodyHealth":997,"modSubwoofer":1,"modArmor":3,"modHydraulics":1,"doors":[],"modShifterLeavers":-1,"modTransmission":1,"lockState":1,"paintType2":7,"livery":-1,"modTank":-1,"modWindows":1,"modFender":2}', '63AVE439', NULL, 'Casa do Michael', 45, 999, 996, 1, 0, NULL, NULL, NULL, NULL, NULL, 7.63248, 0, 0, 0, 0, NULL, '[{"damage":0.003,"offset":{"x":-0.98000001907348,"y":2.4300000667572,"z":0.0}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":2.4300000667572,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.0,"y":2.4300000667572,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":2.4300000667572,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":2.4300000667572,"z":0.0}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":2.4300000667572,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":1.21000003814697,"z":0.0}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":1.21000003814697,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.0,"y":1.21000003814697,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":1.21000003814697,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":1.21000003814697,"z":0.0}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":1.21000003814697,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":0.0,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":0.0,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":-1.21000003814697,"z":0.0}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":-1.21000003814697,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.0,"y":-1.21000003814697,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-1.21000003814697,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":-1.21000003814697,"z":0.0}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":-1.21000003814697,"z":0.75999999046325}},{"damage":0.001,"offset":{"x":-0.98000001907348,"y":-2.4300000667572,"z":0.0}},{"damage":0.0,"offset":{"x":-0.98000001907348,"y":-2.4300000667572,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.0,"y":-2.4300000667572,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-2.4300000667572,"z":0.75999999046325}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":-2.4300000667572,"z":0.0}},{"damage":0.0,"offset":{"x":0.98000001907348,"y":-2.4300000667572,"z":0.75999999046325}}]', '{"x":-829.2400512695313,"y":172.7996063232422,"z":69.84501647949219,"h":333.56781005859377}'),
(72, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'jester4', '-1582061455', '{"paintType1":0,"color2":36,"livery":-1,"modDial":-1,"fuelLevel":65,"modXenon":false,"modPlateHolder":-1,"modRoof":-1,"modWindows":-1,"modFrontBumper":-1,"modAirFilter":-1,"xenonColor":255,"extras":[],"tankHealth":1000,"modHydrolic":-1,"modHorns":-1,"modSuspension":-1,"modSubwoofer":false,"modOrnaments":-1,"wheelColor":134,"modRightFender":-1,"modTransmission":-1,"modFrame":-1,"modBrakes":-1,"modFender":-1,"dashboardColor":156,"interiorColor":27,"neonEnabled":[false,false,false,false],"modTank":-1,"modCustomTiresR":false,"modLivery":-1,"paintType2":0,"bodyHealth":1000,"modTrunk":-1,"color1":20,"driftTyres":false,"modSeats":-1,"windows":[4,5],"modGrille":-1,"modSpoilers":-1,"modVanityPlate":-1,"windowTint":-1,"modAPlate":-1,"modRearBumper":-1,"model":-1582061455,"modStruts":-1,"modTrimA":-1,"plate":"04UKY513","modNitrous":-1,"modCustomTiresF":false,"modTurbo":false,"wheels":1,"modDashboard":-1,"tyreSmokeColor":[255,255,255],"modEngine":-1,"pearlescentColor":5,"wheelSize":0.0,"modEngineBlock":-1,"plateIndex":0,"modArchCover":-1,"neonColor":[255,0,255],"modDoorSpeaker":-1,"lockState":1,"modSmokeEnabled":false,"modSideSkirt":-1,"modArmor":-1,"oilLevel":5,"wheelWidth":0.0,"engineHealth":1000,"modAerials":-1,"modBackWheels":-1,"modSteeringWheel":-1,"modShifterLeavers":-1,"modRoofLivery":-1,"bulletProofTyres":1,"modHydraulics":false,"modDoorR":-1,"modSpeakers":-1,"doors":[],"modTrimB":-1,"modFrontWheels":-1,"modLightbar":-1,"modExhaust":-1,"dirtLevel":7,"tyres":[],"modHood":-1}', '04UKY513', NULL, 'Motel Parking', 64, 1000, 1000, 0, 0, NULL, NULL, NULL, NULL, NULL, 34.4599, 0, 0, 0, 0, NULL, '[{"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":0.0,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.0,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.0},"damage":0.0},{"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604},"damage":0.0}]', NULL),
(73, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'jester4', '-1582061455', '{"modSubwoofer":false,"modArmor":-1,"modSpoilers":-1,"modRoofLivery":-1,"modStruts":-1,"modTrimA":-1,"wheelWidth":0.0,"modShifterLeavers":-1,"windowTint":-1,"modSpeakers":-1,"modXenon":false,"modEngine":-1,"plate":"02RRH076","plateIndex":0,"wheels":1,"paintType1":0,"modCustomTiresR":false,"windows":[4,5],"modTank":-1,"modWindows":-1,"pearlescentColor":111,"modTurbo":false,"tyreSmokeColor":[255,255,255],"modTrunk":-1,"neonEnabled":[false,false,false,false],"modAerials":-1,"modSuspension":-1,"neonColor":[255,0,255],"modSideSkirt":-1,"modAirFilter":-1,"interiorColor":27,"modTransmission":-1,"modTrimB":-1,"modBackWheels":-1,"dirtLevel":5,"modLightbar":-1,"oilLevel":5,"wheelSize":0.0,"doors":[],"modVanityPlate":-1,"tyres":[],"fuelLevel":64,"modBrakes":-1,"modSmokeEnabled":false,"modRoof":-1,"modHorns":-1,"modHydraulics":false,"modFrontWheels":-1,"modDial":-1,"driftTyres":false,"color1":112,"modSeats":-1,"modRightFender":-1,"modHydrolic":-1,"lockState":1,"modRearBumper":-1,"livery":-1,"wheelColor":88,"model":-1582061455,"paintType2":0,"modHood":-1,"modSteeringWheel":-1,"modOrnaments":-1,"modFrame":-1,"dashboardColor":156,"modNitrous":-1,"bulletProofTyres":1,"tankHealth":1000,"modFrontBumper":-1,"modAPlate":-1,"extras":[],"modFender":-1,"modDoorSpeaker":-1,"modDoorR":-1,"bodyHealth":1000,"modLivery":-1,"color2":0,"xenonColor":255,"modEngineBlock":-1,"modDashboard":-1,"modCustomTiresF":false,"modArchCover":-1,"modExhaust":-1,"engineHealth":1000,"modPlateHolder":-1,"modGrille":-1}', '02RRH076', NULL, 'Motel Parking', 63, 1000, 1000, 0, 0, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 'Dinka Jester RR', '[{"damage":0.0,"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.0}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":2.35999989509582,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":2.35999989509582,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":2.35999989509582,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.0}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":2.35999989509582,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.0}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":1.17999994754791,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":1.17999994754791,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":1.17999994754791,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.0}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":1.17999994754791,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":0.0,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":0.0,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.0}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":-1.17999994754791,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-1.17999994754791,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.0}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":-1.17999994754791,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.0}},{"damage":0.0,"offset":{"x":-0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":-2.35999989509582,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-2.35999989509582,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.0}},{"damage":0.0,"offset":{"x":0.95999997854232,"y":-2.35999989509582,"z":0.66000002622604}}]', NULL),
(74, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'gauntlet6', '1336514315', '{"modFrontWheels":-1,"model":1336514315,"doors":[],"modTransmission":-1,"paintType2":0,"modDoorR":-1,"windows":[0,1,4,5,7],"modOrnaments":-1,"modRoofLivery":-1,"tyreSmokeColor":[255,255,255],"modTrimB":-1,"modGrille":-1,"oilLevel":5,"wheelWidth":0.0,"wheelSize":0.0,"modFender":-1,"modAerials":-1,"modArchCover":-1,"wheels":1,"modFrame":-1,"bodyHealth":998,"modTank":-1,"bulletProofTyres":1,"modCustomTiresF":false,"windowTint":-1,"modStruts":-1,"extras":[0],"modRearBumper":-1,"modVanityPlate":-1,"modDashboard":-1,"lockState":1,"xenonColor":255,"modLivery":-1,"modSpeakers":-1,"modFrontBumper":-1,"wheelColor":0,"modAirFilter":-1,"modHydraulics":false,"modShifterLeavers":-1,"modLightbar":-1,"modNitrous":-1,"modRightFender":-1,"dirtLevel":0,"modExhaust":-1,"modBackWheels":-1,"modCustomTiresR":false,"driftTyres":false,"modTrimA":-1,"modArmor":-1,"modDial":-1,"modHood":-1,"modWindows":-1,"modSpoilers":-1,"modTrunk":-1,"modHydrolic":-1,"modSteeringWheel":-1,"modEngineBlock":-1,"tyres":[],"modSmokeEnabled":false,"engineHealth":1000,"modAPlate":-1,"modEngine":-1,"color1":29,"dashboardColor":89,"modSubwoofer":false,"plateIndex":0,"modPlateHolder":-1,"paintType1":0,"modSuspension":-1,"plate":"AD848923","modSideSkirt":-1,"fuelLevel":60,"livery":-1,"modBrakes":-1,"neonColor":[255,0,255],"color2":8,"modTurbo":false,"tankHealth":999,"interiorColor":7,"modXenon":false,"modDoorSpeaker":-1,"modHorns":-1,"neonEnabled":[false,false,false,false],"pearlescentColor":5,"modSeats":-1,"modRoof":-1}', 'AD848923', NULL, 'Garagem Bay City', 59, 1000, 997, 1, 0, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, NULL, '[{"damage":0.0,"offset":{"x":-1.00999999046325,"y":2.57999992370605,"z":0.0}},{"damage":0.0,"offset":{"x":-1.00999999046325,"y":2.57999992370605,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":2.57999992370605,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":2.57999992370605,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":1.00999999046325,"y":2.57999992370605,"z":0.0}},{"damage":0.0,"offset":{"x":1.00999999046325,"y":2.57999992370605,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":-1.00999999046325,"y":1.28999996185302,"z":0.0}},{"damage":0.0,"offset":{"x":-1.00999999046325,"y":1.28999996185302,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":1.28999996185302,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":1.28999996185302,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":1.00999999046325,"y":1.28999996185302,"z":0.0}},{"damage":0.0,"offset":{"x":1.00999999046325,"y":1.28999996185302,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":-1.00999999046325,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":-1.00999999046325,"y":0.0,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":1.00999999046325,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":1.00999999046325,"y":0.0,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":-1.00999999046325,"y":-1.28999996185302,"z":0.0}},{"damage":0.0,"offset":{"x":-1.00999999046325,"y":-1.28999996185302,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":-1.28999996185302,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-1.28999996185302,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":1.00999999046325,"y":-1.28999996185302,"z":0.0}},{"damage":0.0,"offset":{"x":1.00999999046325,"y":-1.28999996185302,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":-1.00999999046325,"y":-2.57999992370605,"z":0.0}},{"damage":0.01,"offset":{"x":-1.00999999046325,"y":-2.57999992370605,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":0.0,"y":-2.57999992370605,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-2.57999992370605,"z":0.66000002622604}},{"damage":0.0,"offset":{"x":1.00999999046325,"y":-2.57999992370605,"z":0.0}},{"damage":0.0,"offset":{"x":1.00999999046325,"y":-2.57999992370605,"z":0.66000002622604}}]', '{"z":4.31552934646606,"h":88.37864685058594,"x":-996.9970703125,"y":-1607.6292724609376}'),
(75, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'weevil2', '-994371320', '{"modAirFilter":-1,"modStruts":-1,"neonColor":[255,0,255],"modFender":2,"modHood":4,"modOrnaments":-1,"wheelSize":0.74000000953674,"paintType2":7,"modRoof":3,"fuelLevel":64,"modSpoilers":-1,"wheels":1,"modWindows":2,"modFrame":2,"modExhaust":3,"color1":68,"modSteeringWheel":4,"modSuspension":3,"modHydraulics":1,"extras":[],"lockState":1,"doors":[],"modLightbar":-1,"modGrille":1,"modTrimA":4,"modAerials":2,"dirtLevel":0,"modBrakes":1,"modTrimB":-1,"windowTint":-1,"bodyHealth":1000,"modFrontBumper":2,"modLivery":-1,"xenonColor":255,"modSmokeEnabled":false,"modTrunk":-1,"modCustomTiresR":false,"engineHealth":1000,"modDial":-1,"model":-994371320,"modHydrolic":-1,"modNitrous":-1,"modTank":-1,"plateIndex":0,"modSideSkirt":2,"color2":68,"modHorns":4,"modTurbo":1,"interiorColor":3,"modSubwoofer":1,"modXenon":false,"modArchCover":4,"wheelColor":0,"paintType1":7,"modBackWheels":-1,"modCustomTiresF":false,"modDoorSpeaker":-1,"modVanityPlate":-1,"modRightFender":-1,"neonEnabled":[false,false,false,false],"tyres":[],"modSeats":4,"modSpeakers":-1,"modPlateHolder":-1,"wheelWidth":0.35546964406967,"modRoofLivery":-1,"modTransmission":2,"modFrontWheels":1,"modEngineBlock":-1,"modRearBumper":4,"plate":"AD412822","modAPlate":-1,"driftTyres":false,"livery":-1,"pearlescentColor":6,"modDashboard":-1,"tyreSmokeColor":[255,255,255],"modShifterLeavers":3,"modArmor":1,"oilLevel":5,"bulletProofTyres":1,"dashboardColor":156,"windows":[4,5],"modEngine":3,"tankHealth":1000,"modDoorR":2}', 'AD412822', NULL, 'Garagem Bay City', 64, 1000, 1000, 1, 0, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, NULL, '[{"damage":0.0,"offset":{"x":-1.05999994277954,"y":2.14000010490417,"z":0.0}},{"damage":0.0,"offset":{"x":-1.05999994277954,"y":2.14000010490417,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":0.0,"y":2.14000010490417,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":2.14000010490417,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":1.05999994277954,"y":2.14000010490417,"z":0.0}},{"damage":0.0,"offset":{"x":1.05999994277954,"y":2.14000010490417,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":-1.05999994277954,"y":1.07000005245208,"z":0.0}},{"damage":0.0,"offset":{"x":-1.05999994277954,"y":1.07000005245208,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":0.0,"y":1.07000005245208,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":1.07000005245208,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":1.05999994277954,"y":1.07000005245208,"z":0.0}},{"damage":0.0,"offset":{"x":1.05999994277954,"y":1.07000005245208,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":-1.05999994277954,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":-1.05999994277954,"y":0.0,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":1.05999994277954,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":1.05999994277954,"y":0.0,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":-1.05999994277954,"y":-1.07000005245208,"z":0.0}},{"damage":0.0,"offset":{"x":-1.05999994277954,"y":-1.07000005245208,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":0.0,"y":-1.07000005245208,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-1.07000005245208,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":1.05999994277954,"y":-1.07000005245208,"z":0.0}},{"damage":0.0,"offset":{"x":1.05999994277954,"y":-1.07000005245208,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":-1.05999994277954,"y":-2.14000010490417,"z":0.0}},{"damage":0.0,"offset":{"x":-1.05999994277954,"y":-2.14000010490417,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":0.0,"y":-2.14000010490417,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-2.14000010490417,"z":0.82999998331069}},{"damage":0.0,"offset":{"x":1.05999994277954,"y":-2.14000010490417,"z":0.0}},{"damage":0.0,"offset":{"x":1.05999994277954,"y":-2.14000010490417,"z":0.82999998331069}}]', '{"h":232.1468963623047,"x":-1009.694580078125,"y":-1639.422119140625,"z":3.78171777725219}'),
(76, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'sultanrs', '-295689028', '{"pearlescentColor":70,"modRearBumper":-1,"model":-295689028,"color2":64,"doors":[],"modDashboard":-1,"xenonColor":255,"modXenon":false,"modGrille":-1,"modLightbar":-1,"color1":64,"livery":-1,"modBrakes":-1,"modTank":-1,"paintType1":7,"plate":"22LWH734","modFrontBumper":-1,"modNitrous":-1,"tyreSmokeColor":[255,255,255],"modOrnaments":-1,"modCustomTiresF":false,"modSmokeEnabled":false,"modSideSkirt":-1,"modSuspension":-1,"modDoorSpeaker":-1,"modHydrolic":-1,"modHydraulics":false,"tankHealth":1000,"bodyHealth":1000,"modDial":-1,"modTransmission":-1,"modTrimB":-1,"neonColor":[255,0,255],"plateIndex":0,"interiorColor":31,"modLivery":-1,"modSeats":-1,"wheelColor":158,"modTrimA":-1,"modRoof":-1,"modEngineBlock":-1,"modAerials":-1,"lockState":1,"modHood":-1,"modSteeringWheel":-1,"paintType2":7,"dashboardColor":134,"neonEnabled":[false,false,false,false],"modDoorR":-1,"modFrontWheels":-1,"modEngine":-1,"windows":[4,5],"modShifterLeavers":-1,"modFrame":-1,"modTrunk":-1,"dirtLevel":0,"modAPlate":-1,"wheelSize":1.0,"modArmor":-1,"modFender":-1,"driftTyres":false,"modTurbo":false,"modSpoilers":-1,"windowTint":-1,"modHorns":-1,"modSpeakers":-1,"modCustomTiresR":false,"extras":[],"modSubwoofer":false,"engineHealth":1000,"modWindows":-1,"modBackWheels":-1,"modArchCover":-1,"modRightFender":-1,"wheels":0,"modStruts":-1,"modExhaust":-1,"modVanityPlate":-1,"tyres":[],"modRoofLivery":-1,"bulletProofTyres":1,"oilLevel":5,"modPlateHolder":-1,"modAirFilter":-1,"wheelWidth":1.0,"fuelLevel":64}', '22LWH734', NULL, 'Garagem Bay City', 64, 1000, 1000, 1, 0, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, NULL, '[{"offset":{"x":-0.98000001907348,"y":2.4300000667572,"z":0.0},"damage":0.0},{"offset":{"x":-0.98000001907348,"y":2.4300000667572,"z":0.75999999046325},"damage":0.0},{"offset":{"x":0.0,"y":2.4300000667572,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":2.4300000667572,"z":0.75999999046325},"damage":0.0},{"offset":{"x":0.98000001907348,"y":2.4300000667572,"z":0.0},"damage":0.0},{"offset":{"x":0.98000001907348,"y":2.4300000667572,"z":0.75999999046325},"damage":0.0},{"offset":{"x":-0.98000001907348,"y":1.21000003814697,"z":0.0},"damage":0.0},{"offset":{"x":-0.98000001907348,"y":1.21000003814697,"z":0.75999999046325},"damage":0.0},{"offset":{"x":0.0,"y":1.21000003814697,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":1.21000003814697,"z":0.75999999046325},"damage":0.0},{"offset":{"x":0.98000001907348,"y":1.21000003814697,"z":0.0},"damage":0.0},{"offset":{"x":0.98000001907348,"y":1.21000003814697,"z":0.75999999046325},"damage":0.0},{"offset":{"x":-0.98000001907348,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":-0.98000001907348,"y":0.0,"z":0.75999999046325},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.75999999046325},"damage":0.0},{"offset":{"x":0.98000001907348,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.98000001907348,"y":0.0,"z":0.75999999046325},"damage":0.0},{"offset":{"x":-0.98000001907348,"y":-1.21000003814697,"z":0.0},"damage":0.0},{"offset":{"x":-0.98000001907348,"y":-1.21000003814697,"z":0.75999999046325},"damage":0.0},{"offset":{"x":0.0,"y":-1.21000003814697,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-1.21000003814697,"z":0.75999999046325},"damage":0.0},{"offset":{"x":0.98000001907348,"y":-1.21000003814697,"z":0.0},"damage":0.0},{"offset":{"x":0.98000001907348,"y":-1.21000003814697,"z":0.75999999046325},"damage":0.0},{"offset":{"x":-0.98000001907348,"y":-2.4300000667572,"z":0.0},"damage":0.0},{"offset":{"x":-0.98000001907348,"y":-2.4300000667572,"z":0.75999999046325},"damage":0.0},{"offset":{"x":0.0,"y":-2.4300000667572,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-2.4300000667572,"z":0.75999999046325},"damage":0.0},{"offset":{"x":0.98000001907348,"y":-2.4300000667572,"z":0.0},"damage":0.0},{"offset":{"x":0.98000001907348,"y":-2.4300000667572,"z":0.75999999046325},"damage":0.0}]', '{"x":-998.8012084960938,"h":262.24395751953127,"z":4.31073904037475,"y":-1611.4718017578126}'),
(77, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'avarus', '-2115793025', '{"modNitrous":-1,"modSmokeEnabled":false,"wheelWidth":0.43999999761581,"interiorColor":111,"modTrimA":-1,"doors":[],"modDial":-1,"modLivery":-1,"modOrnaments":-1,"modSubwoofer":1,"modLightbar":-1,"modRearBumper":1,"modCustomTiresR":1,"xenonColor":255,"modRightFender":-1,"modAPlate":-1,"modAirFilter":-1,"modArmor":4,"paintType1":7,"modHood":-1,"modSeats":-1,"windowTint":-1,"plateIndex":0,"modAerials":-1,"modFrontBumper":-1,"wheelSize":0.5900000333786,"modPlateHolder":-1,"modDoorSpeaker":-1,"dashboardColor":111,"modHorns":4,"driftTyres":false,"neonEnabled":[false,false,false,false],"modFender":-1,"modSuspension":-1,"paintType2":7,"modTurbo":1,"modSteeringWheel":-1,"modBackWheels":3,"extras":[],"modEngineBlock":-1,"modRoofLivery":-1,"bulletProofTyres":1,"oilLevel":5,"lockState":1,"fuelLevel":64,"bodyHealth":1000,"modXenon":false,"modDoorR":-1,"modSpeakers":-1,"windows":[0,1,2,3,4,5,6,7],"neonColor":[255,0,255],"modTrunk":-1,"modHydraulics":1,"modHydrolic":-1,"modExhaust":-1,"modSpoilers":-1,"modSideSkirt":2,"modFrontWheels":1,"pearlescentColor":2,"modFrame":2,"wheels":6,"modTransmission":-1,"wheelColor":111,"modCustomTiresF":1,"modWindows":-1,"modStruts":-1,"modRoof":4,"modEngine":2,"tankHealth":1000,"dirtLevel":1,"modVanityPlate":-1,"color2":142,"model":-2115793025,"modShifterLeavers":-1,"modGrille":-1,"modTank":-1,"engineHealth":1000,"modBrakes":2,"plate":"AD087784","tyreSmokeColor":[255,255,255],"livery":-1,"modTrimB":-1,"color1":145,"tyres":[],"modArchCover":-1,"modDashboard":-1}', 'AD087784', NULL, 'Garagem Bay City', 63, 1000, 1000, 1, 0, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, NULL, '[{"damage":0.0,"offset":{"x":-0.44999998807907,"y":1.22000002861022,"z":0.0}},{"damage":0.0,"offset":{"x":-0.44999998807907,"y":1.22000002861022,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":0.0,"y":1.22000002861022,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":1.22000002861022,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":0.44999998807907,"y":1.22000002861022,"z":0.0}},{"damage":0.0,"offset":{"x":0.44999998807907,"y":1.22000002861022,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":-0.44999998807907,"y":0.61000001430511,"z":0.0}},{"damage":0.0,"offset":{"x":-0.44999998807907,"y":0.61000001430511,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":0.0,"y":0.61000001430511,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":0.61000001430511,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":0.44999998807907,"y":0.61000001430511,"z":0.0}},{"damage":0.0,"offset":{"x":0.44999998807907,"y":0.61000001430511,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":-0.44999998807907,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":-0.44999998807907,"y":0.0,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":0.44999998807907,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.44999998807907,"y":0.0,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":-0.44999998807907,"y":-0.61000001430511,"z":0.0}},{"damage":0.0,"offset":{"x":-0.44999998807907,"y":-0.61000001430511,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":0.0,"y":-0.61000001430511,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-0.61000001430511,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":0.44999998807907,"y":-0.61000001430511,"z":0.0}},{"damage":0.0,"offset":{"x":0.44999998807907,"y":-0.61000001430511,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":-0.44999998807907,"y":-1.22000002861022,"z":0.0}},{"damage":0.0,"offset":{"x":-0.44999998807907,"y":-1.22000002861022,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":0.0,"y":-1.22000002861022,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-1.22000002861022,"z":0.76999998092651}},{"damage":0.0,"offset":{"x":0.44999998807907,"y":-1.22000002861022,"z":0.0}},{"damage":0.0,"offset":{"x":0.44999998807907,"y":-1.22000002861022,"z":0.76999998092651}}]', '{"z":3.99808478355407,"h":4.02358102798461,"x":-1049.14990234375,"y":-1679.29345703125}'),
(78, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'RE036OYR', 'coureur', '610429990', '{"modAerials":-1,"extras":[0],"neonEnabled":[false,false,false,false],"modFrontWheels":-1,"modAPlate":-1,"modXenon":false,"modBackWheels":-1,"modStruts":-1,"modRearBumper":-1,"modSmokeEnabled":false,"modTrunk":-1,"modFender":-1,"modArmor":-1,"modFrontBumper":-1,"windows":[4,5],"paintType2":0,"windowTint":-1,"modEngine":-1,"modSpeakers":-1,"modTank":-1,"modHydrolic":-1,"plate":"AD647471","livery":-1,"lockState":1,"tankHealth":1000,"modSubwoofer":false,"modDoorR":-1,"modVanityPlate":-1,"modShifterLeavers":-1,"wheelColor":0,"modSteeringWheel":-1,"modHydraulics":false,"interiorColor":93,"modLivery":-1,"modCustomTiresR":false,"model":610429990,"color2":27,"modRoof":-1,"driftTyres":false,"modRoofLivery":-1,"modSeats":-1,"engineHealth":1000,"dirtLevel":7,"fuelLevel":59,"modOrnaments":-1,"modSuspension":-1,"wheels":7,"tyreSmokeColor":[255,255,255],"modExhaust":-1,"dashboardColor":134,"modTrimB":-1,"modTurbo":false,"modNitrous":-1,"modPlateHolder":-1,"wheelSize":0.0,"modSpoilers":-1,"modHood":-1,"modHorns":-1,"doors":[],"modAirFilter":-1,"plateIndex":0,"modFrame":-1,"color1":27,"xenonColor":255,"tyres":[],"paintType1":0,"modCustomTiresF":false,"modWindows":-1,"modRightFender":-1,"modGrille":-1,"modSideSkirt":-1,"bulletProofTyres":1,"wheelWidth":0.0,"modBrakes":-1,"modEngineBlock":-1,"modLightbar":-1,"bodyHealth":1000,"modDashboard":-1,"oilLevel":5,"modTransmission":-1,"modArchCover":-1,"modDial":-1,"modDoorSpeaker":-1,"modTrimA":-1,"neonColor":[255,0,255],"pearlescentColor":28}', 'AD647471', NULL, 'Palomino Avenue Detran', 58, 1000, 1000, 1, 0, NULL, NULL, NULL, NULL, NULL, 2, 0, 0, 0, 0, NULL, '[{"offset":{"x":-1.11000001430511,"y":2.19000005722045,"z":0.0},"damage":0.0},{"offset":{"x":-1.11000001430511,"y":2.19000005722045,"z":0.82999998331069},"damage":0.0},{"offset":{"x":0.0,"y":2.19000005722045,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":2.19000005722045,"z":0.82999998331069},"damage":0.0},{"offset":{"x":1.11000001430511,"y":2.19000005722045,"z":0.0},"damage":0.0},{"offset":{"x":1.11000001430511,"y":2.19000005722045,"z":0.82999998331069},"damage":0.0},{"offset":{"x":-1.11000001430511,"y":1.0900000333786,"z":0.0},"damage":0.0},{"offset":{"x":-1.11000001430511,"y":1.0900000333786,"z":0.82999998331069},"damage":0.0},{"offset":{"x":0.0,"y":1.0900000333786,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":1.0900000333786,"z":0.82999998331069},"damage":0.0},{"offset":{"x":1.11000001430511,"y":1.0900000333786,"z":0.0},"damage":0.0},{"offset":{"x":1.11000001430511,"y":1.0900000333786,"z":0.82999998331069},"damage":0.0},{"offset":{"x":-1.11000001430511,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":-1.11000001430511,"y":0.0,"z":0.82999998331069},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":0.0,"z":0.82999998331069},"damage":0.0},{"offset":{"x":1.11000001430511,"y":0.0,"z":0.0},"damage":0.0},{"offset":{"x":1.11000001430511,"y":0.0,"z":0.82999998331069},"damage":0.0},{"offset":{"x":-1.11000001430511,"y":-1.0900000333786,"z":0.0},"damage":0.0},{"offset":{"x":-1.11000001430511,"y":-1.0900000333786,"z":0.82999998331069},"damage":0.0},{"offset":{"x":0.0,"y":-1.0900000333786,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-1.0900000333786,"z":0.82999998331069},"damage":0.0},{"offset":{"x":1.11000001430511,"y":-1.0900000333786,"z":0.0},"damage":0.0},{"offset":{"x":1.11000001430511,"y":-1.0900000333786,"z":0.82999998331069},"damage":0.0},{"offset":{"x":-1.11000001430511,"y":-2.19000005722045,"z":0.0},"damage":0.0},{"offset":{"x":-1.11000001430511,"y":-2.19000005722045,"z":0.82999998331069},"damage":0.0},{"offset":{"x":0.0,"y":-2.19000005722045,"z":0.0},"damage":0.0},{"offset":{"x":0.0,"y":-2.19000005722045,"z":0.82999998331069},"damage":0.0},{"offset":{"x":1.11000001430511,"y":-2.19000005722045,"z":0.0},"damage":0.0},{"offset":{"x":1.11000001430511,"y":-2.19000005722045,"z":0.82999998331069},"damage":0.0}]', '{"x":-1080.842041015625,"h":117.90214538574219,"z":4.87877607345581,"y":-1258.3055419921876}');

-- Structure for `players`
DROP TABLE IF EXISTS `players`;
CREATE TABLE `players` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userId` int(10) unsigned DEFAULT NULL,
  `citizenid` varchar(50) NOT NULL,
  `cid` int(11) DEFAULT NULL,
  `license` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `money` text NOT NULL,
  `charinfo` text DEFAULT NULL,
  `job` text NOT NULL,
  `gang` text DEFAULT NULL,
  `position` text NOT NULL,
  `metadata` text NOT NULL,
  `inventory` longtext DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `last_logged_out` timestamp NULL DEFAULT NULL,
  `last_property` varchar(255) DEFAULT NULL,
  `skills` longtext DEFAULT NULL,
  PRIMARY KEY (`citizenid`),
  KEY `id` (`id`),
  KEY `last_updated` (`last_updated`),
  KEY `license` (`license`)
) ENGINE=InnoDB AUTO_INCREMENT=7408 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Data for `players`
INSERT INTO `players` (`id`, `userId`, `citizenid`, `cid`, `license`, `name`, `money`, `charinfo`, `job`, `gang`, `position`, `metadata`, `inventory`, `phone_number`, `last_updated`, `last_logged_out`, `last_property`, `skills`) VALUES
(7120, 2, 'M6YW58XY', 2, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'SharpFish5162', '{"bank":5000,"crypto":0,"cash":500}', '{"lastname":"Dev","firstname":"Player","gender":1,"account":"US07QBX5717405454","nationality":"American","phone":"4842521852","birthdate":"2006-12-30","cid":2,"backstory":"placeholder backstory"}', '{"name":"unemployed","payment":10,"grade":{"level":0,"name":"Freelancer"},"isboss":false,"bankAuth":false,"label":"Civilian","onduty":true}', '{"name":"none","grade":{"level":0,"name":"Unaffiliated"},"isboss":false,"label":"No Gang","bankAuth":false}', '{"x":5.24835205078125,"y":-547.8461303710938,"z":37.5867919921875,"w":96.37794494628906}', '{"oxygen":100,"licences":{"driver":true,"id":true,"weapon":false},"status":[],"attachmentcraftingrep":0,"bloodtype":"B+","phone":[],"dealerrep":0,"phonedata":{"SerialNumber":82949491,"InstalledApps":[]},"inside":{"apartment":[]},"injail":0,"ishandcuffed":false,"optin":true,"jobrep":{"tow":0,"taxi":0,"trucker":0,"hotdog":0},"health":200,"callsign":"NO CALLSIGN","hunger":100,"criminalrecord":{"hasRecord":false},"thirst":100,"fingerprint":"X26B8J230FH1ZME","stress":0,"craftingrep":0,"jailitems":[],"walletid":"QB-34996215","armor":0,"isdead":false,"inlaststand":false,"tracker":false}', '[{"slot":1,"count":500,"name":"money"},{"metadata":{"birthdate":"2006-12-30","nationality":"American","cardtype":"id_card","firstname":"Player","badge":"none","barcode":"1787637314-56706135","citizenid":"M6YW58XY","lastname":"Dev","sex":"F"},"slot":2,"count":1,"name":"id_card"}]', '4842521852', 1788149977000.0, 1788149977000.0, NULL, NULL),
(6378, 2, 'RE036OYR', 1, 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', 'SharpFish5162', '{"crypto":0,"cash":9688004,"bank":9987012}', '{"nationality":"Dinamarquês","firstname":"Pierre","birthdate":"10/05/1991","cid":1,"phone":"6635274266","account":"US07QBX1249610364","gender":0,"lastname":"Moraes","backstory":"placeholder backstory"}', '{"isboss":true,"bankAuth":true,"payment":58,"grade":{"name":"Coronel","level":5},"name":"police","label":"Policia","onduty":false,"type":"leo"}', '{"isboss":false,"bankAuth":false,"grade":{"name":"Unaffiliated","level":0},"name":"none","label":"No Gang"}', '{"x":-1006.4571533203125,"y":-1637.182373046875,"z":4.4263916015625,"w":45.35432815551758}', '{"photo":"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQ1UVOe575+ZzQyDIwgBCRQCEr40ogiigpikIYkGmo82adImTXKadOW2955q721zTtv09NzV76anzemNbe9ZTdPc1TT2I6056+YoMYkkNiCoKKLgBwxBEAQRnBEYZjPDnrnr/37s2XvED6r2IHeetVjD7P3uPXu/z+993ud93i8LXZnMJ6JxIpKf093NKg7KNMGIRJaI69PEPXFfKbgWgmNIb5TI+13ZG8386sjnCUXcQjG8P/71RpzXIr7HG94V/0beD8dkfsjzxrya0RtYKtZVPDyjK6KJ51QORAGYU+qc+ctEAZh5ns2pKywV69ZFq4A5pdKZvUwUgJnl15xLHQVgzql0Zi8UBWBm+TXnUkcBmHMqndkLRQGYWX7NudRRAOacSmf2QlEAZpZfcy51FIA5p9KZvVAUgJnl15xLHQVgzql0Zi8UBWBm+TXnUkcBmHMqndkLRQGYWX7NudRRAOacSmf2QlEAZpZfcy51FIA5p9KZvVAUgJnl15xLHQVgzql0Zi8UBWBm+TXnUkcBmHMqndkLRQGYWX7NudRRAOacSmf2QlEAZpZfcy71HATAPNUubipknjcnZ+oJVcZcQqVjFotxHh4RRdzgOkfi/xsA6pqaameiq/WV5dVIHwVgJrk2K9KGLUBjfePreKSPVlTkWUOh/KqKNRvvWLc6nyyUJx81zmAC3mlochFZO3fW79lsCVo6dzQ2upDOPIE2agFmhZov/BAaQfELFy5MS1qYlP/khuqv31GxOp9IKD3C5hsBMN5TwvDym7U/cJ9xd545c2aQgxAFYFYBYA+F6/hdDQ218fHxyauXLbv5tlUlP1i3suTOpMQ49rw+n4/UCZUcCpEaCITfwWIzvY9dIXLGOfRj7nGV6lsO7vzL/tav7z187MOxsbGRynJePUCCMTERPsKsyp5LPsx17wNIAKB8vO23vvTFX65bueJOIroZ3wGAVL7qU8kRq5Dq9+sZoyhhZbODWhgO5zwH+cM1yof1B1p3/s+fvfRfkExCEAXgkoxd2wQAQCp/55ZfhWgq4vc0laB4XSzmVoIaUMgWw826PcZK3vEx9r+0ArZYMyC408ee/iJbFQQQRAG4tvq95N0b6+uZo8eUD4kAQB33mO8xDQDGBE4bkdcATGJioul6iZKE4HqfXn/dVQGW4JSukd27m14ionnbfvkzfd0dRwxRwB8gf0CYecUeNvcxNqIprkK/3092u53UKSJtyk9KjEgnzuMYRLp8Dgc/j/RSHvryPzmJaKJ81Ypn5DFL7PwI4i7J8H9qgusWAKF82vbLn5kWUVKCAfJOeMlm486dFqKwcplCeRUAACBBK1dsWOFB/X8JgKpyv8DhsBFJUITaHvryP7HqQEIQBeAa8ywtwO4DB3d+5aknv19VsvxTxp80mnxAAACkBKcCZLVaKWBsBSjhVoA2FdAB4VAEKDiFFgSHJS7OTo75KPRhef/IkT9s/u3W58qXLYbjSVEA/gYAoPSvXVv+zFc++/j3HUQplwKAKR7mnxV5jQEQEFWENcZOwSk/6Z8UZN/DEq5CmBWIAECNoeHNr/7puaZ9B1+CFYgCcNUBMHvtMrq37Rc/1su2XygsMBUgLUikiFKtiPpf0zTCn8nky6agqPPlYytBjfzCQgQYGNwLCE6J5wjx6gCtAztrIXCf4jPP/YRVBecvuze7A0fXgQ9wHgAtX/vc4y/eunIFC8ZA+VC8FAmApgUECAopClcCIFAnI9ZllE6fULpdsZ4HAJSvTfH1KBUlfD2HgP/y3raO2v+15c1NFesqSsxlIArAFdoEc2y/smRZ9def+bsXLSK061V5AwClFWK12slud5Lf72UAoOAbAQjA6w8ESIF/gE+Lxj51QRVhqAKk4hlAzAqEYwqwAM4EPU7g2vy7Nzc1He6ovZ76Dq4rC3CovvGDjZ97/Ney9EMp0wHAS6qNUAXA2wcA+JMWQALg93r1ZqFi53V9wO8jv7AoduE3SAgkAFC8f5KDkLQwHCeAFfjVljefXr6u4tYwUVELcEUWwKp6WX9+Q3NLbWVZSfVTD9a8kjQ/6UZ5UxUmXNTv7Jj0DITyrEGuAMCgaX5SZV0OZQcCZFUUCmp+QpXBZNKnPy9vFZhbCYGQn2w2O2lBYZmsRE4Hbxl4xj2n/7Cr6bP7DrS/tap06T04FjMvSa79e0X5cK0unvUWwAjAl558bNttZaU10ulDpgShONTx0qmzGkpcjI0kADIDg+K8F6UfVYYAAP+j2rAbevtYgIi4ZfCLqkazaqSIezAIrAgh8zS2GBvVt7Vt+z9v7Lg3CsBVQtYIwH9/8rGOW8tK82H2kdkMABKLhUsA7A4ig1NotTooGAyQzeY0WQCUfl49BNlxKUYA2DERKZTn/UGVgpomwNHIapP9CHb2TJ5xz/Fn//XlxVEArjIAzYePdP76O9/s0EgzLc+uGL8xb1+sTi9LpYa6H4rmpdQrTDwAQKDI6x3Rz7Hmo18lq4gisgsCaAIG9OggAJAWALEEzRJkikdLBFWBV/Vq33j59cXL825ig06iVcAVghBSveNNzS215WUl1RsfeWg7yc4cKBslEVYg4Cerzc4+yRFHNlEncxtvo4CfO2w2u4M0EdaVgSC/b9T0hNLHRz8B6y8Iku7wIaEi4gAyrhAIcuuhBYNkg+NpU+i3//FeTdPhI7Xly26ptiy4YVaPF5j1PoAE4EtPPrZ9ddEt1YQMh/JF295mlftRCD3a+QAQpnCAYLFSQHjsTFECAPQXQOxW1P3c8bPb40gVfQX6TVRjVJDIqql6KBkQSACsFuFs2hRq7eyufelP22uiAFxh6cflEoCNTz7WWV50S97FAEBTThNOnG4FBADSCkinEBYA3jyFuDcvIdFiI4BSuY8RmPQxSyAtgHw1NRBuNXArY6fWzhOul/60LT8KwFUE4LUffZc38KQFQNPPbidpAWQ7XgKApM7EVP0J/JM+pmQFJt3P+wIAgN1uM5n4oIjshS1A+CUAQGB8mB2wWhUKBjU9DqFbHRFP+OIPfm6JAnAVAAh4z403txyu/dW3v8EAUGJ4ibSLet4RwyNxemePcP7s6LqNEP9kgIK+8JY9qqqSVYz/43F9eP2G0UOI+42bv/s1H2mB8LGxCcPYAzyfn8cTnt38sqVsWUG1bUFq1Ae4Eg6mA0ARTUAM4gAAUvlsUIfovJG/qcRwkw7lByb9hPECULwUzco7dvT0okpQYhTyq34KTgXJKu6BY6pQsCZMv+ccH0LGfiPgjwJwJcqe7toLWQBAAIXPc/BAmxzRozhsrOMGYVsoDABA+RAAEJgYI5/qozgHdxYBgBSAEPSpusIjlc8AECOCNL9KgMA7wZ1COQIpagGuMgGRAKAzBso2AqArP8ZGGnHlowfP5kA6K3lHvWyYGMQ37tYHiTpg/g3zBNAKgI9gFJR+u8OuA8WGkIlmpQQA6dGqwG9IWxKtAq4SCKFz58abDh+u/dnXv8J8AHscD+g4xcAMhyNi0GZEHe7zuE1P4jkTMWQvYlS49Cn0iyIGmQqDo582jjj2jntpdJw3G7/3yhbLx6sqq0/7I+cWXqWMuUq3mf1xAAHAM5/8eGdxfm7ehQDoO9nLssQzZg7seMcjAj2jE6ass2EYsEHk+D+9WrCYm4UJCeYRQqkLk/WrJQBHT5x0bX3vg/woAFeBUmkB1ixfuv2Jj91TLQGQt/b5eDu+v48DMHB6RP/Vrg4XpWalm59ikpfQrIxM9gkABgaH9DSDw+Hr2f0G+ti5vOwc9pm8IDwmMCsrk0UjpTXCeViAY929tX9+v74mCsBVBKC8uGjj4zUbXpQADA1wpY2O82ZdnwBAsTkJipfijqgSpMW/dfUaysrIoAHPkA7A4OAQHe3uNj114vxwHQEIvOd4FZKVlSGASGCfEgKNbPTG+/WbjnT3bo4C8FcAYPX7mU1u2Lt3i7hciY+Pz/v8Ax/7aUlB7j1uH1fAyFk3jYx4aOAMN/FDZwQQQaJBAQOOOxzmSn5JehLl5eVRbl4uu847wZ3DQ21HqbX9CHkigCHdreNPg3kHyQsS2B8kNTmBkhMTKUVMIEmcn0THenp+tnVX489PjYyAROZFVJaXfwafwZgYc2z5r8ijq3nJrPMBjABUrl79WEXBzU9A8XqJFgB0dHbT8IiH+k8P09BQ2IR7DG18XFOQk0W9wlpkpadScV42u9WG6g38llNEre1HpwUgIzWd+ofMTmRGcgKNnOPQAYLUG5yUnJikQwAApBw90fvWfxxo+W1PT99rUQAuE1sjAOvWrGldk5+zvLSAl1YILIAs/UYAUlNTqWhpEXV7xig9M4sONH7A0hfdlEq9oo7PSkulpPlxrPTn5YslAgwAIL1rYIAyF6ZT3xn+Oe/mRXTm1CANDQyw+y29MYk6evsYBBcD4OgJ7pO0nhpqr9+zpygKwBUA0NLhopKCPAIIkQAEglaC8qWo85NooK+XBk726ABA8VJSxf+RAOA8qgG08zNSsYM9l/rjR9nn0KkBKlpZSguDPIoorQBGCU9nAba+X8/S+e2OKACXqXuWzBIMstj57t27X6msqPzj+uLFDx/v6qaUpEQqyM0hJYbIKyZ8OucnkmJLoOEzYc89zmGlnr5+/SeHBvn/pcuXss/EeXZyJiSSMz6JfWIm0eg5N42d45+qVyW3OxwrUOLCzTxc3+fmv5Wawo8rFO5bSJifQEqMkwbOjFBL23FKS02m04HQ6w2NDY+sXbv2KaQPWa3mNYtmkjnXIO2s8wGMAOTn5z/1+J23/Romf9jtobVlJToAUD5T4vxEGhkeoeNHj7Ps6e47YcqmnIxUSr9xITuWfmMqWcUIotSMHPKOekixkgkAR2wcec6G6/1RVaHe00PsD7LopnSmfAlAXAxvho6KaeUA4EA7f5b01BT6Xd1fnj579uwrUQAuk14JAJJ3dnYe/OJD9x/A/4BAWgB8l8qXtwUEsARDw7yuhmRnZpDm5yUUyodIAHA9xDvGSz9T4jk3AQCj9J7iDh8AyLoxlRJvTCZj8IcCKo2JYBMgiABg8o+7Giry8/NXyHtGLcAlQDACgGrgsbur9qYkJa4yWgCpPJR+IwDJMMuiGdd7kgdwUpPMkzklABIiCQCUDwEASTfw+7rPeog0czPSYZgHwBJFADDkVnXzT0QHtv6lfqUs/UgeBeASAJBhSBbmAd6+dMn24twcNg1seW4OjYT8lLAghRIW8DoY7XKzOMjrHaWhoX5yOhMoIYED4Fd9FGA9fTx1UjqP7PnHR2jMPUKjHj7QQ5nHLUP8Ag4BOpKM4hT3k8c8Y9wpRMgZq4u4R8L+SGtXz1t7j3dUz+aZQrPOBzgPgFtuqS7OW7T9YgBgjL8c58/cMu8opabySB2GfUP5rLAKAOLik8gxP5Ec85NodJBHDfu7eb0dCQBGBQ+dHSJnnJO8Pi/FxZmriFFveEgYHE7Z9Yx7HXL1fGxPR8f2KACRhfSi382TN9v3HWj5uw131RbnLso71NVN8ckOVvphBZiIWUFhAIiVfKeTjxPQAl6meL8IEDnmO8gIAKluGvWErYBXTBBKWJDErYAAgJXyCS9bVcQkVt6ZhNIPKwAAinOzqLWrl36z8y+FpatKi80XzK6pYrPaAiDjUA186f6a7ctyc6qNAMhMVSxmhUD5ECMAXkOzDgDA/KP0M5kGgNFzHkpYkEiAwCqWkUPpBwDG0US4PCExWVc+vusAfNjremnbO4UV6yoeigIwIwtgToxFoAqys6vvu62SVQOkqmSPtZMzXjh3IT85nPx/xzwnOeLCoVhWMs/wVsHIsJuSU5IoKTWVkpPDbXupUBnpc58doKER3ipITU4kxRpHToeDvMKCDI1zZ9Hj8bB+BriIgSmN/HL6uBiu5jo1ULtjT0vNbF9EahZaADMAKUpo/EhXT+fH77gN6wDm2UNB8k/6dQCkRQYEkQCoXi9pE6NM+ZDCJTmkWewXBcBGKtU1tTDlsxIen0hOMXwM3wEAlC/FGWNjygcETgxHw7B0i8X11t79m7r6BmujAFxB6celAODNXQ219922bntBdla106aQd8zLrAAz9fN5HRwJAJSPv9GRYRoZ9tDaW/m6DQAAAiswMjJC3tHwgJGhwQHKSOMWREKg2BzMAkjxTqmsGpCWwybmIRgBEKV/0/qykvwxhzM6KvhKGJAAEFH1V554bDs6cwAABJYAuomTVQCsgIMrUAKAFgAASE7hJVqLaDZ6BgdNj+dWVb30oypIT+P9AhICIwA+VaW4GADCIcSCk+hLeGvfgRqU/vVlJdVRAK5E+0xjGutPb2xsfGNtxdqdNYsXVRlv6ZuCT+AgW2wc2e0OEpN12WKP3gmf3qrs7jlBJ3q6KfUjvHkI6TnVTx6Pj9JTDOtMqV7K+EgaZXyEjyQKYnFhg9g0TARVyT+lss/EiDGJjYOeut2Nu5+sqKhYzS5T0Hsxe2XW+wBGAJKTkz/xcGXZLzKTk/XuOiMArKTGOXTlO+fFUeoNPGl3TzcBgpSF4Z7BD5r3MABKlhTqGho82Uury0ooMz2d+gYGzgOAJjWyxTh0CJxiYgpuMHj23OBbx489MDI4sreiouITUQCuBvjCAggrsPe+yrKX1hQU6Kt1a6KAwgJECmBwxoXDxYBgbGKCstIzqHegnwBAXIyT0hYmU3pKMg0Mj1DWjclM+VJGJnnzTxcDAADBOJNo4Ky7dsuuxmf00h+1AFeBADMAb6wozHn4k2sr/ijvfCEAuPLhvJlj+UYPvn7/HspIDlsE3DMn0zyIVI3hw81koAkmH6ZfinFMce3eA48c6R98XS/9UQCuAgARt2jcV9/yjUce7JSHjSNycUxG6hJFMy7OEVYoOnxsTm4pMMADf3nZ6dRvGBWcnGIGQq4KJiHASiNGCQTC1uHnb9blV6xbF7FM3NXPg6t5x9nvA0QCUF//+oO3r+lckpXBxnTp6/M4bGwGD1aMkcrH+cAkQse8ZWAEQEKQIIqwhAAAoLQ7RctCAsD6Gya8+lJEWE0EypeLS7lODbl27G8DAA9fTQVd63tdlwA8dPua7YuzMpgfMB0AbMqXEEUxzxxyi75/eR4AQPl9g0OUmZZKEgCch8Kd88KtAAkAX38QU8zDpd/Vf7p2x4H2WR/5iwTqugTgltzM6k+sXf0iiwzG2Mkm2uHSAsiXVCd8hKX/YQFQ+vE5ANM/EG77D7rDo38y0jF6iFcB4c4l1WAN+GJkQbksTHh3Eddb+w5v6ho8M+sjf9c9APGhqfG3G5o6N1SueTEvK6M6MYYoDjF5Ga4Vc/mGRtwspi+XgceL954ZooCYByAzAoEfoySIyGKWaC6OjHtZdDBBTBBB/D8gZhtjDaGAzUndp4Zq6w4e3lRVsizfF+OY1ZG/uQJAbW52ZvU9a1dvBwCQpETRCTRFJJU/dNZNJXk5tOW9Ov29P3v3ffr/OxrrCQBUlZRQThp3Fn/yxmv6+cduraKWE91M+fHz49inItYCkvsNAIB3D7TX9PT01FaVl1VHAbjGXgssAH6iq6ev855bV3c6plTWKwcrAHHExOkA4HuGGN4lH8se46S8zCz9KQeGzaHggeEB6h0OTzQJiBFKRgCk8nETAPDy9p35KP34HgXgbwTA2w1NtX//6IMhAMAULyAYPce/yy5dCUDv0BBlpaYSADDKkMc8GXTIE1Y+u+98O42N+3QLoAU0VgXYYm28KpifSC+/sd2C0h8F4BorH7ePExagrqGp9nOPPhh0u45aCvPDoVyrYqWgFmQrdkgo3OfGyDM6Sm5M6bLa6ehxPvyLSYw5gpg036HP+0teEE/qFF/9wznPyWMMYgkZXNrdP0Rpi5e0b3l966yd+XMplVx3rYAIADqWpCTlH+88Tik38A4dAAABBBC/YXHo7pN9dLTTPPv3QgBA+ZBRsaiU7mMIANyjXsKcgz19I7X1jXtqZuvUrzkNQFXlmm01pUU1eEkJgbQAcjVvwQHLB2YFxCjeC2VMQLQKJACwAFhSVh8LGNJIKh/3+FPjocd7+mbv5M85DUB2dmb1xvs38KFiAoKE+AR9SjirCqY0SloQT6gG8OnTFLplcbjKwJhAKUdcvaSKsQY4hvl/ihh4wqyJ3896GlHyhWhv1LfcnJ6dre8PMNumf885AKwaXz8A0nfyFG189IHXZGnHIk0DPd2UaPD8E8QgUaRPviGZ4gxjBgdOD5B/0mua6YP9BwbENDBmNQQQWP4Ff6kpqWSzKWS3K2SzWUM/eWX7otXlK3UAAjGWWTX/f84C0NC4d0t2ZuZjn/9k9Wt2sYED1u71ekbIc9ajQ3AhAKB8VqonzRM/vGIqGc4NDg2xUedQPAQdT4nxfNQxAIBs/eDQ466eD1+7rbySLQARBeBSyF3heWkBAMCt5Wu2PXBrGfMBILAEWAjS7XZTd1c3JSUlMe/dOAoYc/cgEgBNLB8n7zHmNy8qNXpOlPy0VAaAU1QJNht3NuuPDNTu2tNYEwXgChV7uZcbAXj04QcPr1yUXmS6dgrTu3m9DgiwIKQRAKzhM3DaEPyJWAbOY/AJ2E2meMmXf1gzKBAIwvzz3/BQ+5Y3thZFAbhcDc44nXmmUHwoxCKBu5pbOp/7wpOdycaZOmzzAL75M8YD4rOxpYWN+JGC6mJkxLDsi1gFblS0Dhx287JxGRm8eYlh4nJHcWxTYxV7E+7tGiSrNZQfCllZJHBM4+sbXL78584Uug7iAOcDgCjgXWvLN966atmLOgDIR0NS9AdARsSCDi1HO9h3X8Tiz8bNoI1KK8rlg0dt8+wXVD7OJ2Tk0DsfNG56d9fuzetvr6yOAnD56F9myul3Dv3Wl55hK4cyAGQhMiSVVgC+Gsb6SRkRizvDCmCNIQAge/oS4h2UOC8cKk69IYFsTjm0bPrHBQAUItdXv/cTZgHO3zn0Uq8ZtQCXyCGuVcwRXLhwYVpJQW7JVz//+Pb6/a3sOAMAZhx/QCICAmz0IIWBYFhNHMvM+QM+GhtXKV509ypimzlm9m9IoEQxn+BCD8kAIKK7b1tLX/veCzUtRzpazpw5MxgJgtzyVt4nfH6OA6AQmepE1auaut+aW5ox5WtaqSyvrHYmOent2rdZmudf+Nft+fMms0NkuQXf3UMI3LCx98TWetGCpIilXeV0LaSTs3iwSjjbZxDNOJudxfhVL1/uXfX7yTcZoLgYDC3nVgAtCKvNqo86YukmVbIZ/ISEeBslp/Ol55LTso4ePT164qv/8FXWMllfvb561O2lpqaG2tjY2LzilSs3ZWcsyjt27Ojmjo4jnZOTk66yMt6JJMXmsEX4ENcWkGvuA0wHgFR6QkJCXnZ2dv7SZUs3IgPa2tvy4+fFdx48eNDl8/k2GTPmwKEjfMeQcTd1H+IrcDEAJkQGCQDYRiJyjwAxZ884o9cfMsdpvOdGSBUDPHBPY3YDAAwvk7uCSQDwCQjsNhubmSQBKFixjuJS+LiC0tJS0+5mayoqthNZ8rNuWoSxjC4KUSdA6Onp6hwdHWWLFACGOQtAfX39K3hJKL0gtyA/rzBvY25+bn5cXBwb3NnW1gYAyHWcL9hQUlJSa7FYXPMWzO/80fM/xfAvJt2739S5YABM2ljJZxYACoxY7t0rNomSF8ECyLX9cSwSgASDD4Dz8fHhjT+xNZzRAkQCkJyWRZlFa/Tn+8dv/OOm0XMT+ZZQKK+1pYWV9MLCJXTv/cYZ4z5XV1dXp6vDtbmjo4PB8LdcUOKaWwBM7yaitOzs7JLKtZVP5eTlYNi0WKWR9BU3AADk37f+O5WWlOJf19NPPZ1XWr7WaAjOByDgQNefngYAYI5eWOHhKoCVYFEFAAKEjrE4hBRHrI3sYn9BHHPGzWNDzYzb018MAFxTfJd5UPDu5gP06iu/BtV5rS0H6L77H2Q/V1DIajG0S+TPMxBaDra8cvbMWdeZM2dacOJajzK+YgBCk0HTsFsl3tbXULeL1dmxCbF5pctLS1aXrX4qFAqVkIXSbIYSlZOVTQO9PdTd3U0nPjxB3R92U+LCRCorW0Nf+K+iBogI1Ay172IZNnGGLwLlxdbugXCxR6AHPXcIC7MNo6f8+qZQcmcwWd/j+hGPlwJY8dtmJ5ti1dcc0scZOhz6trHBKT9hQqicmYxBIakJPDQMySypIqeYVyB3LJHbzfzb//43at7XzKaWFyxZQgWLl1DhkiXktCvk6govbp2ekUNHjx7dayHqP3rs2ObmpvqTRl8hZA2ZFkCw2+MMW5+bysplfbmqADTt2/0SlF5WVp6/qmwNq9dLlxVVN+9v1h+mYKk5cAcA3tv5HjsPAO6q3hBWPg5GAIASM9S+VwcA5Qe7g0jRgnz6t9wyHt3DUDzb8WtSZc6eFHTresZVsikK2cV+wPGx1vDwMkccacKfwEbSAEALhWHDIhWJhqnjS6o/R8Ep3m8QCQCOAYJ333mXAQABBKXFPD8kBJ5R7qQu4Wn6Kage+v2W328+fPgwcxpXrl75mFGzswIAKB4PtWpVxZ2Vd9z6lVVla6r37dvDnnNvE3fYylaW8b+yMv356+rrafeu91nplwB87Z//mVkAXf4KAKB8OTAE97kYAF5fgCnfH9TYpwQAph8jiqAOWJFIAFD6YWlmAkBzczP98Ps/NAHw8EMPsFftcnWxz+aWNjp6hC9Pu+SWJbSkkDcziagWIIRCofb9+/ezhYgBw6wA4ODhAztXLCu98/Gnnv5+UkpSCpTf3MwBwL670ykf54wAoPRDpgNge+2fX6+pfkhUrudbAGOJCGp2k/LluekggAUITIZLNKoADAmTyse1EgD8DwjIGrY2FwIApR9/WI/IKNMBAAuwYYNYuZyIjVgCAFv/vJVd6ldHqaiIW4miZezz8B9+94f6ffv2/Td8uVIf4YqrADh5sbGx1R+9664XKRTKCxj21CsqWk74wgAaAAAO2ElEQVRLCotpzWpDiWZZihE8LurocJHX66FXf/sqO7Z8+XL61nee1/MMu3GxjBf1Of7Hzp8nmvUxIKSpXpbZXEEakWG6NjZ5tlv5+j1sHZ+Apq/uwWICGP1jsDAOh52S5jvZgE9Zz/uD2DoOCo1oXrCmoJUUK69yEtKzKGPFOrKLTaskAHx2UTi6+O0f/Iv+fsVFyyk5OYHW3WZa8oCd7z3ZQ/X19dRykPmCujgsRBVrK6hxd+Pmurq6TbMCgA01NdCIaOYUUNEyvjLa0qJitoKGlL7+PvJO8PV1oHzIxQDA7ByURuzyqdfpIlKnQzDl07eJYxCQTd/dG98lAOy3fP4LAgDlxzls5MBMowgAcG0kBFC+3YadyXmLY0k1r5olAPgfM5bg9Ml5hhhaBgAOHeZRzCcefYIBkCW2o5GfRoUfOsj9p9bDbXSorY0AgBBXXR2bjHpFcxGvigUAALdXVSEWnnd7BM0AAIrv7+erdg+JVbvkWxgB+PGPfky5hXxVbymRVkDu/XspACQwigj8wAoYAcD9YQXIULIlAMbVQDUrN+cSArlXNZTPgNMUvfQbAcAeg7IFILeqx/kTJwbp2eeeNQHQ29MdhiCH742QdROPLtJUOJR9qK2d+np7UPpRejobGho2la5adUWzka8YgASns+X2u+/uvL1KmDGDSW1vayXNT9QnlI/36T5hHpWbmRHuqi1eXnxRAFipMqwLyCAQGSQ3iySrQ7cWSD8dADgO8882kDTEDGAFsAW8EQBVVGkSAhlzAAA2u0L2RG76pSjwE9hGlmEAjEADgN/87lVmBWABvOPmeQmowrKy+MQVfGKXE6PAooQo5GpsaKSGhobqyampqwuAWHhT/83ExHnm9e1jFHr7zVoev4+lvOd/+NNvZ2VlPyqJHRweoIH+fhro76PB/n7y+fyULnboYsfErl65uTwW5J300j13cXhycxaR3c7b1aj3IQFNZYEd1OFMQgppIY1N0cJn/95wZBCn/UElAgBF3x4e/okfO31OYdNn0Xw2rODD1v2LcejDvXgJ5M1GbDgdKazeLyoju53X8WyqeIhIsdnIarOT6nGT3RAnYPeZGKW29qP0hz9upaVLl1BKUjLb8Eruepa7uEBfin5oeIRNVs3MyKSMDN49nShCzSe6XfRhl+v33/zWc9+kSWL1KfoeaNL8lB6fx9S3oBgCXUh5ngW4EACyQ2bD/RvyMPihev29G4lC+avXrM2DwwLp7e2l0XMjTPFSEm9IZTBA2PEYB0nld3W5KE2syJF3cw5tuPOO8wAgSzjjoTgW9RXz83BPq8VPJ5rCTqEEQFYBcPL8fh8x5WPHzym5sKNGAZh/AQBTfpyD7IZ7XwwA3ekT8YNIANiz2exsh3G507gRAEAA6Tp+lNaUr9MhgIuMvQgWig0p0IqSAggKl/AWQfeHLrrjznuovn4Xqw52vlO72RK0dO7YsYPDULWe+WRXBMDeRhbGRTMlL2QN5Vevr9644d4HWF0vH8rtdo/VN9THQ/kQ7MBhFFgACURaRgYVF/M4gKuLt3thASAAAFKz/l5TCdaCKnlVPzmx+APrteOlXwoAkAIQ5DqAlwMArgtQkK/4KdYUcBpGGAUCGtksxJxQKY7kdJPJlwEkuVAEtrSVpd8hJ6yKiwHDgX17mAWQIgHAd1iCMdVLKPlyQ4rkxHCkEWlybg7vnwQA5JxIcT/XO9ve7Nz5zk4Ow/schtUVq3VH8ZIWQMTuKTMzM29V+W0lt1WuemrDPRvCSjd49bg5tlfZ8rvwjFoJAJQtqwD5sqWr11BOZo4e9drx9g6TBWCw3VlDdkN3q2INmGb3aFMKBQ3Ts4wA4PoTzTyqqIvwSXQrMMGbobJK0YQPAAAAghIMkt1uJb9fNPtE1QMI4M2nletjUNl9AACUj0UjIFa7nYIBP4MgUlTVR22tLdMCkHETr/cHBrqp/RgfvQSJBMB4z6ef+ftIANhSukxC5Hqn7p3Opv1Nr+zZt8d1qufUtH0Llqr13FTUvf12Ler0yrLKmz779Bc2rixZiUpndWKSg3WXqpO8v9wuXlQ+yKh3lF79DW/HQxSbQvGi3hszrMKJWABMGJwvGfZkVkCUrrz8QsorKKDd79XRg4+yEdZM0D8P0UJEfo1/R3seghIauV28VSzegPODbY2sg1cd5lUQJOxTiwNiLKAznSvAaHLlFWnhgcemsQEs4BMKEDqRdAmiOck7KCGSI/y/9fU/U2nJLez9ZR70nx6hqju4D5SzKIcSExNpT1M99YutcLHARWZWBo2eG6XRc2NkN/gsTzz1dHhdBPEAihgRIzfXRt8FYHj/vXd3fONr//hlPFJVVZU+BoEBwJRPRN/94fPba9bftxyzqvUMi9hIUZHtIJEAgQ4A0Np6iIqLl1NichIlxMfT6NgYSQCgeBkMQpevlDzhCLo6OpjymaIFEBmiGYQhXYqFAwBRfX42MUOKKkpoOE5g7u/HkC/Psb06BJEAOOebvWwjAGkr7jDtLo7fVAwjBliwx7CEDApKgtMpx6acB0B/Xx8F2AgWg8Q49JaRBAAOIXMMT/aKFU7iKWFBAoNADmDBHXQADBYReWUUtnaxQb75tWdrGhoaWL8CQOAA7Hq787vfev7FO6rurjYGbnAdFmK8mMCsSQCQ7r4H7kWfP40aSr/Ri5WDM3gp6KIuAcSGj/GFG+yKlTKyssgIgPx9+XJuj4+cTm5iAyHeYpDRQpvFPIZwukGf3fU8zAoxApCK5lxk30PkOp/iPJp5rKknQsOeUS+lp/COOuN8RKMFMALw1ttvEQqAEutkJV8KLABEQqBO8vcBAH29fbSngfeGPvnU52j5ihJyGKau4filAHAPn3K98OMXXmxoaKitrKzMZ7wAgu9854cvkoXyrhYA8oWMILAMdzq54kUXaK5o88r0GJCRKY6trrxVjvPQM8guhnF7J7gl0IRDCAcLEFwOABcl+jIA0JUP/0FUOXHCeYTyjS0pzYIOMd4v0neyj4bO9DLFowB0dXWxnUsAQE6O2MJG9VJmZpa+F7LdEQ4jwwK8s503e4tXlHILYAQAlsAwNoIljJj+7hkeYHGEF378wqa6urpay6OPPvrlL/6Pf/iJninIAGk1YHaBCP7wfwgLJJlLWG9fL7W2trIqAJKaspDt4KmbeoNJQmdI1UerKCMrk9VrGTdlMKdlj8ig/pP9LENSb0ylodNDVHV3FRm3YuUvZFafOu5jy8NZhTMXUEW7XTSfpMOIMGyk8Pi++X2CoqqRaa0GE2qPtZFNKBpOIULVsHZo5oXzz1zJeDwq7dnPAeg/1a8vW1ki+0eEr1D37lssTYpYqqbtGG8pZKSF1zbG965j7bR0OWppok9/5gnTABYcg1Mc+Q7G94YfJeXXL/3iWUvD3gPmV8YDyX4PUdrYBeJYMCLDJADypgP9AzoAbe3thCoCXcBlq1axJEUrzKFeANDf1099fdxRU0RQBf8DgrXlaygtnW/1ziTGDKHMfMTq/SoWheALPgREAEdG8vTrzfomLeJ9YEWM28IAAKPi4fME/LxFYIvw9Fmb3+CE4jd37OQmW4pdFAgJAAJPUrq7uyio+ant6FGSALiHPVRUtJT1BLYdbiOHmJOIayQACIixvGPW8OJzU40A4JrzATiv/930/OjrMh2YDgAovmgpV3TZ6lWmMQCqIbbNEohmi7QCRgBwenRkiGruC4+hC4TCHUOs3jfEBGS41qt6yelwki3GTpG/Z+zVYx086D4yhIPhPRsFPYoQ7B7GQsQWYoqXsQE93iCil8YqaPub2yk7j09F7zvFAb8YADgvd0FrFxbgg8Y91NbWziBg5yMAkM8nI6OKwQeSjrPxfYz+yVUFAFXAoYOtlJaeTp9+5FPMCkAShWMkH+KvAaC0LGwFIq83euVmVLE6CJqv3CSjVE9XDcgMZ1FB8CiamHKdQEwpN0mEly3PydC1vN/gwCAdaD7AAJDKnwkA8r7YDZ0NmD3cxkBAM9hYBUgAkJ5NjjVabeGQigHTkdnDvlt2vt/AqgCHnZtOY5CFHVDCcXn2IxFe9uCJQfr9H1+ltrZWKioqpk8/8gSlZYY3X470quWgTPk0AycGqbs33EGkxFqp43gHFRTyZqEcpFlSzvs8+C49FxfjsC2ZEu8l1xEwXi0VrXfZijpeNne1YJAim77G62VPn7HXEud3NyEGQZSUFE/dIuqZk5tL/nEe2s0WXcCXmngigUJ12Haojfbub6a2Q4foU48/QUXLiyln0aJLZYd+HgNaECcwvrMOgITACACrWyLblREAvLttB7W1cwewaOlyusswuoUdjKhSAADqfCk9H/IQsoRAOpmRACANIIgEAAoyiXhec7SQRw+nAyAy96STd7m5GozoPJGWANvRYFYy3rfu7R3U3eWinNw80lRehcq+f7mbebro7In8XePGmIBgz/4Waj/ExxMsXV5M993Ph5RJMQIr/2cjmYQAALliOiyiCQCkQRPHfEM+ulb/gWkAkOeKlhabS78BAIwHQLew6jd7yZo/qCv/xMluNnmzsLCAWYDCwkIGoHvEzRZ9gBTk5bL1fI0vbHxe6aMYlW00k+/WvfP6HR+tuuAgCuO7Xi4EMh0yVI57kFPSAQCUDwiYTIWVj6+ZmWEvPw29poqib1OD80YAYAG6ReERELie+cIXUpJTUvWR2dISWaXODK02DGqlUNCwDC6R5c//d5vqiHXEOGIdqD0sbI7dxUQ0wzxuD+bfd4+cHkLdMVG0tBiV5TyxUrdNneAhGKyu0dffP3Gqv88bIkpQVRVelmzMTfkm1ckTJ7uBKCiL9Y352gsXF/gKCguXFhYWOshCinvYfc7j9iDyE0dTqj85JZU9ZXLKwljn/ATlIoDKhqw+SuhSVkDcS16nXy9LtjFrkNbv92t2u93i9XpZA9rrxWuy98NncGh4INDt6vJ0d7l6yELZNEXIL5gBW1Z2jk2xsLR4d94aczjc6enplJaWznqBnDYWesUf8kjzBoJK26FWTK/zW8jiT74hPqZg8dICWSgkALiWOclhpz0ES6CqTC+wk/jdwP8Dg/qKVWOJfRkAAAAASUVORK5CYII=","health":200,"tracker":false,"inside":{"apartment":[]},"inlaststand":false,"vip":{"expiresAt":1872020757,"tier":"developer","assignedAt":1785707157},"callsign":"NO CALLSIGN","criminalrecord":{"hasRecord":false},"staff":{"permissions":["command.addjob","command.addpermission","command.admin","command.admincar","command.blips","command.car","command.changejob","command.closeserver","command.deletechar","command.dv","command.givemoney","command.heading","command.logout","command.names","command.noclip","command.openserver","command.optin","command.removejob","command.removepermission","command.setgang","command.setjob","command.setmodel","command.setmoney","command.togglepvp","command.tp","command.tpm","command.vec2","command.vec3","command.vec4","forge-core.admin","forgechat.stickers.admin","group.admin","group.mod","group.staff","group.support","pr_bridge.developer","qbadmin.join"],"version":2},"oxygen":100,"armor":0,"ishandcuffed":false,"craftingrep":0,"jobrep":{"trucker":0,"tow":0,"taxi":0,"hotdog":0},"deathTimeStamp":0,"jailitems":[],"optin":true,"multijob":[{"grade":2,"name":"realestate","label":"Imobiliário","stored":true,"addedAt":1785210654},{"grade":5,"name":"police","label":"Policia","stored":true,"addedAt":1788138980},{"name":"government","label":"Governo","grade":3,"addedAt":1788139016}],"attachmentcraftingrep":0,"hunger":100,"phonedata":{"InstalledApps":[],"SerialNumber":87237295},"isdead":false,"fingerprint":"Y3GX99IF80Q5WXK","bloodtype":"O-","thirst":81.00000000000002,"phone":[],"walletid":"QB-12136507","stress":0,"licences":{"id":true,"weapon":false,"driver":true},"dealerrep":0,"injail":0,"status":[]}', '[{"count":1,"name":"umbrella2","slot":1,"metadata":{"barcode":"1787806726-15289057"}},{"count":1,"name":"WEAPON_CARBINERIFLE","slot":2,"metadata":{"serial":"279419XNP734011","durability":97.14999999999988,"barcode":"1787630163-69877257","components":[],"ammo":28,"registered":"Pierre Moraes"}},{"count":38,"name":"bandage","slot":3},{"count":35,"name":"remedio_calmante","slot":4},{"count":2639,"name":"ammo-9","slot":6},{"count":1,"name":"carkey_permanent","slot":7,"metadata":{"distance":8,"motor":0,"label":"Modelo: jester4\\nPlaca: 5TS706NB\\nProprietario: Pierre Moraes\\nSerial: 215910JLM764854","code":"215910JLM764854","sound":"tranca_1","barcode":"215910JLM764854","modelo":"jester4","proprietario":"Pierre Moraes","plate":"5TS706NB"}},{"count":877,"name":"ammo-rifle","slot":8},{"count":1,"name":"carkey_permanent","slot":9,"metadata":{"distance":8,"motor":0,"label":"Modelo: sultanrs\\nPlaca: 63AVE439\\nProprietario: Pierre Moraes\\nSerial: 909020SJB333207","code":"909020SJB333207","sound":"tranca_1","barcode":"909020SJB333207","modelo":"sultanrs","proprietario":"Pierre Moraes","plate":"63AVE439"}},{"count":1,"name":"carkey_permanent","slot":10,"metadata":{"code":"960810XXP316774","proprietario":"Pierre Moraes","barcode":"960810XXP316774","modelo":"O4UKY513","label":"Modelo: O4UKY513\\nPlaca: O4UKY513\\nProprietario: Pierre Moraes\\nSerial: 960810XXP316774","plate":"O4UKY513"}},{"count":9688004,"name":"money","slot":11},{"count":1,"name":"carkey_permanent","slot":12,"metadata":{"distance":8,"motor":0,"label":"Modelo: jester4\\nPlaca: 89KYG626\\nProprietario: Pierre Moraes\\nSerial: 261951RQV200766","code":"261951RQV200766","sound":"tranca_1","barcode":"261951RQV200766","modelo":"jester4","proprietario":"Pierre Moraes","plate":"89KYG626"}},{"count":1,"name":"carkey_copy","slot":13,"metadata":{"barcode":"959079LKP442039","label":"Placa: 09QZC287\\nTipo: COPIA\\nSerial: 959079LKP442039","plate":"09QZC287"}},{"count":1,"name":"carkey_permanent","slot":14,"metadata":{"code":"761282RWF232469","proprietario":"Pierre Moraes","barcode":"761282RWF232469","modelo":"sultanrs","label":"Modelo: sultanrs\\nPlaca: 41LGZ479\\nProprietario: Pierre Moraes\\nSerial: 761282RWF232469","plate":"41LGZ479"}},{"count":1,"name":"carkey_permanent","slot":15,"metadata":{"distance":8,"motor":0,"label":"Modelo: sultanrs\\nPlaca: 41LGZ479\\nProprietario: Pierre Moraes\\nSerial: 672248MXB342423","code":"672248MXB342423","sound":"tranca_1","barcode":"672248MXB342423","modelo":"sultanrs","proprietario":"Pierre Moraes","plate":"41LGZ479"}},{"count":1,"name":"id_card","slot":16,"metadata":{"sex":"M","cardtype":"id_card","nationality":"Dinamarquês","badge":"none","firstname":"Pierre","lastname":"Moraes","birthdate":"10/05/1991","citizenid":"RE036OYR"}},{"count":1,"name":"carkey_permanent","slot":17,"metadata":{"distance":30,"motor":true,"label":"Modelo: jester4\\nPlaca: 86IDP629\\nProprietario: Pierre Moraes\\nSerial: 969643SPD874216","code":"969643SPD874216","sound":"tranca_2","barcode":"969643SPD874216","modelo":"jester4","proprietario":"Pierre Moraes","plate":"86IDP629"}},{"count":1,"name":"carkey_permanent","slot":18,"metadata":{"distance":8,"motor":0,"label":"Modelo: jester4\\nPlaca: 29SEZ734\\nProprietario: Pierre Moraes\\nSerial: 400890KBW379335","code":"400890KBW379335","sound":"tranca_1","barcode":"400890KBW379335","modelo":"jester4","proprietario":"Pierre Moraes","plate":"29SEZ734"}},{"count":1,"name":"carkey_permanent","slot":19,"metadata":{"distance":8,"motor":0,"label":"Modelo: jester4\\nPlaca: 45YRP591\\nProprietario: Pierre Moraes\\nSerial: 690069VCP446894","code":"690069VCP446894","sound":"tranca_1","barcode":"690069VCP446894","modelo":"jester4","proprietario":"Pierre Moraes","plate":"45YRP591"}},{"count":1,"name":"carkey_permanent","slot":20,"metadata":{"distance":8,"motor":0,"label":"Modelo: jester4\\nPlaca: 09QZC287\\nProprietario: Pierre Moraes\\nSerial: 693650VMZ968300","code":"693650VMZ968300","sound":"tranca_1","barcode":"693650VMZ968300","modelo":"jester4","proprietario":"Pierre Moraes","plate":"09QZC287"}},{"count":1,"name":"WEAPON_NIGHTSTICK","slot":21,"metadata":{"durability":99.9,"components":[]}},{"count":1,"name":"carkey_permanent","slot":22,"metadata":{"distance":8,"motor":0,"label":"Modelo: gauntlet6\\nPlaca: AD848923\\nProprietario: Pierre Moraes\\nSerial: 934800MGO291317","code":"934800MGO291317","sound":"tranca_1","barcode":"934800MGO291317","modelo":"gauntlet6","proprietario":"Pierre Moraes","plate":"AD848923"}},{"count":1,"name":"WEAPON_PISTOL","slot":23,"metadata":{"serial":"779249UIQ834880","durability":12.1,"components":[],"ammo":12,"registered":"Pierre Moraes"}},{"count":2,"name":"black_money","slot":24},{"count":1,"name":"prop_boombox_01","slot":25},{"count":1,"name":"carkey_permanent","slot":26,"metadata":{"distance":8,"motor":0,"label":"Modelo: weevil2\\nPlaca: AD412822\\nProprietario: Pierre Moraes\\nSerial: 650069OAL449954","code":"650069OAL449954","sound":"tranca_1","barcode":"650069OAL449954","modelo":"weevil2","proprietario":"Pierre Moraes","plate":"AD412822"}},{"count":1,"name":"WEAPON_FLASHLIGHT","slot":27,"metadata":{"barcode":"1787633250-83375878","components":[],"durability":100}},{"count":1,"name":"carkey_permanent","slot":28,"metadata":{"barcode":"455352RUC742529","label":"Placa: 22LWH734\\nTipo: ORIGINAL\\nSerial: 455352RUC742529","plate":"22LWH734"}},{"count":1,"name":"phone","slot":29},{"count":1,"name":"large_backpack","slot":30,"metadata":{"stash":"backpack_359021","barcode":"1786833525-39082811","backpack_code":"5f3c9366","description":"Backpack Master Mind","label":"Backpack Master Mind","profile":"master_mind"}},{"count":1,"name":"umbrella","slot":31,"metadata":{"barcode":"1787881611-90530250"}},{"count":1,"name":"carkey_permanent","slot":32,"metadata":{"distance":8,"motor":0,"label":"Modelo: coureur\\nPlaca: AD647471\\nProprietario: Pierre Moraes\\nSerial: 518674GSC277665","code":"518674GSC277665","sound":"tranca_1","barcode":"518674GSC277665","modelo":"coureur","proprietario":"Pierre Moraes","plate":"AD647471"}},{"count":1,"name":"WEAPON_APPISTOL","slot":33,"metadata":{"serial":"148740WVN200693","durability":48.40000000000004,"components":["at_flashlight"],"ammo":18,"registered":"Pierre Moraes"}},{"count":1,"name":"cola","slot":35,"metadata":{"barcode":"1787891298-57025383"}},{"count":1,"name":"cola","slot":36,"metadata":{"barcode":"1787891298-98000591"}},{"count":1,"name":"cola","slot":37,"metadata":{"barcode":"1787891298-11165222"}},{"count":1,"name":"carkey_permanent","slot":38,"metadata":{"barcode":"221286COG198368","label":"Placa: AD087784\\nTipo: ORIGINAL\\nSerial: 221286COG198368","plate":"AD087784"}},{"count":1,"name":"cola","slot":39,"metadata":{"barcode":"1787891298-17498297"}},{"count":1,"name":"cola","slot":40,"metadata":{"barcode":"1787891298-35864109"}},{"count":1,"name":"cola","slot":41,"metadata":{"barcode":"1787891298-19979019"}},{"count":1,"name":"cola","slot":42,"metadata":{"barcode":"1787891298-79076023"}},{"count":1,"name":"grapejuice","slot":44,"metadata":{"barcode":"1788014851-29054029"}},{"count":1,"name":"sandwich","slot":45,"metadata":{"barcode":"1787810930-93124847"}},{"count":1,"name":"sandwich","slot":46,"metadata":{"barcode":"1787810930-67890438"}},{"count":1,"name":"sandwich","slot":47,"metadata":{"barcode":"1787810930-19589624"}},{"count":1,"name":"sandwich","slot":48,"metadata":{"barcode":"1787810930-55153145"}},{"count":1,"name":"sandwich","slot":49,"metadata":{"barcode":"1787810930-80726371"}},{"count":1,"name":"sandwich","slot":50,"metadata":{"barcode":"1787810930-74747689"}},{"count":1,"name":"water","slot":51,"metadata":{"barcode":"1787811052-64887525"}},{"count":1,"name":"water","slot":52,"metadata":{"barcode":"1787811052-49684872"}},{"count":1,"name":"water","slot":53,"metadata":{"barcode":"1787811052-63883073"}},{"count":1,"name":"grapejuice","slot":54,"metadata":{"barcode":"1788014851-73274229"}},{"count":1,"name":"whiskey","slot":55,"metadata":{"barcode":"1787892072-00515014"}},{"count":1,"name":"sandwich","slot":56,"metadata":{"barcode":"1787810930-32555258"}},{"count":1,"name":"sandwich","slot":57,"metadata":{"barcode":"1787810930-40835412"}},{"count":1,"name":"water","slot":58,"metadata":{"barcode":"1787811052-03005952"}},{"count":4,"name":"remedio_magico","slot":60}]', '6635274266', 1788635038000.0, 1788492237000.0, NULL, '{"reports":0,"admin":0,"driving":0,"staff":0,"delivery":0,"strength":0,"fram":0,"stamina":0,"performance":0,"suport":0,"duvidas":0,"lung":0,"runner":0,"shooting":0,"jobs":0}');

-- Structure for `playerskins`
DROP TABLE IF EXISTS `playerskins`;
CREATE TABLE `playerskins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(255) NOT NULL,
  `model` varchar(255) NOT NULL,
  `skin` text NOT NULL,
  `active` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `active` (`active`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Data for `playerskins`
INSERT INTO `playerskins` (`id`, `citizenid`, `model`, `skin`, `active`) VALUES
(26, 'RE036OYR', 'mp_m_freemode_01', '{"tattoos":{"ZONE_RIGHT_LEG":[{"hashFemale":"MP_Smuggler_Tattoo_020_F","label":"Homeward Bound","opacity":0.2,"zone":"ZONE_RIGHT_LEG","name":"TAT_SM_020","collection":"mpsmuggler_overlays","hashMale":"MP_Smuggler_Tattoo_020_M"}],"ZONE_LEFT_LEG":[{"hashFemale":"FM_Tat_F_023","label":"Hottie","opacity":0.2,"zone":"ZONE_LEFT_LEG","name":"TAT_FM_224","collection":"multiplayer_overlays","hashMale":"FM_Tat_M_023"},{"hashFemale":"MP_MP_Biker_Tat_044_F","label":"Ride Free","opacity":0.1,"zone":"ZONE_LEFT_LEG","name":"TAT_BI_044","collection":"mpbiker_overlays","hashMale":"MP_MP_Biker_Tat_044_M"}],"ZONE_HAIR":[{"hashFemale":"FM_F_Hair_003_e","label":"hair-0-190","opacity":0.1,"zone":"ZONE_HAIR","name":"hair-0-190","collection":"multiplayer_overlays","hashMale":"FM_M_Hair_003_e"}],"ZONE_HEAD":[{"hashFemale":"","label":"Cash is King","opacity":0.2,"zone":"ZONE_HEAD","name":"TAT_BUS_005","collection":"mpbusiness_overlays","hashMale":"MP_Buis_M_Neck_000"},{"hashFemale":"","label":"Surf LS","opacity":0.2,"zone":"ZONE_HEAD","name":"TAT_BB_022","collection":"mpbeach_overlays","hashMale":"MP_Bea_M_Head_001"},{"hashFemale":"MP_Security_Tat_027_F","label":"Black Widow","opacity":0.1,"zone":"ZONE_HEAD","name":"TAT_FX_027","collection":"mpsecurity_overlays","hashMale":"MP_Security_Tat_027_M"}],"ZONE_TORSO":[{"hashFemale":"MP_Smuggler_Tattoo_003_F","label":"Give Nothing Back","opacity":0.2,"zone":"ZONE_TORSO","name":"TAT_SM_003","collection":"mpsmuggler_overlays","hashMale":"MP_Smuggler_Tattoo_003_M"},{"hashFemale":"MP_Vinewood_Tat_011_F","label":"Life''s a Gamble","opacity":0.1,"zone":"ZONE_TORSO","name":"TAT_VW_011","collection":"mpvinewood_overlays","hashMale":"MP_Vinewood_Tat_011_M"},{"hashFemale":"MP_MP_Biker_Tat_058_F","label":"Reaper Vulture","opacity":0.1,"zone":"ZONE_TORSO","name":"TAT_BI_058","collection":"mpbiker_overlays","hashMale":"MP_MP_Biker_Tat_058_M"},{"hashFemale":"MP_LR_Tat_012_F","label":"Royal Kiss","opacity":0.1,"zone":"ZONE_TORSO","name":"TAT_S2_012","collection":"mplowrider2_overlays","hashMale":"MP_LR_Tat_012_M"}]},"props":[{"texture":-1,"drawable":-1,"prop_id":0},{"texture":9,"drawable":20,"prop_id":1},{"texture":-1,"drawable":-1,"prop_id":2},{"texture":-1,"drawable":-1,"prop_id":6},{"texture":-1,"drawable":-1,"prop_id":7}],"eyeColor":2,"hair":{"color":32,"texture":0,"highlight":35,"style":3},"model":"mp_m_freemode_01","faceFeatures":{"nosePeakLowering":0,"nosePeakSize":0,"chinHole":0,"cheeksBoneHigh":0,"jawBoneBackSize":0,"eyeBrownHigh":0,"noseBoneHigh":0,"noseWidth":0,"cheeksBoneWidth":0,"cheeksWidth":0,"neckThickness":0,"eyesOpening":0,"noseBoneTwist":0,"chinBoneSize":0,"chinBoneLenght":0,"jawBoneWidth":0,"lipsThickness":0,"chinBoneLowering":0,"eyeBrownForward":0,"nosePeakHigh":0},"headOverlays":{"makeUp":{"secondColor":0,"style":0,"opacity":0,"color":0},"moleAndFreckles":{"secondColor":0,"style":0,"opacity":0,"color":0},"bodyBlemishes":{"secondColor":0,"style":0,"opacity":0,"color":0},"ageing":{"secondColor":0,"style":0,"opacity":0,"color":0},"blemishes":{"secondColor":0,"style":0,"opacity":1,"color":0},"sunDamage":{"secondColor":0,"style":0,"opacity":0,"color":0},"beard":{"secondColor":0,"style":0,"opacity":0,"color":0},"lipstick":{"secondColor":0,"style":0,"opacity":0,"color":0},"chestHair":{"secondColor":0,"style":0,"opacity":0,"color":0},"complexion":{"secondColor":0,"style":0,"opacity":0,"color":0},"blush":{"secondColor":0,"style":0,"opacity":0,"color":0},"eyebrows":{"secondColor":0,"style":12,"opacity":1,"color":0}},"headBlend":{"thirdMix":0,"shapeMix":0,"shapeSecond":0,"skinFirst":0,"shapeThird":0,"skinSecond":0,"skinThird":0,"skinMix":0,"shapeFirst":0},"components":[{"texture":0,"component_id":0,"drawable":0},{"texture":13,"component_id":1,"drawable":169},{"texture":0,"component_id":2,"drawable":3},{"texture":0,"component_id":3,"drawable":202},{"texture":0,"component_id":4,"drawable":123},{"texture":0,"component_id":5,"drawable":0},{"texture":9,"component_id":6,"drawable":32},{"texture":0,"component_id":7,"drawable":0},{"texture":0,"component_id":8,"drawable":170},{"texture":0,"component_id":9,"drawable":0},{"texture":0,"component_id":10,"drawable":0},{"texture":3,"component_id":11,"drawable":349}]}', 1),
(27, 'M6YW58XY', 'mp_f_freemode_01', '{"model":"mp_f_freemode_01","headOverlays":{"complexion":{"secondColor":0,"style":0,"color":0,"opacity":0},"chestHair":{"secondColor":0,"style":0,"color":0,"opacity":0},"blush":{"secondColor":0,"style":0,"color":0,"opacity":0},"makeUp":{"secondColor":0,"style":0,"color":0,"opacity":0},"bodyBlemishes":{"secondColor":0,"style":0,"color":0,"opacity":0},"lipstick":{"secondColor":0,"style":0,"color":0,"opacity":0},"blemishes":{"secondColor":0,"style":0,"color":0,"opacity":0},"eyebrows":{"secondColor":0,"style":0,"color":0,"opacity":0},"sunDamage":{"secondColor":0,"style":0,"color":0,"opacity":0},"moleAndFreckles":{"secondColor":0,"style":0,"color":0,"opacity":0},"ageing":{"secondColor":0,"style":0,"color":0,"opacity":0},"beard":{"secondColor":0,"style":0,"color":0,"opacity":0}},"tattoos":[],"props":[{"texture":-1,"drawable":-1,"prop_id":0},{"texture":-1,"drawable":-1,"prop_id":1},{"texture":-1,"drawable":-1,"prop_id":2},{"texture":-1,"drawable":-1,"prop_id":6},{"texture":-1,"drawable":-1,"prop_id":7}],"faceFeatures":{"nosePeakHigh":0,"chinBoneLenght":0,"chinBoneSize":0,"eyeBrownForward":0,"jawBoneWidth":0,"cheeksWidth":0,"eyesOpening":0,"eyeBrownHigh":0,"jawBoneBackSize":0,"cheeksBoneWidth":0,"chinHole":0,"noseBoneTwist":0,"noseBoneHigh":0,"nosePeakLowering":0,"cheeksBoneHigh":0,"noseWidth":0,"neckThickness":0,"nosePeakSize":0,"lipsThickness":0,"chinBoneLowering":0},"components":[{"texture":0,"drawable":0,"component_id":0},{"texture":0,"drawable":0,"component_id":1},{"texture":0,"drawable":0,"component_id":2},{"texture":0,"drawable":0,"component_id":3},{"texture":0,"drawable":0,"component_id":4},{"texture":0,"drawable":0,"component_id":5},{"texture":0,"drawable":0,"component_id":6},{"texture":0,"drawable":0,"component_id":7},{"texture":0,"drawable":0,"component_id":8},{"texture":0,"drawable":0,"component_id":9},{"texture":0,"drawable":0,"component_id":10},{"texture":0,"drawable":0,"component_id":11}],"headBlend":{"shapeThird":0,"skinMix":0.1,"shapeFirst":45,"shapeSecond":21,"thirdMix":0,"skinFirst":20,"shapeMix":0.3,"skinThird":0,"skinSecond":15},"eyeColor":0,"hair":{"texture":0,"style":0,"color":0,"highlight":0}}', 1);

-- Structure for `police_impound`
DROP TABLE IF EXISTS `police_impound`;
CREATE TABLE `police_impound` (
  `citizenid` varchar(50) NOT NULL,
  `plate` varchar(50) DEFAULT NULL,
  `vehicle` longtext DEFAULT NULL,
  `props` longtext DEFAULT NULL,
  `owner` longtext DEFAULT NULL,
  `officer` longtext DEFAULT NULL,
  `date` longtext NOT NULL,
  `fine` bigint(20) DEFAULT 0,
  `paid` tinyint(4) DEFAULT 0,
  `garage` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `pr_bomboxplaylists`
DROP TABLE IF EXISTS `pr_bomboxplaylists`;
CREATE TABLE `pr_bomboxplaylists` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user` varchar(255) NOT NULL,
  `playlist` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pr_bomboxsongs`
DROP TABLE IF EXISTS `pr_bomboxsongs`;
CREATE TABLE `pr_bomboxsongs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `playlist_id` int(11) DEFAULT NULL,
  `url` varchar(255) NOT NULL DEFAULT '0',
  `name` varchar(150) NOT NULL DEFAULT '0',
  `author` varchar(50) NOT NULL DEFAULT '0',
  `maxDuration` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `playlist_id` (`playlist_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pr_boomboxplaylists`
DROP TABLE IF EXISTS `pr_boomboxplaylists`;
CREATE TABLE `pr_boomboxplaylists` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user` varchar(255) NOT NULL,
  `playlist` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pr_boomboxsongs`
DROP TABLE IF EXISTS `pr_boomboxsongs`;
CREATE TABLE `pr_boomboxsongs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `playlist_id` int(11) DEFAULT NULL,
  `url` varchar(255) NOT NULL DEFAULT '0',
  `name` varchar(150) NOT NULL DEFAULT '0',
  `author` varchar(50) NOT NULL DEFAULT '0',
  `maxDuration` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `playlist_id` (`playlist_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pr_carkeys`
DROP TABLE IF EXISTS `pr_carkeys`;
CREATE TABLE `pr_carkeys` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `barcode` varchar(20) NOT NULL COMMENT 'Código de barras único da chave (metadata)',
  `citizenid` varchar(50) NOT NULL COMMENT 'CitizenID do dono da chave',
  `plate` varchar(15) NOT NULL COMMENT 'Placa do veículo',
  `key_type` varchar(20) NOT NULL DEFAULT 'permanent' COMMENT 'permanent | temporary | single_use',
  `sound` varchar(50) NOT NULL DEFAULT 'lock' COMMENT 'Nome do som configurado',
  `motor` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 = liga motor ao destrancar',
  `level` varchar(20) NOT NULL DEFAULT 'original' COMMENT 'original | copy',
  `distance` float NOT NULL DEFAULT 5 COMMENT 'Distância do sinal (metros)',
  `expires_at` bigint(20) DEFAULT NULL COMMENT 'Timestamp UNIX de expiração (apenas temporary)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `barcode` (`barcode`),
  KEY `idx_barcode` (`barcode`),
  KEY `idx_citizenid` (`citizenid`),
  KEY `idx_plate` (`plate`)
) ENGINE=InnoDB AUTO_INCREMENT=142 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci COMMENT='Configurações individuais das chaves de veículo';

-- Data for `pr_carkeys`
INSERT INTO `pr_carkeys` (`id`, `barcode`, `citizenid`, `plate`, `key_type`, `sound`, `motor`, `level`, `distance`, `expires_at`, `created_at`) VALUES
(121, '831792AJA555813', 'RE036OYR', '66LRM325', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1784935361000.0),
(122, '215910JLM764854', 'RE036OYR', '5TS706NB', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1784935633000.0),
(123, '261951RQV200766', 'RE036OYR', '89KYG626', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1784938210000.0),
(124, '690069VCP446894', 'RE036OYR', '45YRP591', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1784938700000.0),
(125, '693650VMZ968300', 'RE036OYR', '09QZC287', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1784939234000.0),
(126, '959079LKP442039', 'RE036OYR', '09QZC287', 'permanent', 'tranca_1', 0, 'copy', 8, NULL, 1784939381000.0),
(127, '969643SPD874216', 'RE036OYR', '86IDP629', 'permanent', 'tranca_2', 1, 'original', 30, NULL, 1785002818000.0),
(128, '672248MXB342423', 'RE036OYR', '41LGZ479', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1785003525000.0),
(129, '400890KBW379335', 'RE036OYR', '29SEZ734', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1785004236000.0),
(130, '909020SJB333207', 'RE036OYR', '63AVE439', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1785004816000.0),
(131, '821217GKW255987', 'RE036OYR', '04UKY513', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1785027924000.0),
(132, '780546ZLM613045', 'RE036OYR', '04UKY513', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1785028032000.0),
(133, '970871NXZ173655', 'RE036OYR', '02RRH076', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1785028063000.0),
(134, '727905PEO378993', 'RE036OYR', '04UKY513', 'permanent', 'tranca_2', 1, 'original', 30, NULL, 1785034354000.0),
(135, '960810XXP316774', 'RE036OYR', 'O4UKY513', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1785035458000.0),
(136, '761282RWF232469', 'RE036OYR', '41LGZ479', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1785130194000.0),
(137, '934800MGO291317', 'RE036OYR', 'AD848923', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1787629701000.0),
(138, '650069OAL449954', 'RE036OYR', 'AD412822', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1787630029000.0),
(139, '455352RUC742529', 'RE036OYR', '22LWH734', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1787630072000.0),
(140, '221286COG198368', 'RE036OYR', 'AD087784', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1787712615000.0),
(141, '518674GSC277665', 'RE036OYR', 'AD647471', 'permanent', 'tranca_1', 0, 'original', 8, NULL, 1788138474000.0);

-- Structure for `pr_elevator_elevator`
DROP TABLE IF EXISTS `pr_elevator_elevator`;
CREATE TABLE `pr_elevator_elevator` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL COMMENT 'Nome do elevador',
  `type` varchar(50) NOT NULL DEFAULT 'public' COMMENT 'Tipo de acesso',
  `job` varchar(50) DEFAULT NULL COMMENT 'Nome do emprego/gang',
  `job_grade` int(11) DEFAULT 0 COMMENT 'Nivel de cargo minimo',
  `password` varchar(50) DEFAULT NULL COMMENT 'Senha de acesso',
  `access_key` varchar(50) DEFAULT NULL COMMENT 'Chave de acesso do cartao',
  `citizenid` varchar(50) DEFAULT NULL COMMENT 'CitizenID do player',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Data for `pr_elevator_elevator`
INSERT INTO `pr_elevator_elevator` (`id`, `name`, `type`, `job`, `job_grade`, `password`, `access_key`, `citizenid`) VALUES
(4, 'Teste', 'public', NULL, NULL, NULL, NULL, NULL);

-- Structure for `pr_elevator_floor`
DROP TABLE IF EXISTS `pr_elevator_floor`;
CREATE TABLE `pr_elevator_floor` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID do andar - 1 id por andar!',
  `elevator_id` int(11) NOT NULL COMMENT 'ID do elevador',
  `name` varchar(50) NOT NULL DEFAULT 'Andar' COMMENT 'Nome de exibicao do andar (ex: T, S1)',
  `floor` int(11) DEFAULT 0 COMMENT 'Ordem/Numero do andar',
  `distance` float DEFAULT 2 COMMENT 'Distância necessária para interagir com o elevador',
  `theme_color` varchar(50) DEFAULT NULL COMMENT 'Cor do tema',
  `theme_background` varchar(50) DEFAULT NULL COMMENT 'Cor do fundo do tema',
  `coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Coordenadas de spawn',
  `interact_coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Payload de interacao: vector3 legado ou prop DUI',
  `access_type` varchar(50) NOT NULL DEFAULT 'public' COMMENT 'Tipo de acesso do andar',
  `access_job` varchar(50) DEFAULT NULL COMMENT 'Emprego/gang do andar',
  `access_job_grade` int(11) DEFAULT 0 COMMENT 'Nivel minimo do emprego/gang',
  `access_password` varchar(50) DEFAULT NULL COMMENT 'Senha do andar',
  `access_key` varchar(50) DEFAULT NULL COMMENT 'Metadata/chave do cartao',
  `access_item` varchar(50) DEFAULT NULL COMMENT 'Item de cartao exigido',
  `access_citizenid` varchar(50) DEFAULT NULL COMMENT 'CitizenID permitido no andar',
  PRIMARY KEY (`id`),
  KEY `fk_elevator_floor_elevator` (`elevator_id`),
  CONSTRAINT `fk_elevator_floor_elevator` FOREIGN KEY (`elevator_id`) REFERENCES `pr_elevator_elevator` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Data for `pr_elevator_floor`
INSERT INTO `pr_elevator_floor` (`id`, `elevator_id`, `name`, `floor`, `distance`, `theme_color`, `theme_background`, `coords`, `interact_coords`, `access_type`, `access_job`, `access_job_grade`, `access_password`, `access_key`, `access_item`, `access_citizenid`) VALUES
(7, 4, 'T', 1, 2, '#00F8B8', '#1E7F7E', '{"y":-988.79,"z":30.69,"heading":359.08,"x":446.44}', '{"type":"prop","coords":{"y":-989.1671,"z":31.0767,"x":446.4805},"model":-935024926,"rotation":{"y":0.0,"z":-178.3627,"x":0.0},"mode":"dui","heading":181.6373,"modelName":"ch_prop_casino_keypad_01"}', 'password', NULL, 0, '0000', NULL, NULL, NULL),
(8, 4, 'S1', 2, 2, '#00F8B8', '#1E7F7E', '{"y":-988.18,"z":26.75,"heading":358.76,"x":449.16}', '{"type":"prop","coords":{"y":-988.7992,"z":27.2005,"x":449.1844},"model":-935024926,"rotation":{"y":0.0,"z":-179.8208,"x":0.0},"mode":"dui","heading":180.1792,"modelName":"ch_prop_casino_keypad_01"}', 'public', NULL, 0, NULL, NULL, NULL, NULL);

-- Structure for `pr_nitrous`
DROP TABLE IF EXISTS `pr_nitrous`;
CREATE TABLE `pr_nitrous` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plate` varchar(255) NOT NULL,
  `kitnitro` int(11) NOT NULL DEFAULT 0,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `bottleamount` int(11) NOT NULL DEFAULT 0,
  `bottletype` varchar(64) NOT NULL DEFAULT '',
  `usage` float NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate` (`plate`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pr_placeable_item`
DROP TABLE IF EXISTS `pr_placeable_item`;
CREATE TABLE `pr_placeable_item` (
  `id` varchar(50) DEFAULT NULL,
  `model` int(11) DEFAULT NULL,
  `item` varchar(50) DEFAULT NULL,
  `quantity` int(11) DEFAULT 1,
  `is_box` tinyint(1) DEFAULT 0,
  `freeze` tinyint(1) DEFAULT 1,
  `in_vehicle` tinyint(1) DEFAULT 0,
  `vehicle_plate` varchar(50) DEFAULT NULL,
  `vehicle_offset_x` float DEFAULT 0,
  `vehicle_offset_y` float DEFAULT 0,
  `vehicle_offset_z` float DEFAULT 0,
  `vehicle_offset_h` float DEFAULT 0,
  `x` float DEFAULT NULL,
  `y` float DEFAULT NULL,
  `z` float DEFAULT NULL,
  `heading` float DEFAULT NULL,
  `citizen` varchar(50) DEFAULT NULL,
  `metadata` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pr_stance`
DROP TABLE IF EXISTS `pr_stance`;
CREATE TABLE `pr_stance` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plate` varchar(15) NOT NULL COMMENT 'Placa do veiculo',
  `vehicle_meta` mediumtext DEFAULT '{}' COMMENT 'Metadata da handling completa salva do veiculo',
  `config_meta` mediumtext DEFAULT '{}' COMMENT 'Configuracao e preferencias completa da suspensao',
  `suspension` int(11) NOT NULL DEFAULT 0 COMMENT 'Suspensao instalada = 1 | nao instalada = 0',
  `cambage` int(11) NOT NULL DEFAULT 0 COMMENT 'Kit Cambagem instalada = 1 | nao instalada = 0',
  `angle` int(11) NOT NULL DEFAULT 0 COMMENT 'Kit Angulo instalada = 1 | nao instalada = 0',
  `shock` int(11) NOT NULL DEFAULT 0 COMMENT 'Amortecedor instalada = 1 | nao instalada = 0',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_plate` (`plate`)
) ENGINE=InnoDB AUTO_INCREMENT=3709 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci COMMENT='Configuracoes individuais de veiculo';

-- Structure for `pr_truck_areas`
DROP TABLE IF EXISTS `pr_truck_areas`;
CREATE TABLE `pr_truck_areas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `description` text DEFAULT NULL,
  `vehicle_zone` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `unload_zone` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `pr_truck_player_prizes`
DROP TABLE IF EXISTS `pr_truck_player_prizes`;
CREATE TABLE `pr_truck_player_prizes` (
  `identifier` varchar(64) NOT NULL,
  `prize_id` int(11) NOT NULL,
  `claimed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`identifier`,`prize_id`),
  KEY `fk_pr_truck_player_prizes_id` (`prize_id`),
  CONSTRAINT `fk_pr_truck_player_prizes_id` FOREIGN KEY (`prize_id`) REFERENCES `pr_truck_prizes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `pr_truck_player_tablet_settings`
DROP TABLE IF EXISTS `pr_truck_player_tablet_settings`;
CREATE TABLE `pr_truck_player_tablet_settings` (
  `identifier` varchar(64) NOT NULL,
  `citizenid` varchar(64) DEFAULT NULL,
  `language` varchar(12) NOT NULL DEFAULT 'pt-BR',
  `theme` enum('dark','light') NOT NULL DEFAULT 'dark',
  `notifications_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `tablet_scale` float NOT NULL DEFAULT 1,
  `xp` int(11) NOT NULL DEFAULT 0,
  `level` int(11) NOT NULL DEFAULT 1,
  `earnings` int(11) NOT NULL DEFAULT 0,
  `deliveries` int(11) NOT NULL DEFAULT 0,
  `rating` float NOT NULL DEFAULT 0,
  `success_rate` float NOT NULL DEFAULT 0,
  `partner_earnings` int(11) NOT NULL DEFAULT 0,
  `partner_deliveries` int(11) NOT NULL DEFAULT 0,
  `partner_rating` float NOT NULL DEFAULT 0,
  `partner_success_rate` float NOT NULL DEFAULT 0,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`identifier`),
  KEY `idx_pr_truck_player_tablet_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `pr_truck_prizes`
DROP TABLE IF EXISTS `pr_truck_prizes`;
CREATE TABLE `pr_truck_prizes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `level_required` int(11) NOT NULL,
  `title` varchar(128) NOT NULL,
  `description` text DEFAULT NULL,
  `image` varchar(255) NOT NULL,
  `rewards` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `pr_truck_tablet_settings`
DROP TABLE IF EXISTS `pr_truck_tablet_settings`;
CREATE TABLE `pr_truck_tablet_settings` (
  `id` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `default_language` varchar(12) NOT NULL DEFAULT 'en',
  `default_theme` enum('dark','light') NOT NULL DEFAULT 'light',
  `allow_light_theme` tinyint(1) NOT NULL DEFAULT 1,
  `notifications_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `tablet_scale` float NOT NULL DEFAULT 1,
  `vehicle_img_url` text DEFAULT NULL,
  `peds_img_url` text DEFAULT NULL,
  `ox_inventory_img_path` text DEFAULT NULL,
  `ox_inventory_items_path` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `pr_truck_transporters`
DROP TABLE IF EXISTS `pr_truck_transporters`;
CREATE TABLE `pr_truck_transporters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `description` text DEFAULT NULL,
  `level_required` int(11) NOT NULL DEFAULT 0,
  `banner` text DEFAULT NULL,
  `vehicle_spawn` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `trailer_spawn` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `assistant_spawn` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `ped_spawn` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `fiscal_spawn` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `freight_spawn` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `pr_truck_xp_tablet`
DROP TABLE IF EXISTS `pr_truck_xp_tablet`;
CREATE TABLE `pr_truck_xp_tablet` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lvl_id` int(11) NOT NULL,
  `label` varchar(50) NOT NULL,
  `xp_value` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `pr_vehicle_config`
DROP TABLE IF EXISTS `pr_vehicle_config`;
CREATE TABLE `pr_vehicle_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `sms` varchar(255) NOT NULL,
  `location` text NOT NULL,
  `start_carreata` text NOT NULL,
  `end_carreata` text NOT NULL,
  `duration` int(11) NOT NULL DEFAULT 0,
  `xp` int(11) NOT NULL DEFAULT 0,
  `xp_engine_on` int(11) NOT NULL DEFAULT 0,
  `xp_owner_in_area` int(11) NOT NULL DEFAULT 0,
  `xp_hood_open` int(11) NOT NULL DEFAULT 0,
  `time` varchar(10) NOT NULL DEFAULT '00:00',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pr_vehicle_scenario`
DROP TABLE IF EXISTS `pr_vehicle_scenario`;
CREATE TABLE `pr_vehicle_scenario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `event_id` int(11) NOT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_vehicle_event` (`event_id`),
  CONSTRAINT `fk_vehicle_event` FOREIGN KEY (`event_id`) REFERENCES `pr_vehicle_config` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pr_vehicle_sounds`
DROP TABLE IF EXISTS `pr_vehicle_sounds`;
CREATE TABLE `pr_vehicle_sounds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plate` varchar(50) NOT NULL,
  `data` longtext NOT NULL,
  `created` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_plate` (`plate`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pr_vehicle_xp`
DROP TABLE IF EXISTS `pr_vehicle_xp`;
CREATE TABLE `pr_vehicle_xp` (
  `plate` varchar(50) NOT NULL,
  `exp` int(11) NOT NULL DEFAULT 0,
  `points` int(11) NOT NULL DEFAULT 0,
  `voted` int(11) NOT NULL DEFAULT 0,
  `text` varchar(255) NOT NULL DEFAULT '0',
  PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pr_vehiclekeys`
DROP TABLE IF EXISTS `pr_vehiclekeys`;
CREATE TABLE `pr_vehiclekeys` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL COMMENT 'Identifier do player (citizenid/identifier)',
  `plate` varchar(20) NOT NULL COMMENT 'Placa do veículo (sem espaços)',
  `vehicle_model` varchar(100) NOT NULL DEFAULT 'Desconhecido' COMMENT 'Nome/modelo do veículo',
  `key_type` enum('permanent','temporary','onetime') NOT NULL DEFAULT 'permanent',
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Metadados extras da chave',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `sound` varchar(100) DEFAULT NULL COMMENT 'Toque de tranca desta chave',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_citizen_plate` (`citizenid`,`plate`),
  KEY `idx_citizenid` (`citizenid`),
  KEY `idx_plate` (`plate`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `properties`
DROP TABLE IF EXISTS `properties`;
CREATE TABLE `properties` (
  `property_id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_citizenid` varchar(50) DEFAULT NULL,
  `street` varchar(100) DEFAULT NULL,
  `region` varchar(100) DEFAULT NULL,
  `description` longtext DEFAULT NULL,
  `has_access` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT json_array() CHECK (json_valid(`has_access`)),
  `extra_imgs` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT json_array() CHECK (json_valid(`extra_imgs`)),
  `furnitures` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT json_array() CHECK (json_valid(`furnitures`)),
  `for_sale` tinyint(1) NOT NULL DEFAULT 1,
  `price` int(11) NOT NULL DEFAULT 0,
  `shell` varchar(50) NOT NULL,
  `apartment` varchar(50) DEFAULT NULL,
  `door_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`door_data`)),
  `garage_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`garage_data`)),
  `zone_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`zone_data`)),
  `admin_access` longtext DEFAULT NULL,
  `tax_data` longtext DEFAULT NULL,
  `house_object` longtext DEFAULT NULL,
  PRIMARY KEY (`property_id`),
  UNIQUE KEY `UQ_owner_apartment` (`owner_citizenid`,`apartment`),
  CONSTRAINT `FK_owner_citizenid` FOREIGN KEY (`owner_citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Data for `properties`
INSERT INTO `properties` (`property_id`, `owner_citizenid`, `street`, `region`, `description`, `has_access`, `extra_imgs`, `furnitures`, `for_sale`, `price`, `shell`, `apartment`, `door_data`, `garage_data`, `zone_data`, `admin_access`, `tax_data`, `house_object`) VALUES
(4, 'RE036OYR', 'Marina Drive', 'Sandy Shores', 'Casa do trevor modelinho trailer', '[]', '[{"label":"1","url":"https://static.wikia.nocookie.net/playstationallstarsfanfictionroyale/images/1/1c/Michael_House.jpg/revision/latest?cb=20140529000932 https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) undefined https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) https://static.wikia.nocookie.net/playstationallstarsfanfictionroyale/images/1/1c/Michael_House.jpg/revision/latest?cb=20140529000932 https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) https://i.redd.it/d37evjb6enhd1.jpeg https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) https://static.wikia.nocookie.net/playstationallstarsfanfictionroyale/images/1/1c/Michael_House.jpg/revision/latest?cb=20140529000932 https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) undefined https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) https://static.wikia.nocookie.net/playstationallstarsfanfictionroyale/images/1/1c/Michael_House.jpg/revision/latest?cb=20140529000932 https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) https://i.redd.it/d37evjb6enhd1.jpeg https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) https://static.wikia.nocookie.net/playstationallstarsfanfictionroyale/images/1/1c/Michael_House.jpg/revision/latest?cb=20140529000932 https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) undefined https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9)"},{"label":"2","url":"https://static.wikia.nocookie.net/playstationallstarsfanfictionroyale/images/1/1c/Michael_House.jpg/revision/latest?cb=20140529000932 https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) undefined https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) https://static.wikia.nocookie.net/playstationallstarsfanfictionroyale/images/1/1c/Michael_House.jpg/revision/latest?cb=20140529000932 https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) https://i.redd.it/d37evjb6enhd1.jpeg https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) https://static.wikia.nocookie.net/playstationallstarsfanfictionroyale/images/1/1c/Michael_House.jpg/revision/latest?cb=20140529000932 https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) undefined https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) https://static.wikia.nocookie.net/playstationallstarsfanfictionroyale/images/1/1c/Michael_House.jpg/revision/latest?cb=20140529000932 https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) https://i.redd.it/d37evjb6enhd1.jpeg https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) https://static.wikia.nocookie.net/playstationallstarsfanfictionroyale/images/1/1c/Michael_House.jpg/revision/latest?cb=20140529000932 https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9) undefined https://files.fivemerr.com/images/e39bd4a6-bc3f-41e7-876e-cc03d77f953b.jpg (@ps-realtor/html/index.js:9)"}]', '[{"position":{"z":32.61,"x":1975.2553,"y":3818.6333},"label":"Chairl","id":"5217934","object":"v_res_fa_chair01","rotation":{"x":0.0,"y":-0.0,"z":116.99998474121094}},{"position":{"z":33.11,"x":1975.3913,"y":3819.998},"label":"High chair","id":"9171034","object":"v_res_d_highchair","rotation":{"x":0.0,"y":0.0,"z":33.99999618530273}}]', 0, 500, 'mlo', NULL, '{"count":2}', '[]', '{"thickness":5.0,"points":[{"x":1995.96,"y":3819.1,"z":31.19},{"x":1963.05,"y":3799.52,"z":31.19},{"x":1956.8,"y":3819.27,"z":31.19},{"x":1987.06,"y":3837.85,"z":31.19}],"maxZ":36.19,"minZ":31.19}', NULL, NULL, NULL),
(5, 'RE036OYR', 'Algonquin Boulevard', 'Sandy Shores', 'Casa teste Shell.', '[]', '[]', '[{"position":{"x":1927.4036,"z":31.28,"y":3820.477},"rotation":{"x":0.0,"z":0.0,"y":-0.0},"id":"2107085","object":"v_res_msonbed","label":"Bed 3"},{"position":{"x":1925.55,"z":31.26,"y":3820.7595},"rotation":{"x":0.0,"z":0.0,"y":-0.0},"id":"9373185","object":"v_res_m_lampstand","label":"Lamp Stand"},{"position":{"x":-6.259,"z":-1.49,"y":2.4445},"rotation":{"x":0.0,"z":84.99999237060547,"y":0.0},"area":"interior","id":"5-362234-753457","object":"v_res_tre_bed2","label":"T Bed"}]', 0, 200, 'Apartment Unfurnished', NULL, '{"x":1925.21,"locked":false,"y":3824.37,"z":32.43,"h":30.32,"width":2.2,"length":1.5}', '[]', '{"points":[{"z":31.25,"x":1903.39,"y":3832.51},{"z":31.25,"x":1922.88,"y":3845.7},{"z":31.25,"x":1938.56,"y":3817.65},{"z":31.25,"x":1918.6,"y":3806.67}],"thickness":5.0,"maxZ":36.25,"minZ":31.25}', NULL, NULL, NULL),
(9, NULL, 'Niland Avenue', 'Sandy Shores', 'jklkjlkjljkl', '[]', '[]', '[]', 1, 55, 'House 1', NULL, '[{"length":1.5,"width":2.2,"locked":true,"z":32.8,"x":1901.37,"h":115.21,"y":3782.65}]', '[]', '{"points":[{"z":31.28,"x":1918.12,"y":3771.86},{"z":31.28,"x":1872.15,"y":3740.15},{"z":31.28,"x":1843.82,"y":3801.43},{"z":31.28,"x":1889.51,"y":3822.35},{"z":31.28,"x":1916.99,"y":3795.03}],"minZ":31.28,"maxZ":36.28,"thickness":5.0}', '[]', '{"luz":{"amount":2,"nextDueAt":0,"intervalDays":7,"label":"Luz","balance":0},"iptu":{"amount":2,"nextDueAt":0,"intervalDays":30,"label":"IPTU","balance":0},"agua":{"amount":2,"nextDueAt":0,"intervalDays":7,"label":"Agua","balance":0}}', NULL),
(10, 'RE036OYR', 'Algonquin Boulevard', 'Sandy Shores', 'Casa Sandy 111', '[]', '[]', '[{"object":"prop_ld_farm_couch02","clothing":false,"rotation":{"z":0.0,"y":0.0,"x":0.0},"id":"10-629570-956025","position":{"z":-1.03,"y":-5.75,"x":2.15},"area":"interior","label":"Old striped couch"},{"object":"v_res_m_dinechair","clothing":false,"rotation":{"z":-95.0,"y":0.0,"x":0.0},"id":"10-793917-773326","position":{"z":24.0099,"y":-2.6358,"x":0.7335},"area":"interior","label":"Kitchen chair 5"},{"object":"v_res_j_dinechair","clothing":false,"rotation":{"z":-62.99999618530273,"y":0.0,"x":0.0},"id":"10-793917-528419","position":{"z":33.65,"y":3741.3693,"x":1775.3336},"area":"garden","label":"Kitchen chair 4"},{"object":"v_res_m_armoire","type":"clothing","clothing":true,"rotation":{"z":0.0,"y":0.0,"x":0.0},"area":"interior","id":"10-2988841-846830","safe":{"enable":false,"weight":10000,"slots":12},"position":{"z":-1.56,"y":3.52,"x":4.72},"trunk":{"enable":false,"weight":10000,"slots":12},"label":"Armoire Unit"}]', 0, 333, 'House 1', NULL, '[{"length":1.5,"z":34.65,"locked":true,"y":3742.7,"width":2.2,"x":1774.57,"h":300.5},{"length":1.5,"z":34.65,"locked":true,"y":3738.22,"width":2.2,"x":1777.12,"h":288.22}]', '{"name":"Garagem Algonquin Boulevard #10","provider":"forge-garage","public":true}', '{"minZ":30.27,"points":[{"y":3768.27,"z":30.27,"x":1784.66},{"y":3736.9,"z":30.27,"x":1803.72},{"y":3719.03,"z":30.27,"x":1773.01},{"y":3746.74,"z":30.27,"x":1757.38},{"y":3749.58,"z":30.27,"x":1757.02},{"y":3752.38,"z":30.27,"x":1758.24}],"thickness":11.25,"maxZ":41.52}', '[]', '{"iptu":{"intervalDays":1,"label":"IPTU","nextDueAt":1788715606,"amount":3,"balance":102},"luz":{"intervalDays":1,"label":"Luz","nextDueAt":1788715606,"amount":1,"balance":34},"agua":{"intervalDays":1,"label":"Agua","nextDueAt":1788715606,"amount":2,"balance":68}}', NULL),
(11, 'RE036OYR', 'Goma Street', 'La Puerta', 'AP do Trevor Palme Beach', '[]', '[]', '[{"rotation":{"z":-120.99999237060547,"x":0.0,"y":0.0},"position":{"z":10.14,"x":-1153.3034,"y":-1516.8858},"label":"Old chair","id":"11-934772-964971","object":"prop_ld_farm_chair01","area":"interior"}]', 0, 2222, 'mlo', NULL, '{"count":4}', '{"name":"Garagem Goma Street #11","provider":"forge-garage","public":true}', '{"points":[{"z":3.38,"x":-1165.52,"y":-1519.85},{"z":3.38,"x":-1147.19,"y":-1506.74},{"z":3.38,"x":-1139.43,"y":-1518.28},{"z":3.38,"x":-1157.86,"y":-1530.67}],"minZ":3.38,"thickness":10.25,"maxZ":13.63}', '[]', '{"iptu":{"intervalDays":1,"label":"IPTU","nextDueAt":1788716938,"amount":44,"balance":1496},"luz":{"intervalDays":1,"label":"Luz","nextDueAt":1788716938,"amount":22,"balance":748},"agua":{"intervalDays":1,"label":"Agua","nextDueAt":1788716938,"amount":33,"balance":1122}}', NULL),
(12, 'RE036OYR', 'Ineseno Road', 'Banham Canyon', 'teeeeesxt', '[]', '[]', '[]', 0, 1, 'Modern Hotel', NULL, '[{"y":220.64,"z":16.09,"x":-3060.95,"h":171.93,"length":1.5,"locked":true,"width":2.2}]', '[]', '{"thickness":18.5,"maxZ":24.24,"points":[{"y":215.32,"z":5.74,"x":-3045.72},{"y":218.93,"z":5.74,"x":-3047.22},{"y":220.5,"z":5.74,"x":-3050.05},{"y":221.27,"z":5.74,"x":-3053.32},{"y":221.9,"z":5.74,"x":-3057.57},{"y":222.83,"z":5.74,"x":-3064.12},{"y":224.17,"z":5.74,"x":-3069.53},{"y":224.93,"z":5.74,"x":-3071.94},{"y":215.78,"z":5.74,"x":-3074.53},{"y":196.88,"z":5.74,"x":-3082.39},{"y":200.2,"z":5.74,"x":-3044.63}],"minZ":5.74}', '[]', '{"luz":{"amount":0,"label":"Luz","intervalDays":7,"nextDueAt":0,"balance":0},"iptu":{"amount":0,"label":"IPTU","intervalDays":30,"nextDueAt":0,"balance":0},"agua":{"amount":0,"label":"Agua","intervalDays":7,"nextDueAt":0,"balance":0}}', '{"y":213.85,"z":14.91,"x":-3060.39,"model":"lf_house_18_","heading":0.0}'),
(13, 'RE036OYR', 'Great Ocean Highway', 'Pacific Bluffs', 'sadasd', '[]', '[]', '[{"clothing":false,"id":"13-240832-115054","area":"interior","safe":{"weight":10000,"enable":false,"slots":12},"position":{"z":-4.3801,"x":-0.066,"y":-8.57},"trunk":{"weight":10000,"enable":true,"slots":12},"type":"trunk","label":"Cabinet Large","object":"v_res_cabinet","rotation":{"z":179.99998474121098,"x":0.0,"y":0.0}},{"clothing":false,"id":"13-287407-782495","area":"interior","safe":{"weight":10000,"enable":false,"slots":12},"position":{"z":-4.3401,"x":-0.5899,"y":0.1648},"trunk":{"weight":10000,"enable":true,"slots":12},"type":"trunk","label":"Cabinet Large","object":"v_res_cabinet","rotation":{"z":0.0,"x":0.0,"y":0.0}},{"clothing":false,"id":"13-374324-371360","area":"interior","safe":{"weight":10000,"enable":false,"slots":12},"position":{"z":-3.5301,"x":-2.74,"y":-1.28},"trunk":{"weight":100000,"enable":true,"slots":150},"type":"trunk","label":"Dressing Table","object":"v_res_d_dressingtable","rotation":{"z":0.0,"x":0.0,"y":0.0}},{"clothing":false,"id":"13-471241-787994","area":"interior","safe":{"weight":45000,"enable":true,"slots":25},"position":{"z":-3.8901,"x":-2.2901,"y":-3.82},"trunk":{"weight":10000,"enable":false,"slots":12},"type":"safe","label":"Safe","object":"prop_ld_int_safe_01","rotation":{"z":87.99999237060547,"x":0.0,"y":0.0}},{"clothing":false,"id":"13-520555-926104","area":"interior","safe":{"weight":45000,"enable":true,"slots":25},"position":{"z":-3.91,"x":-2.69,"y":-7.1698},"trunk":{"weight":10000,"enable":false,"slots":12},"type":"safe","label":"Safe","object":"prop_ld_int_safe_01","rotation":{"z":142.0,"x":0.0,"y":0.0}},{"clothing":false,"id":"13-520555-172736","area":"interior","safe":{"weight":10000,"enable":false,"slots":12},"position":{"z":-3.6001,"x":-1.8599,"y":-5.23},"trunk":{"weight":10000,"enable":false,"slots":12},"label":"Chairl","object":"v_res_fa_chair01","rotation":{"z":0.0,"x":0.0,"y":0.0}},{"clothing":false,"id":"13-916881-937926","area":"interior","safe":{"weight":10000,"enable":false,"slots":12},"position":{"z":-5.0901,"x":-1.6959,"y":5.3659},"trunk":{"weight":22000,"enable":true,"slots":22},"type":"trunk","label":"Palete de Drogas","object":"hei_prop_heist_weed_pallet_02","rotation":{"z":0.0,"x":0.0,"y":0.0}}]', 0, 334, '2 Floor House', NULL, '[{"width":2.2,"length":1.5,"z":14.93,"y":34.96,"x":-2834.31,"locked":true,"h":155.74}]', '[]', '{"thickness":13.75,"points":[{"y":31.18,"x":-2820.0,"z":6.77},{"y":11.13,"x":-2826.58,"z":6.77},{"y":18.68,"x":-2853.15,"z":6.77},{"y":41.63,"x":-2847.14,"z":6.77}],"maxZ":20.52,"minZ":6.77}', '[]', '{"iptu":{"intervalDays":1,"label":"IPTU","nextDueAt":1788641757,"amount":111,"balance":3663},"luz":{"intervalDays":1,"label":"Luz","nextDueAt":1788641757,"amount":111,"balance":3663},"agua":{"intervalDays":1,"label":"Agua","nextDueAt":1788641757,"amount":111,"balance":3663}}', '{"z":13.54,"y":29.95,"x":-2837.78,"model":"lf_house_04_","heading":340.0}'),
(14, 'RE036OYR', 'Forum Drive', 'Strawberry', 'Tia do trevor', '[]', '[]', '[{"type":"safe","label":"Safe","object":"prop_ld_int_safe_01","safe":{"slots":25,"enable":true,"weight":45000},"area":"interior","trunk":{"slots":12,"enable":false,"weight":10000},"rotation":{"z":-90.99999237060547,"y":0.0,"x":0.0},"clothing":false,"position":{"z":30.5799,"y":-1436.7365,"x":-9.306},"id":"14-1498532-674829"},{"type":"trunk","label":"Storage Unit","object":"v_res_tre_storagebox","safe":{"slots":12,"enable":false,"weight":10000},"area":"interior","trunk":{"slots":12,"enable":true,"weight":10000},"rotation":{"z":-147.99998474121095,"y":0.0,"x":0.0},"clothing":false,"position":{"z":30.09,"y":-1435.379,"x":-9.595},"id":"14-1498532-207740"}]', 0, 5555, 'mlo', NULL, '{"count":4}', '{"provider":"forge-garage","public":true,"name":"Tia do Franklin #14"}', '{"maxZ":37.62,"points":[{"z":27.12,"y":-1454.94,"x":-27.69},{"z":27.12,"y":-1421.96,"x":-27.79},{"z":27.12,"y":-1420.88,"x":-15.68},{"z":27.12,"y":-1416.46,"x":-7.28},{"z":27.12,"y":-1452.35,"x":-7.45}],"minZ":27.12,"thickness":10.5}', '[]', '{"iptu":{"intervalDays":7,"label":"IPTU","balance":400,"amount":100,"nextDueAt":1788817707},"luz":{"intervalDays":7,"label":"Luz","balance":400,"amount":100,"nextDueAt":1788817707},"agua":{"intervalDays":7,"label":"Agua","balance":400,"amount":100,"nextDueAt":1788817707}}', NULL),
(15, 'RE036OYR', 'Utopia Gardens', 'Mirror Park', '22222', '[]', '[]', '[]', 0, 222, 'Apartamento Luxo Jordqn', NULL, '[{"locked":true,"h":352.72,"x":1377.55,"z":67.33,"y":-715.33,"width":2.2,"length":1.5}]', '[]', '{"maxZ":71.19,"points":[{"z":66.19,"y":-724.07,"x":1365.61},{"z":66.19,"y":-723.24,"x":1374.0},{"z":66.19,"y":-724.26,"x":1382.92},{"z":66.19,"y":-716.12,"x":1386.55},{"z":66.19,"y":-694.46,"x":1391.03},{"z":66.19,"y":-687.13,"x":1370.73}],"minZ":66.19,"thickness":5.0}', '[]', '{"iptu":{"amount":0,"label":"IPTU","intervalDays":30,"balance":0,"nextDueAt":0},"luz":{"amount":0,"label":"Luz","intervalDays":7,"balance":0,"nextDueAt":0},"agua":{"amount":0,"label":"Agua","intervalDays":7,"balance":0,"nextDueAt":0}}', '{"heading":350.0,"model":"lf_house_11_","z":65.73,"y":-707.31,"x":1378.88}');

-- Structure for `ps_banking_accounts`
DROP TABLE IF EXISTS `ps_banking_accounts`;
CREATE TABLE `ps_banking_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `balance` bigint(20) NOT NULL,
  `holder` varchar(255) NOT NULL,
  `cardNumber` varchar(255) NOT NULL,
  `users` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `owner` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `ps_banking_bills`
DROP TABLE IF EXISTS `ps_banking_bills`;
CREATE TABLE `ps_banking_bills` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `description` varchar(255) NOT NULL,
  `type` varchar(50) NOT NULL,
  `amount` decimal(20,2) NOT NULL,
  `date` date NOT NULL,
  `isPaid` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `ps_banking_transactions`
DROP TABLE IF EXISTS `ps_banking_transactions`;
CREATE TABLE `ps_banking_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `description` varchar(255) NOT NULL,
  `type` varchar(50) NOT NULL,
  `amount` decimal(20,2) NOT NULL,
  `date` date NOT NULL,
  `isIncome` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `pug_atm`
DROP TABLE IF EXISTS `pug_atm`;
CREATE TABLE `pug_atm` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `settings` text DEFAULT '[]',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pug_banktruck`
DROP TABLE IF EXISTS `pug_banktruck`;
CREATE TABLE `pug_banktruck` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `settings` text DEFAULT '[]',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pug_heist`
DROP TABLE IF EXISTS `pug_heist`;
CREATE TABLE `pug_heist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `heist_name` varchar(50) NOT NULL,
  `stages` mediumtext DEFAULT '[]',
  `settings` text DEFAULT '[]',
  PRIMARY KEY (`id`),
  UNIQUE KEY `heist_name` (`heist_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `pug_sellitems`
DROP TABLE IF EXISTS `pug_sellitems`;
CREATE TABLE `pug_sellitems` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `settings` text DEFAULT '[]',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `qb_propplacing`
DROP TABLE IF EXISTS `qb_propplacing`;
CREATE TABLE `qb_propplacing` (
  `id` varchar(50) DEFAULT NULL,
  `model` int(11) DEFAULT NULL,
  `in_vehicle` tinyint(1) DEFAULT 0,
  `vehicle_plate` varchar(50) DEFAULT NULL,
  `vehicle_offset_x` float DEFAULT 0,
  `vehicle_offset_y` float DEFAULT 0,
  `vehicle_offset_z` float DEFAULT 0,
  `vehicle_offset_h` float DEFAULT 0,
  `item` varchar(50) DEFAULT NULL,
  `x` float DEFAULT NULL,
  `y` float DEFAULT NULL,
  `z` float DEFAULT NULL,
  `heading` float DEFAULT NULL,
  `citizen` varchar(50) DEFAULT NULL,
  `metadata` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `qf_graffiti`
DROP TABLE IF EXISTS `qf_graffiti`;
CREATE TABLE `qf_graffiti` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(20) NOT NULL DEFAULT 'project',
  `owner` varchar(72) DEFAULT NULL,
  `creator` varchar(50) DEFAULT NULL,
  `name` longtext DEFAULT NULL,
  `last_edited` varchar(50) DEFAULT NULL,
  `created` varchar(50) DEFAULT NULL,
  `canvas` longtext DEFAULT NULL,
  `data` longtext DEFAULT NULL,
  `Graffiti_id` int(11) DEFAULT NULL,
  `image_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_type` (`type`),
  KEY `idx_owner` (`owner`),
  KEY `idx_creator` (`creator`),
  KEY `idx_graffiti_id` (`Graffiti_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `race_tracks`
DROP TABLE IF EXISTS `race_tracks`;
CREATE TABLE `race_tracks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `checkpoints` text DEFAULT NULL,
  `metadata` text DEFAULT NULL,
  `creatorid` varchar(50) DEFAULT NULL,
  `creatorname` varchar(50) DEFAULT NULL,
  `distance` int(11) DEFAULT NULL,
  `raceid` varchar(50) DEFAULT NULL,
  `access` text DEFAULT NULL,
  `curated` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `raceid` (`raceid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=50 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `racer_names`
DROP TABLE IF EXISTS `racer_names`;
CREATE TABLE `racer_names` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` text NOT NULL,
  `racername` text NOT NULL,
  `lasttouched` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `races` int(11) NOT NULL DEFAULT 0,
  `wins` int(11) NOT NULL DEFAULT 0,
  `tracks` int(11) NOT NULL DEFAULT 0,
  `auth` varchar(50) DEFAULT 'racer',
  `crew` varchar(50) DEFAULT NULL,
  `createdby` varchar(50) DEFAULT NULL,
  `revoked` tinyint(4) DEFAULT 0,
  `ranking` int(11) DEFAULT 0,
  `active` int(11) NOT NULL DEFAULT 0,
  `crypto` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `id` (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `racing_crews`
DROP TABLE IF EXISTS `racing_crews`;
CREATE TABLE `racing_crews` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `crew_name` text DEFAULT NULL,
  `members` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `wins` int(11) DEFAULT NULL,
  `races` int(11) DEFAULT NULL,
  `rank` int(11) DEFAULT NULL,
  `founder_name` text DEFAULT NULL,
  `founder_citizenid` text DEFAULT NULL,
  `tag` varchar(6) DEFAULT NULL,
  `banner_url` text DEFAULT NULL,
  `logo_url` text DEFAULT NULL,
  `color` varchar(7) NOT NULL DEFAULT '#6366f1',
  PRIMARY KEY (`id`) USING BTREE,
  CONSTRAINT `members` CHECK (json_valid(`members`))
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `racing_races`
DROP TABLE IF EXISTS `racing_races`;
CREATE TABLE `racing_races` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `raceId` varchar(50) NOT NULL,
  `trackId` varchar(50) NOT NULL,
  `results` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `amountOfRacers` int(11) NOT NULL,
  `laps` int(11) NOT NULL,
  `hostName` varchar(255) DEFAULT NULL,
  `maxClass` varchar(50) DEFAULT NULL,
  `ghosting` tinyint(1) NOT NULL DEFAULT 0,
  `ranked` tinyint(1) NOT NULL DEFAULT 0,
  `reversed` tinyint(1) NOT NULL DEFAULT 0,
  `firstPerson` tinyint(1) NOT NULL DEFAULT 0,
  `automated` tinyint(1) NOT NULL DEFAULT 0,
  `drift` tinyint(1) NOT NULL DEFAULT 0,
  `hidden` tinyint(1) NOT NULL DEFAULT 0,
  `silent` tinyint(1) NOT NULL DEFAULT 0,
  `buyIn` int(11) NOT NULL DEFAULT 0,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `timestamp` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_raceId` (`raceId`),
  KEY `idx_trackId` (`trackId`),
  KEY `idx_timestamp` (`timestamp`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `rcore_guidebook_categories`
DROP TABLE IF EXISTS `rcore_guidebook_categories`;
CREATE TABLE `rcore_guidebook_categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) NOT NULL,
  `key` varchar(255) NOT NULL,
  `order_number` int(11) DEFAULT 1,
  `is_enabled` tinyint(1) DEFAULT 1,
  `default_expand` tinyint(1) DEFAULT 1,
  `attributes` longtext NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rcore_guidebook_categories_key_uindex` (`key`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `rcore_guidebook_pages`
DROP TABLE IF EXISTS `rcore_guidebook_pages`;
CREATE TABLE `rcore_guidebook_pages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) NOT NULL,
  `key` varchar(255) NOT NULL,
  `category_key` varchar(255) NOT NULL,
  `order_number` int(11) DEFAULT 1,
  `is_enabled` tinyint(1) DEFAULT 1,
  `content` longtext DEFAULT NULL,
  `attributes` longtext NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rcore_guidebook_pages_key_uindex` (`key`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `rcore_guidebook_points`
DROP TABLE IF EXISTS `rcore_guidebook_points`;
CREATE TABLE `rcore_guidebook_points` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(50) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `is_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `can_navigate` tinyint(1) NOT NULL DEFAULT 1,
  `blip_sprite` varchar(255) DEFAULT NULL,
  `blip_color` int(11) DEFAULT NULL,
  `blip_display_type` int(11) DEFAULT 4,
  `blip_size` float DEFAULT 1,
  `blip_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `marker_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `marker_size` varchar(255) DEFAULT NULL,
  `marker_draw_distance` int(11) DEFAULT NULL,
  `marker_type` varchar(255) DEFAULT NULL,
  `marker_color` varchar(255) DEFAULT NULL,
  `show_date` timestamp NULL DEFAULT NULL,
  `hide_date` timestamp NULL DEFAULT NULL,
  `content` mediumtext DEFAULT NULL,
  `help_key` varchar(255) DEFAULT NULL,
  `draw_distance` int(11) DEFAULT NULL,
  `position` varchar(255) NOT NULL DEFAULT 'vector3(0,0,0)',
  `size` float DEFAULT 1,
  `color` varchar(255) DEFAULT NULL,
  `is_rotation_enabled` tinyint(1) DEFAULT 1,
  `marker_rotation` varchar(255) DEFAULT '{"x":0.0,"y":0.0,"z":0.0}',
  `font` tinyint(1) DEFAULT 0,
  `attributes` longtext NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rcore_guidebook_points_key_uindex` (`key`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `real_vehicleshop`
DROP TABLE IF EXISTS `real_vehicleshop`;
CREATE TABLE `real_vehicleshop` (
  `id` int(11) DEFAULT NULL,
  `information` longtext DEFAULT NULL,
  `vehicles` longtext DEFAULT NULL,
  `categories` longtext DEFAULT NULL,
  `feedbacks` longtext DEFAULT NULL,
  `complaints` longtext DEFAULT NULL,
  `preorders` longtext DEFAULT NULL,
  `employees` longtext DEFAULT NULL,
  `soldvehicles` longtext DEFAULT NULL,
  `transactions` longtext DEFAULT NULL,
  `perms` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `rf_dealership_favorites`
DROP TABLE IF EXISTS `rf_dealership_favorites`;
CREATE TABLE `rf_dealership_favorites` (
  `identifier` varchar(50) NOT NULL,
  `model` varchar(50) NOT NULL,
  PRIMARY KEY (`identifier`,`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `rf_dealership_vehicles`
DROP TABLE IF EXISTS `rf_dealership_vehicles`;
CREATE TABLE `rf_dealership_vehicles` (
  `model` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `brand` varchar(50) NOT NULL,
  `category` varchar(50) NOT NULL,
  `level` int(11) NOT NULL DEFAULT 1,
  `price` int(11) NOT NULL DEFAULT 0,
  `stock` int(11) NOT NULL DEFAULT 0,
  `class` varchar(50) NOT NULL,
  `image` varchar(255) DEFAULT 'img/default.png',
  `isNew` tinyint(1) NOT NULL DEFAULT 0,
  `isLimited` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `territories`
DROP TABLE IF EXISTS `territories`;
CREATE TABLE `territories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `label` varchar(100) NOT NULL,
  `polyzone_points` longtext DEFAULT NULL,
  `npcs` longtext DEFAULT NULL,
  `center_coords` varchar(100) DEFAULT NULL,
  `center_radius` float NOT NULL DEFAULT 10,
  `gang` varchar(50) DEFAULT NULL,
  `influence` int(11) NOT NULL DEFAULT 100,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `territories_globals`
DROP TABLE IF EXISTS `territories_globals`;
CREATE TABLE `territories_globals` (
  `key_name` varchar(50) NOT NULL,
  `value` longtext DEFAULT NULL,
  PRIMARY KEY (`key_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `track_times`
DROP TABLE IF EXISTS `track_times`;
CREATE TABLE `track_times` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `trackId` varchar(50) NOT NULL,
  `racerName` varchar(50) NOT NULL,
  `carClass` varchar(50) NOT NULL,
  `vehicleModel` varchar(255) NOT NULL,
  `raceType` varchar(50) NOT NULL,
  `time` int(11) NOT NULL,
  `reversed` tinyint(1) NOT NULL DEFAULT 0,
  `pbHistory` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `timestamp` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_trackId` (`trackId`),
  KEY `idx_racerName` (`racerName`),
  KEY `idx_track_racer_class` (`trackId`,`racerName`,`carClass`,`raceType`,`reversed`),
  KEY `idx_time` (`time`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `users`
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `userId` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(255) DEFAULT NULL,
  `license` varchar(50) DEFAULT NULL,
  `license2` varchar(50) DEFAULT NULL,
  `fivem` varchar(20) DEFAULT NULL,
  `discord` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`userId`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Data for `users`
INSERT INTO `users` (`userId`, `username`, `license`, `license2`, `fivem`, `discord`) VALUES
(2, 'SharpFish5162', 'license:96d348f246a7b8d3624f6d7190ec5355d126076d', 'license2:96d348f246a7b8d3624f6d7190ec5355d126076d', NULL, 'discord:340522406332465152');

-- Structure for `vehicle_engates`
DROP TABLE IF EXISTS `vehicle_engates`;
CREATE TABLE `vehicle_engates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `placa` varchar(20) NOT NULL,
  `tipo` varchar(10) NOT NULL COMMENT 'femea ou macho',
  `item` varchar(64) NOT NULL COMMENT 'nome do item do engate',
  `model` varchar(64) NOT NULL COMMENT 'modelo 3D do engate',
  `offset_x` float NOT NULL DEFAULT 0,
  `offset_y` float NOT NULL DEFAULT 0,
  `offset_z` float NOT NULL DEFAULT 0,
  `rot_x` float NOT NULL DEFAULT 0,
  `rot_y` float NOT NULL DEFAULT 0,
  `rot_z` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_placa_tipo` (`placa`,`tipo`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `vehicle_financing`
DROP TABLE IF EXISTS `vehicle_financing`;
CREATE TABLE `vehicle_financing` (
  `vehicleId` int(11) NOT NULL,
  `balance` int(11) DEFAULT NULL,
  `paymentamount` int(11) DEFAULT NULL,
  `paymentsleft` int(11) DEFAULT NULL,
  `financetime` int(11) DEFAULT NULL,
  PRIMARY KEY (`vehicleId`),
  CONSTRAINT `vehicleId` FOREIGN KEY (`vehicleId`) REFERENCES `player_vehicles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `vehicle_parts`
DROP TABLE IF EXISTS `vehicle_parts`;
CREATE TABLE `vehicle_parts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `plate` varchar(10) NOT NULL COMMENT 'Placa do veiculo',
  `part` varchar(64) NOT NULL COMMENT 'Identificador da peca',
  `stage` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Nivel/estagio da peca',
  `installed_km` int(10) unsigned NOT NULL DEFAULT 0,
  `durability` int(10) unsigned NOT NULL DEFAULT 0,
  `citizen_id` varchar(64) DEFAULT NULL COMMENT 'CitizenID de quem instalou',
  `installed_at` datetime NOT NULL DEFAULT current_timestamp() COMMENT 'Data e hora da instalacao',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_plate_part` (`plate`,`part`),
  KEY `idx_plate` (`plate`),
  KEY `idx_citizen_id` (`citizen_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `warns`
DROP TABLE IF EXISTS `warns`;
CREATE TABLE `warns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `license` varchar(50) NOT NULL,
  `reason` text NOT NULL,
  `warnedby` varchar(50) NOT NULL,
  `warnedtime` bigint(20) NOT NULL DEFAULT unix_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `weed_plants`
DROP TABLE IF EXISTS `weed_plants`;
CREATE TABLE `weed_plants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `property` varchar(30) DEFAULT NULL,
  `stage` tinyint(4) NOT NULL DEFAULT 1,
  `sort` varchar(30) NOT NULL,
  `gender` enum('male','female') NOT NULL,
  `food` tinyint(4) NOT NULL DEFAULT 100,
  `health` tinyint(4) NOT NULL DEFAULT 100,
  `stageProgress` tinyint(4) NOT NULL DEFAULT 0,
  `coords` tinytext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `wizating_dragstrip_highscores`
DROP TABLE IF EXISTS `wizating_dragstrip_highscores`;
CREATE TABLE `wizating_dragstrip_highscores` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `player_name` varchar(100) NOT NULL,
  `vehicle_name` varchar(50) NOT NULL,
  `finish_time` float NOT NULL,
  `finish_speed` float NOT NULL,
  `track_length` float NOT NULL,
  `race_date` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `wizating_dragstrip_objects`
DROP TABLE IF EXISTS `wizating_dragstrip_objects`;
CREATE TABLE `wizating_dragstrip_objects` (
  `id` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `wizating_stage_box_data` longtext DEFAULT NULL CHECK (json_valid(`wizating_stage_box_data`)),
  `wizating_time_billboard_left_data` longtext DEFAULT NULL CHECK (json_valid(`wizating_time_billboard_left_data`)),
  `wizating_time_billboard_right_data` longtext DEFAULT NULL CHECK (json_valid(`wizating_time_billboard_right_data`)),
  `wizating_dragrace_scoretv_data` longtext DEFAULT NULL CHECK (json_valid(`wizating_dragrace_scoretv_data`)),
  `wizating_treelight_body_data` longtext DEFAULT NULL CHECK (json_valid(`wizating_treelight_body_data`)),
  `extra_track_objects` longtext DEFAULT NULL CHECK (json_valid(`extra_track_objects`)),
  `finishLineDistance` float DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- Structure for `wizating_dyno`
DROP TABLE IF EXISTS `wizating_dyno`;
CREATE TABLE `wizating_dyno` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vehData` longtext NOT NULL,
  `plate` varchar(50) NOT NULL,
  `owned` int(11) NOT NULL DEFAULT 0,
  `model` varchar(50) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `plate` (`plate`,`model`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Structure for `xt_prison`
DROP TABLE IF EXISTS `xt_prison`;
CREATE TABLE `xt_prison` (
  `identifier` varchar(100) NOT NULL,
  `jailtime` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Data for `xt_prison`
INSERT INTO `xt_prison` (`identifier`, `jailtime`) VALUES
('RE036OYR', 0),
('M6YW58XY', 0);

-- Structure for `xt_prison_items`
DROP TABLE IF EXISTS `xt_prison_items`;
CREATE TABLE `xt_prison_items` (
  `owner` varchar(60) DEFAULT NULL,
  `data` longtext DEFAULT NULL,
  UNIQUE KEY `owner` (`owner`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

SET FOREIGN_KEY_CHECKS=1;
