-- PR Bridge SQL Backup
-- Mode: schema
-- Tables: 164
SET FOREIGN_KEY_CHECKS=0;

-- Structure for `ar_prop_groups`
DROP TABLE IF EXISTS `ar_prop_groups`;
CREATE TABLE `ar_prop_groups` (
  `group_name` varchar(64) NOT NULL,
  `enabled` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`group_name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

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
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

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
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `bank_accounts_new`
DROP TABLE IF EXISTS `bank_accounts_new`;
CREATE TABLE `bank_accounts_new` (
  `id` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` int(11) DEFAULT 0,
  `transactions` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `auth` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isFrozen` int(11) DEFAULT 0,
  `creator` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `bans`
DROP TABLE IF EXISTS `bans`;
CREATE TABLE `bans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `license` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `discord` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reason` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expire` int(11) DEFAULT NULL,
  `bannedby` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'LeBanhammer',
  PRIMARY KEY (`id`),
  KEY `license` (`license`),
  KEY `discord` (`discord`),
  KEY `ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `bodycam_recordings`
DROP TABLE IF EXISTS `bodycam_recordings`;
CREATE TABLE `bodycam_recordings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `recording` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_cid` (`cid`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `character_slots`
DROP TABLE IF EXISTS `character_slots`;
CREATE TABLE `character_slots` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `license2` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `dealers`
DROP TABLE IF EXISTS `dealers`;
CREATE TABLE `dealers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '0',
  `coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `time` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `createdby` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `ds_blipcreator`
DROP TABLE IF EXISTS `ds_blipcreator`;
CREATE TABLE `ds_blipcreator` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `data` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Structure for `forge_blip`
DROP TABLE IF EXISTS `forge_blip`;
CREATE TABLE `forge_blip` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `data` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

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
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `fox_engine_config`
DROP TABLE IF EXISTS `fox_engine_config`;
CREATE TABLE `fox_engine_config` (
  `key` varchar(100) NOT NULL,
  `value` text NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`key`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `frkn_dispatch`
DROP TABLE IF EXISTS `frkn_dispatch`;
CREATE TABLE `frkn_dispatch` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category` varchar(50) NOT NULL,
  `map_data` longtext NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=330 DEFAULT CHARSET=utf8;

-- Structure for `frkn_dispatch_data`
DROP TABLE IF EXISTS `frkn_dispatch_data`;
CREATE TABLE `frkn_dispatch_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Unit` varchar(100) NOT NULL,
  `unitdata` longtext NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `profession` varchar(50) DEFAULT 'police',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4;

-- Structure for `frkn_pd_cloth`
DROP TABLE IF EXISTS `frkn_pd_cloth`;
CREATE TABLE `frkn_pd_cloth` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `data` longtext NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8;

-- Structure for `frkn_pd_vaults`
DROP TABLE IF EXISTS `frkn_pd_vaults`;
CREATE TABLE `frkn_pd_vaults` (
  `id` int(11) DEFAULT NULL,
  `station` int(11) DEFAULT NULL,
  `vault` int(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=utf8;

-- Structure for `frkn_radio_channels`
DROP TABLE IF EXISTS `frkn_radio_channels`;
CREATE TABLE `frkn_radio_channels` (
  `channel_id` varchar(50) NOT NULL,
  `password` varchar(100) DEFAULT '',
  PRIMARY KEY (`channel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB AUTO_INCREMENT=72 DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Structure for `gangs_metadata`
DROP TABLE IF EXISTS `gangs_metadata`;
CREATE TABLE `gangs_metadata` (
  `gang_name` varchar(50) NOT NULL,
  `level` int(11) NOT NULL DEFAULT 1,
  `xp` int(11) NOT NULL DEFAULT 0,
  `bank_money` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`gang_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Structure for `inventory_items`
DROP TABLE IF EXISTS `inventory_items`;
CREATE TABLE `inventory_items` (
  `uniqueId` int(11) NOT NULL AUTO_INCREMENT,
  `inventoryId` varchar(100) DEFAULT NULL,
  `data` longtext NOT NULL,
  `lastModified` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`uniqueId`),
  KEY `idx_inventoryId` (`inventoryId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `items`
DROP TABLE IF EXISTS `items`;
CREATE TABLE `items` (
  `name` varchar(100) NOT NULL,
  `category` varchar(100) DEFAULT NULL,
  `data` longtext NOT NULL,
  PRIMARY KEY (`name`),
  KEY `idx_category` (`category`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `jeff_presets`
DROP TABLE IF EXISTS `jeff_presets`;
CREATE TABLE `jeff_presets` (
  `citizenid` varchar(50) NOT NULL,
  `vehicle_name` varchar(100) NOT NULL,
  `preset_name` varchar(100) NOT NULL,
  `props` longtext NOT NULL,
  PRIMARY KEY (`citizenid`,`vehicle_name`,`preset_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Structure for `jeffresources`
DROP TABLE IF EXISTS `jeffresources`;
CREATE TABLE `jeffresources` (
  `conheceu` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Structure for `koja_crafting`
DROP TABLE IF EXISTS `koja_crafting`;
CREATE TABLE `koja_crafting` (
  `#` int(11) NOT NULL AUTO_INCREMENT,
  `playerid` varchar(50) DEFAULT NULL,
  `currentXP` int(11) DEFAULT NULL,
  PRIMARY KEY (`#`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB AUTO_INCREMENT=58 DEFAULT CHARSET=utf8mb4;

-- Structure for `lapraces`
DROP TABLE IF EXISTS `lapraces`;
CREATE TABLE `lapraces` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `checkpoints` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `records` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `creator` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `distance` int(11) DEFAULT NULL,
  `raceid` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `raceid` (`raceid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `management_outfits`
DROP TABLE IF EXISTS `management_outfits`;
CREATE TABLE `management_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `minrank` int(11) NOT NULL DEFAULT 0,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Cool Outfit',
  `gender` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'male',
  `model` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `props` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `components` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4;

-- Structure for `mapeditor_categories`
DROP TABLE IF EXISTS `mapeditor_categories`;
CREATE TABLE `mapeditor_categories` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT 'New Category',
  `parent_id` int(10) unsigned DEFAULT NULL,
  `slot_limit` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Structure for `mapeditor_deleted_objects`
DROP TABLE IF EXISTS `mapeditor_deleted_objects`;
CREATE TABLE `mapeditor_deleted_objects` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `prop_hash` varchar(255) NOT NULL,
  `coords` longtext NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

-- Structure for `mapeditor_exports`
DROP TABLE IF EXISTS `mapeditor_exports`;
CREATE TABLE `mapeditor_exports` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Structure for `mapeditor_object_categories`
DROP TABLE IF EXISTS `mapeditor_object_categories`;
CREATE TABLE `mapeditor_object_categories` (
  `object_id` int(10) unsigned NOT NULL,
  `category_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`object_id`),
  KEY `idx_category` (`category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

-- Structure for `npwd_calls`
DROP TABLE IF EXISTS `npwd_calls`;
CREATE TABLE `npwd_calls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 DEFAULT NULL,
  `transmitter` varchar(255) NOT NULL,
  `receiver` varchar(255) NOT NULL,
  `is_accepted` tinyint(4) DEFAULT 0,
  `isAnonymous` tinyint(4) NOT NULL DEFAULT 0,
  `start` varchar(255) DEFAULT NULL,
  `end` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `npwd_darkchat_channel_members`
DROP TABLE IF EXISTS `npwd_darkchat_channel_members`;
CREATE TABLE `npwd_darkchat_channel_members` (
  `channel_id` int(11) NOT NULL,
  `user_identifier` varchar(255) NOT NULL,
  `is_owner` tinyint(4) NOT NULL DEFAULT 0,
  KEY `npwd_darkchat_channel_members_npwd_darkchat_channels_id_fk` (`channel_id`) USING BTREE,
  CONSTRAINT `npwd_darkchat_channel_members_npwd_darkchat_channels_id_fk` FOREIGN KEY (`channel_id`) REFERENCES `npwd_darkchat_channels` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Structure for `npwd_darkchat_channels`
DROP TABLE IF EXISTS `npwd_darkchat_channels`;
CREATE TABLE `npwd_darkchat_channels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel_identifier` varchar(191) NOT NULL,
  `label` varchar(255) DEFAULT '',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `darkchat_channels_channel_identifier_uindex` (`channel_identifier`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4;

-- Structure for `npwd_marketplace_listings`
DROP TABLE IF EXISTS `npwd_marketplace_listings`;
CREATE TABLE `npwd_marketplace_listings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 DEFAULT NULL,
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
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `npwd_match_profiles`
DROP TABLE IF EXISTS `npwd_match_profiles`;
CREATE TABLE `npwd_match_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 NOT NULL,
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
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- Structure for `npwd_match_views`
DROP TABLE IF EXISTS `npwd_match_views`;
CREATE TABLE `npwd_match_views` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 NOT NULL,
  `profile` int(11) NOT NULL,
  `liked` tinyint(4) DEFAULT 0,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `match_profile_idx` (`profile`),
  KEY `identifier` (`identifier`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `npwd_messages`
DROP TABLE IF EXISTS `npwd_messages`;
CREATE TABLE `npwd_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `message` varchar(512) CHARACTER SET utf8mb4 NOT NULL,
  `user_identifier` varchar(48) CHARACTER SET utf8mb4 NOT NULL,
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
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `npwd_messages_conversations`
DROP TABLE IF EXISTS `npwd_messages_conversations`;
CREATE TABLE `npwd_messages_conversations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `conversation_list` varchar(225) CHARACTER SET utf8mb4 NOT NULL,
  `label` varchar(60) CHARACTER SET utf8mb4 DEFAULT '',
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_message_id` int(11) DEFAULT NULL,
  `is_group_chat` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `npwd_messages_participants`
DROP TABLE IF EXISTS `npwd_messages_participants`;
CREATE TABLE `npwd_messages_participants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `conversation_id` int(11) NOT NULL,
  `participant` varchar(225) CHARACTER SET utf8mb4 NOT NULL,
  `unread_count` int(11) DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `message_participants_npwd_messages_conversations_id_fk` (`conversation_id`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `npwd_notes`
DROP TABLE IF EXISTS `npwd_notes`;
CREATE TABLE `npwd_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `npwd_phone_contacts`
DROP TABLE IF EXISTS `npwd_phone_contacts`;
CREATE TABLE `npwd_phone_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `number` varchar(20) DEFAULT NULL,
  `display` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `npwd_phone_gallery`
DROP TABLE IF EXISTS `npwd_phone_gallery`;
CREATE TABLE `npwd_phone_gallery` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 DEFAULT NULL,
  `image` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

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
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `npwd_twitter_profiles`
DROP TABLE IF EXISTS `npwd_twitter_profiles`;
CREATE TABLE `npwd_twitter_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_name` varchar(90) NOT NULL,
  `identifier` varchar(48) CHARACTER SET utf8mb4 NOT NULL,
  `avatar_url` varchar(255) DEFAULT 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png',
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `profile_name_UNIQUE` (`profile_name`),
  KEY `identifier` (`identifier`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

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
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `npwd_twitter_tweets`
DROP TABLE IF EXISTS `npwd_twitter_tweets`;
CREATE TABLE `npwd_twitter_tweets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `message` varchar(1000) CHARACTER SET utf8mb4 NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `likes` int(11) NOT NULL DEFAULT 0,
  `identifier` varchar(48) CHARACTER SET utf8mb4 NOT NULL,
  `visible` tinyint(4) NOT NULL DEFAULT 1,
  `images` varchar(1000) CHARACTER SET utf8mb4 DEFAULT '',
  `retweet` int(11) DEFAULT NULL,
  `profile_id` int(11) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `npwd_twitter_tweets_npwd_twitter_profiles_id_fk` (`profile_id`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `nxtgn_crafting_bench_type_access`
DROP TABLE IF EXISTS `nxtgn_crafting_bench_type_access`;
CREATE TABLE `nxtgn_crafting_bench_type_access` (
  `bench_type` varchar(50) NOT NULL,
  `access` varchar(50) NOT NULL,
  `ranks` longtext DEFAULT NULL,
  UNIQUE KEY `bench_type` (`bench_type`,`access`),
  CONSTRAINT `FK__nxtgn_crafting_bench_types` FOREIGN KEY (`bench_type`) REFERENCES `nxtgn_crafting_bench_types` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `nxtgn_crafting_bench_type_levels`
DROP TABLE IF EXISTS `nxtgn_crafting_bench_type_levels`;
CREATE TABLE `nxtgn_crafting_bench_type_levels` (
  `bench_type` varchar(36) NOT NULL,
  `category` varchar(36) DEFAULT NULL,
  `level` float NOT NULL DEFAULT 1,
  UNIQUE KEY `bench_type_category` (`bench_type`,`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `nxtgn_crafting_blueprints`
DROP TABLE IF EXISTS `nxtgn_crafting_blueprints`;
CREATE TABLE `nxtgn_crafting_blueprints` (
  `uuid` varchar(36) NOT NULL,
  `label` varchar(50) NOT NULL,
  `description` text DEFAULT NULL,
  `uses` int(11) DEFAULT NULL,
  `item` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `nxtgn_crafting_categories`
DROP TABLE IF EXISTS `nxtgn_crafting_categories`;
CREATE TABLE `nxtgn_crafting_categories` (
  `uuid` varchar(36) NOT NULL,
  `title` varchar(50) NOT NULL,
  `description` text NOT NULL DEFAULT '',
  `icon` varchar(50) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `nxtgn_crafting_player_blueprints`
DROP TABLE IF EXISTS `nxtgn_crafting_player_blueprints`;
CREATE TABLE `nxtgn_crafting_player_blueprints` (
  `identifier` varchar(255) NOT NULL,
  `blueprint` varchar(36) NOT NULL,
  UNIQUE KEY `identifier` (`identifier`,`blueprint`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `nxtgn_crafting_player_history`
DROP TABLE IF EXISTS `nxtgn_crafting_player_history`;
CREATE TABLE `nxtgn_crafting_player_history` (
  `identifier` varchar(255) NOT NULL,
  `bench_type` varchar(36) NOT NULL,
  `bench_location` varchar(36) NOT NULL,
  `recipe` varchar(36) NOT NULL,
  `quantity` int(11) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `nxtgn_crafting_player_levels`
DROP TABLE IF EXISTS `nxtgn_crafting_player_levels`;
CREATE TABLE `nxtgn_crafting_player_levels` (
  `identifier` varchar(255) NOT NULL DEFAULT '0',
  `category` varchar(36) NOT NULL,
  `level` float NOT NULL DEFAULT 0,
  UNIQUE KEY `identifier` (`identifier`,`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `nxtgn_crafting_players`
DROP TABLE IF EXISTS `nxtgn_crafting_players`;
CREATE TABLE `nxtgn_crafting_players` (
  `identifier` varchar(255) NOT NULL,
  `level` float NOT NULL DEFAULT 1,
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `nxtgn_crafting_recipe_blueprints`
DROP TABLE IF EXISTS `nxtgn_crafting_recipe_blueprints`;
CREATE TABLE `nxtgn_crafting_recipe_blueprints` (
  `recipe_id` varchar(36) NOT NULL,
  `blueprint_id` varchar(36) NOT NULL,
  UNIQUE KEY `recipe_id` (`recipe_id`,`blueprint_id`) USING BTREE,
  KEY `FK_nxtgn_crafting_recipe_blueprints_nxtgn_crafting_blueprints` (`blueprint_id`),
  CONSTRAINT `FK_nxtgn_crafting_recipe_blueprints_nxtgn_crafting_blueprints` FOREIGN KEY (`blueprint_id`) REFERENCES `nxtgn_crafting_blueprints` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `FK_nxtgn_crafting_recipe_blueprints_nxtgn_crafting_recipes` FOREIGN KEY (`recipe_id`) REFERENCES `nxtgn_crafting_recipes` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- Structure for `nxtgn_crafting_recipe_ingredients`
DROP TABLE IF EXISTS `nxtgn_crafting_recipe_ingredients`;
CREATE TABLE `nxtgn_crafting_recipe_ingredients` (
  `recipe_id` varchar(36) NOT NULL,
  `item` varchar(50) NOT NULL,
  `count` int(11) NOT NULL DEFAULT 1,
  UNIQUE KEY `recipe_id` (`recipe_id`,`item`),
  CONSTRAINT `FK_nxtgn_crafting_recipe_ingredients_nxtgn_crafting_recipes` FOREIGN KEY (`recipe_id`) REFERENCES `nxtgn_crafting_recipes` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `nxtgn_crafting_recipe_results`
DROP TABLE IF EXISTS `nxtgn_crafting_recipe_results`;
CREATE TABLE `nxtgn_crafting_recipe_results` (
  `recipe_id` varchar(36) NOT NULL,
  `item` varchar(50) NOT NULL,
  `count` int(11) NOT NULL DEFAULT 1,
  `metadata` longtext DEFAULT NULL,
  UNIQUE KEY `recipe_id` (`recipe_id`,`item`),
  CONSTRAINT `FK_nxtgn_crafting_recipe_results_nxtgn_crafting_recipes` FOREIGN KEY (`recipe_id`) REFERENCES `nxtgn_crafting_recipes` (`uuid`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `occasion_vehicles`
DROP TABLE IF EXISTS `occasion_vehicles`;
CREATE TABLE `occasion_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `seller` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `description` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `plate` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `model` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mods` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `occasionid` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `occasionId` (`occasionid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `ox_doorlock`
DROP TABLE IF EXISTS `ox_doorlock`;
CREATE TABLE `ox_doorlock` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `data` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `ox_inventory`
DROP TABLE IF EXISTS `ox_inventory`;
CREATE TABLE `ox_inventory` (
  `owner` varchar(60) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `data` longtext DEFAULT NULL,
  `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  UNIQUE KEY `owner` (`owner`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `pa_vehicleshop_player_level`
DROP TABLE IF EXISTS `pa_vehicleshop_player_level`;
CREATE TABLE `pa_vehicleshop_player_level` (
  `citizenid` varchar(50) NOT NULL,
  `level` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `pa_vehicleshop_showroom_vehicles`
DROP TABLE IF EXISTS `pa_vehicleshop_showroom_vehicles`;
CREATE TABLE `pa_vehicleshop_showroom_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dealershipId` int(11) DEFAULT NULL,
  `data` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

-- Structure for `pa_vehicleshop_stocks`
DROP TABLE IF EXISTS `pa_vehicleshop_stocks`;
CREATE TABLE `pa_vehicleshop_stocks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dealershipId` int(11) DEFAULT NULL,
  `data` longtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- Structure for `pinel-crafting`
DROP TABLE IF EXISTS `pinel-crafting`;
CREATE TABLE `pinel-crafting` (
  `craft_id` int(11) NOT NULL AUTO_INCREMENT,
  `craft_name` varchar(50) DEFAULT NULL,
  `crafting` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`crafting`)),
  `blipdata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`blipdata`)),
  `jobs` longtext DEFAULT NULL,
  PRIMARY KEY (`craft_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Structure for `pinel_blip`
DROP TABLE IF EXISTS `pinel_blip`;
CREATE TABLE `pinel_blip` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `data` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=MyISAM AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;

-- Structure for `pinel_whitelist_config`
DROP TABLE IF EXISTS `pinel_whitelist_config`;
CREATE TABLE `pinel_whitelist_config` (
  `id` int(11) NOT NULL,
  `config` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `player_groups`
DROP TABLE IF EXISTS `player_groups`;
CREATE TABLE `player_groups` (
  `citizenid` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `group` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `grade` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY (`citizenid`,`type`,`group`),
  CONSTRAINT `fk_citizenid` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Structure for `player_mails`
DROP TABLE IF EXISTS `player_mails`;
CREATE TABLE `player_mails` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sender` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `subject` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `message` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `read` tinyint(4) DEFAULT 0,
  `mailid` int(11) DEFAULT NULL,
  `date` timestamp NULL DEFAULT current_timestamp(),
  `button` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `player_outfit_codes`
DROP TABLE IF EXISTS `player_outfit_codes`;
CREATE TABLE `player_outfit_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `outfitid` int(11) NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `FK_player_outfit_codes_player_outfits` (`outfitid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `player_outfits`
DROP TABLE IF EXISTS `player_outfits`;
CREATE TABLE `player_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `outfitname` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '0',
  `model` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `props` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `components` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid_outfitname_model` (`citizenid`,`outfitname`,`model`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `player_transactions`
DROP TABLE IF EXISTS `player_transactions`;
CREATE TABLE `player_transactions` (
  `id` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `isFrozen` int(11) DEFAULT 0,
  `transactions` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `player_vehicles`
DROP TABLE IF EXISTS `player_vehicles`;
CREATE TABLE `player_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `citizenid` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vehicle` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hash` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mods` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `plate` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fakeplate` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `garage` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fuel` int(11) DEFAULT 100,
  `engine` float DEFAULT 1000,
  `body` float DEFAULT 1000,
  `state` int(11) DEFAULT 1,
  `depotprice` int(11) NOT NULL DEFAULT 0,
  `drivingdistance` int(50) DEFAULT NULL,
  `status` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `coords` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `glovebox` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `trunk` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mileage` float NOT NULL DEFAULT 0,
  `balance` int(11) NOT NULL DEFAULT 0,
  `paymentamount` int(11) NOT NULL DEFAULT 0,
  `paymentsleft` int(11) NOT NULL DEFAULT 0,
  `financetime` int(11) NOT NULL DEFAULT 0,
  `vehicle_name` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deformation` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `parking_coords` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate` (`plate`),
  UNIQUE KEY `UK_playervehicles_plate` (`plate`),
  KEY `FK_playervehicles_players` (`citizenid`),
  CONSTRAINT `FK_playervehicles_players` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `player_vehicles_ibfk_1` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=64 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `players`
DROP TABLE IF EXISTS `players`;
CREATE TABLE `players` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userId` int(10) unsigned DEFAULT NULL,
  `citizenid` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cid` int(11) DEFAULT NULL,
  `license` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `money` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `charinfo` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `job` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `gang` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `position` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `metadata` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `inventory` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `last_logged_out` timestamp NULL DEFAULT NULL,
  `last_property` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `skills` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`citizenid`),
  KEY `id` (`id`),
  KEY `last_updated` (`last_updated`),
  KEY `license` (`license`)
) ENGINE=InnoDB AUTO_INCREMENT=6378 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `playerskins`
DROP TABLE IF EXISTS `playerskins`;
CREATE TABLE `playerskins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `skin` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `active` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `active` (`active`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `pr_bomboxplaylists`
DROP TABLE IF EXISTS `pr_bomboxplaylists`;
CREATE TABLE `pr_bomboxplaylists` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user` varchar(255) NOT NULL,
  `playlist` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

-- Structure for `pr_boomboxplaylists`
DROP TABLE IF EXISTS `pr_boomboxplaylists`;
CREATE TABLE `pr_boomboxplaylists` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user` varchar(255) NOT NULL,
  `playlist` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=121 DEFAULT CHARSET=utf8mb4 COMMENT='Configurações individuais das chaves de veículo';

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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=3709 DEFAULT CHARSET=utf8mb4 COMMENT='Configuracoes individuais de veiculo';

-- Structure for `pr_truck_areas`
DROP TABLE IF EXISTS `pr_truck_areas`;
CREATE TABLE `pr_truck_areas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vehicle_zone` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `unload_zone` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `pr_truck_player_prizes`
DROP TABLE IF EXISTS `pr_truck_player_prizes`;
CREATE TABLE `pr_truck_player_prizes` (
  `identifier` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `prize_id` int(11) NOT NULL,
  `claimed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`identifier`,`prize_id`),
  KEY `fk_pr_truck_player_prizes_id` (`prize_id`),
  CONSTRAINT `fk_pr_truck_player_prizes_id` FOREIGN KEY (`prize_id`) REFERENCES `pr_truck_prizes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `pr_truck_player_tablet_settings`
DROP TABLE IF EXISTS `pr_truck_player_tablet_settings`;
CREATE TABLE `pr_truck_player_tablet_settings` (
  `identifier` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `citizenid` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `language` varchar(12) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pt-BR',
  `theme` enum('dark','light') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'dark',
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
  `title` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `image` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `rewards` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `pr_truck_tablet_settings`
DROP TABLE IF EXISTS `pr_truck_tablet_settings`;
CREATE TABLE `pr_truck_tablet_settings` (
  `id` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `default_language` varchar(12) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'en',
  `default_theme` enum('dark','light') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'light',
  `allow_light_theme` tinyint(1) NOT NULL DEFAULT 1,
  `notifications_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `tablet_scale` float NOT NULL DEFAULT 1,
  `vehicle_img_url` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `peds_img_url` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ox_inventory_img_path` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ox_inventory_items_path` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `pr_truck_transporters`
DROP TABLE IF EXISTS `pr_truck_transporters`;
CREATE TABLE `pr_truck_transporters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `level_required` int(11) NOT NULL DEFAULT 0,
  `banner` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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
  `label` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4;

-- Structure for `pr_vehicle_scenario`
DROP TABLE IF EXISTS `pr_vehicle_scenario`;
CREATE TABLE `pr_vehicle_scenario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `event_id` int(11) NOT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_vehicle_event` (`event_id`),
  CONSTRAINT `fk_vehicle_event` FOREIGN KEY (`event_id`) REFERENCES `pr_vehicle_config` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4;

-- Structure for `pr_vehicle_sounds`
DROP TABLE IF EXISTS `pr_vehicle_sounds`;
CREATE TABLE `pr_vehicle_sounds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plate` varchar(50) NOT NULL,
  `data` longtext NOT NULL,
  `created` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_plate` (`plate`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4;

-- Structure for `pr_vehicle_xp`
DROP TABLE IF EXISTS `pr_vehicle_xp`;
CREATE TABLE `pr_vehicle_xp` (
  `plate` varchar(50) NOT NULL,
  `exp` int(11) NOT NULL DEFAULT 0,
  `points` int(11) NOT NULL DEFAULT 0,
  `voted` int(11) NOT NULL DEFAULT 0,
  `text` varchar(255) NOT NULL DEFAULT '0',
  PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Structure for `pr_vehiclekeys`
DROP TABLE IF EXISTS `pr_vehiclekeys`;
CREATE TABLE `pr_vehiclekeys` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Identifier do player (citizenid/identifier)',
  `plate` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Placa do veículo (sem espaços)',
  `vehicle_model` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Desconhecido' COMMENT 'Nome/modelo do veículo',
  `key_type` enum('permanent','temporary','onetime') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'permanent',
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Metadados extras da chave',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `sound` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Toque de tranca desta chave',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_citizen_plate` (`citizenid`,`plate`),
  KEY `idx_citizenid` (`citizenid`),
  KEY `idx_plate` (`plate`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `properties`
DROP TABLE IF EXISTS `properties`;
CREATE TABLE `properties` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `property_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `price` int(11) NOT NULL DEFAULT 0,
  `owner` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `interior` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `keyholders` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT json_object(),
  `rent_interval` int(11) DEFAULT NULL,
  `interact_options` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT json_object(),
  `stash_options` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT json_object(),
  `garage` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `owner` (`owner`),
  CONSTRAINT `properties_ibfk_1` FOREIGN KEY (`owner`) REFERENCES `players` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `properties_decorations`
DROP TABLE IF EXISTS `properties_decorations`;
CREATE TABLE `properties_decorations` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `property_id` int(11) NOT NULL,
  `model` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `rotation` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  PRIMARY KEY (`id`),
  KEY `property_id` (`property_id`),
  CONSTRAINT `properties_decorations_ibfk_1` FOREIGN KEY (`property_id`) REFERENCES `properties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;

-- Structure for `pug_atm`
DROP TABLE IF EXISTS `pug_atm`;
CREATE TABLE `pug_atm` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `settings` text DEFAULT '[]',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

-- Structure for `pug_banktruck`
DROP TABLE IF EXISTS `pug_banktruck`;
CREATE TABLE `pug_banktruck` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `settings` text DEFAULT '[]',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

-- Structure for `pug_heist`
DROP TABLE IF EXISTS `pug_heist`;
CREATE TABLE `pug_heist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `heist_name` varchar(50) NOT NULL,
  `stages` mediumtext DEFAULT '[]',
  `settings` text DEFAULT '[]',
  PRIMARY KEY (`id`),
  UNIQUE KEY `heist_name` (`heist_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Structure for `pug_sellitems`
DROP TABLE IF EXISTS `pug_sellitems`;
CREATE TABLE `pug_sellitems` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `settings` text DEFAULT '[]',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB AUTO_INCREMENT=50 DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4;

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
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

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
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

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
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

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
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `rf_dealership_favorites`
DROP TABLE IF EXISTS `rf_dealership_favorites`;
CREATE TABLE `rf_dealership_favorites` (
  `identifier` varchar(50) NOT NULL,
  `model` varchar(50) NOT NULL,
  PRIMARY KEY (`identifier`,`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4;

-- Structure for `territories_globals`
DROP TABLE IF EXISTS `territories_globals`;
CREATE TABLE `territories_globals` (
  `key_name` varchar(50) NOT NULL,
  `value` longtext DEFAULT NULL,
  PRIMARY KEY (`key_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

-- Structure for `users`
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `userId` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `license` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `license2` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fivem` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `discord` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`userId`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4;

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
  `plate` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Placa do veiculo',
  `part` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Identificador da peca',
  `stage` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Nivel/estagio da peca',
  `installed_km` int(10) unsigned NOT NULL DEFAULT 0,
  `durability` int(10) unsigned NOT NULL DEFAULT 0,
  `citizen_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'CitizenID de quem instalou',
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
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Structure for `wizating_dragstrip_objects`
DROP TABLE IF EXISTS `wizating_dragstrip_objects`;
CREATE TABLE `wizating_dragstrip_objects` (
  `id` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `wizating_stage_box_data` longtext COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`wizating_stage_box_data`)),
  `wizating_time_billboard_left_data` longtext COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`wizating_time_billboard_left_data`)),
  `wizating_time_billboard_right_data` longtext COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`wizating_time_billboard_right_data`)),
  `wizating_dragrace_scoretv_data` longtext COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`wizating_dragrace_scoretv_data`)),
  `wizating_treelight_body_data` longtext COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`wizating_treelight_body_data`)),
  `extra_track_objects` longtext COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`extra_track_objects`)),
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Structure for `xt_prison`
DROP TABLE IF EXISTS `xt_prison`;
CREATE TABLE `xt_prison` (
  `identifier` varchar(100) NOT NULL,
  `jailtime` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Structure for `xt_prison_items`
DROP TABLE IF EXISTS `xt_prison_items`;
CREATE TABLE `xt_prison_items` (
  `owner` varchar(60) DEFAULT NULL,
  `data` longtext DEFAULT NULL,
  UNIQUE KEY `owner` (`owner`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS=1;
