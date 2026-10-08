-- PR Bridge SQL Backup
-- Mode: schema
-- Tables: 220
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

-- Structure for `forge-crafting`
DROP TABLE IF EXISTS `forge-crafting`;
CREATE TABLE `forge-crafting` (
  `craft_id` int(11) NOT NULL AUTO_INCREMENT,
  `craft_name` varchar(50) DEFAULT NULL,
  `crafting` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `blipdata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `jobs` longtext DEFAULT NULL,
  `model_slug` varchar(50) DEFAULT 'default',
  PRIMARY KEY (`craft_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Structure for `forge-crafting-bench-models`
DROP TABLE IF EXISTS `forge-crafting-bench-models`;
CREATE TABLE `forge-crafting-bench-models` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `slug` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `model` varchar(100) NOT NULL,
  `center_offset` longtext NOT NULL,
  `scale` float NOT NULL DEFAULT 1,
  `anim_dict` varchar(100) NOT NULL DEFAULT 'anim@amb@board_room@diagram_blueprints@',
  `anim_name` varchar(100) NOT NULL DEFAULT 'idle_01_amy_skater_01',
  `anim_offset` longtext NOT NULL,
  `cam_offset` longtext NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Structure for `forge-crafting-items`
DROP TABLE IF EXISTS `forge-crafting-items`;
CREATE TABLE `forge-crafting-items` (
  `craft_id` int(11) DEFAULT NULL,
  `item` varchar(50) DEFAULT NULL,
  `item_label` varchar(50) DEFAULT NULL,
  `recipe` longtext DEFAULT NULL,
  `time` int(11) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `model` longtext DEFAULT NULL,
  `anim` longtext DEFAULT NULL,
  `level` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Structure for `forge_blip`
DROP TABLE IF EXISTS `forge_blip`;
CREATE TABLE `forge_blip` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `data` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `forge_garage_meter_fines`
DROP TABLE IF EXISTS `forge_garage_meter_fines`;
CREATE TABLE `forge_garage_meter_fines` (
  `id` varchar(100) NOT NULL,
  `plate` varchar(50) NOT NULL,
  `garage` varchar(120) DEFAULT NULL,
  `meter_id` varchar(80) DEFAULT NULL,
  `location` varchar(160) DEFAULT NULL,
  `occurred_time` char(5) DEFAULT NULL,
  `amount` int(11) NOT NULL,
  `created_at` bigint(20) NOT NULL,
  `active` tinyint(4) DEFAULT 1,
  `delivered` tinyint(4) DEFAULT 0,
  `reference` varchar(120) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `forge_garage_meter_sessions`
DROP TABLE IF EXISTS `forge_garage_meter_sessions`;
CREATE TABLE `forge_garage_meter_sessions` (
  `plate` varchar(50) NOT NULL,
  `payload` longtext NOT NULL,
  PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `forge_garage_parking_debts`
DROP TABLE IF EXISTS `forge_garage_parking_debts`;
CREATE TABLE `forge_garage_parking_debts` (
  `plate` varchar(50) NOT NULL,
  `garage` varchar(120) DEFAULT NULL,
  `meter_id` varchar(80) DEFAULT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `active` tinyint(4) NOT NULL DEFAULT 1,
  `session_parked_at` bigint(20) DEFAULT NULL,
  `session_charged_at` bigint(20) DEFAULT NULL,
  `reported_at` bigint(20) DEFAULT NULL,
  `report_reference` varchar(120) DEFAULT NULL,
  `updated_at` bigint(20) NOT NULL,
  PRIMARY KEY (`plate`),
  KEY `active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `forge_garage_parking_sessions`
DROP TABLE IF EXISTS `forge_garage_parking_sessions`;
CREATE TABLE `forge_garage_parking_sessions` (
  `plate` varchar(50) NOT NULL,
  `garage` varchar(120) NOT NULL,
  `meter_id` varchar(80) DEFAULT NULL,
  `parked_at` bigint(20) NOT NULL,
  `paid_until` bigint(20) DEFAULT NULL,
  `updated_at` bigint(20) NOT NULL,
  PRIMARY KEY (`plate`),
  KEY `garage` (`garage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `forge_phone_app_security`
DROP TABLE IF EXISTS `forge_phone_app_security`;
CREATE TABLE `forge_phone_app_security` (
  `device_id` varchar(36) NOT NULL,
  `app_id` varchar(64) NOT NULL,
  `pin_hash` char(64) NOT NULL,
  `pin_salt` varchar(64) NOT NULL,
  `pin_length` tinyint(3) unsigned NOT NULL,
  `fail_count` smallint(5) unsigned NOT NULL DEFAULT 0,
  `locked_until` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`device_id`,`app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `forge_phone_devices`
DROP TABLE IF EXISTS `forge_phone_devices`;
CREATE TABLE `forge_phone_devices` (
  `device_id` char(36) NOT NULL,
  `profile_id` char(36) NOT NULL,
  `serial_number` varchar(32) NOT NULL,
  `registered_owner_citizenid` varchar(50) NOT NULL,
  `current_user_citizenid` varchar(50) DEFAULT NULL,
  `pin_hash` varchar(128) DEFAULT NULL,
  `pin_salt` varchar(64) DEFAULT NULL,
  `pin_length` tinyint(3) unsigned DEFAULT NULL,
  `pin_fail_count` smallint(5) unsigned NOT NULL DEFAULT 0,
  `pin_locked_until` timestamp NULL DEFAULT NULL,
  `pin_updated_at` timestamp NULL DEFAULT NULL,
  `model` varchar(32) NOT NULL,
  `color` varchar(24) NOT NULL,
  `schema_version` smallint(5) unsigned NOT NULL DEFAULT 1,
  `status` varchar(16) NOT NULL DEFAULT 'active',
  `blocked_at` timestamp NULL DEFAULT NULL,
  `replaced_by_device_id` char(36) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_activated_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`device_id`),
  UNIQUE KEY `uq_forge_phone_devices_serial` (`serial_number`),
  KEY `idx_forge_phone_devices_owner` (`registered_owner_citizenid`),
  KEY `idx_forge_phone_devices_profile_status` (`profile_id`,`status`),
  KEY `idx_forge_phone_devices_current_user` (`current_user_citizenid`),
  CONSTRAINT `fk_forge_phone_devices_profile` FOREIGN KEY (`profile_id`) REFERENCES `forge_phone_profiles` (`profile_id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `forge_phone_lines`
DROP TABLE IF EXISTS `forge_phone_lines`;
CREATE TABLE `forge_phone_lines` (
  `line_id` char(36) NOT NULL,
  `profile_id` char(36) NOT NULL,
  `phone_number` varchar(20) NOT NULL,
  `status` varchar(16) NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`line_id`),
  UNIQUE KEY `uq_forge_phone_lines_number` (`phone_number`),
  UNIQUE KEY `uq_forge_phone_lines_profile` (`profile_id`),
  CONSTRAINT `fk_forge_phone_lines_profile` FOREIGN KEY (`profile_id`) REFERENCES `forge_phone_profiles` (`profile_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `forge_phone_profiles`
DROP TABLE IF EXISTS `forge_phone_profiles`;
CREATE TABLE `forge_phone_profiles` (
  `profile_id` char(36) NOT NULL,
  `settings` longtext DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`profile_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `forge_police_containment_objects`
DROP TABLE IF EXISTS `forge_police_containment_objects`;
CREATE TABLE `forge_police_containment_objects` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `object_type` varchar(50) NOT NULL,
  `owner` varchar(100) NOT NULL,
  `bucket` int(11) NOT NULL DEFAULT 0,
  `x` double NOT NULL,
  `y` double NOT NULL,
  `z` double NOT NULL,
  `rx` double NOT NULL DEFAULT 0,
  `ry` double NOT NULL DEFAULT 0,
  `rz` double NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_forge_police_containment_bucket` (`bucket`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `forge_police_speed_radars`
DROP TABLE IF EXISTS `forge_police_speed_radars`;
CREATE TABLE `forge_police_speed_radars` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `kind` varchar(12) NOT NULL,
  `label` varchar(80) NOT NULL,
  `model` varchar(80) NOT NULL,
  `speed_limit` int(11) NOT NULL,
  `law_up_to_20` varchar(50) NOT NULL,
  `law_up_to_50` varchar(50) NOT NULL,
  `law_over_50` varchar(50) NOT NULL,
  `x` double NOT NULL,
  `y` double NOT NULL,
  `z` double NOT NULL,
  `rx` double NOT NULL DEFAULT 0,
  `ry` double NOT NULL DEFAULT 0,
  `rz` double NOT NULL DEFAULT 0,
  `bucket` int(11) NOT NULL DEFAULT 0,
  `created_by` varchar(100) DEFAULT NULL,
  `created_at` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `kind` (`kind`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `forge_police_vehicle_citations`
DROP TABLE IF EXISTS `forge_police_vehicle_citations`;
CREATE TABLE `forge_police_vehicle_citations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(100) NOT NULL,
  `plate` varchar(50) NOT NULL,
  `kind` varchar(20) NOT NULL,
  `description` varchar(255) NOT NULL,
  `location` varchar(120) DEFAULT NULL,
  `amount` int(11) NOT NULL,
  `issued_at` bigint(20) NOT NULL,
  `status` varchar(20) NOT NULL,
  `edited_by` varchar(60) DEFAULT NULL,
  `edited_at` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `external_id` (`external_id`),
  KEY `plate` (`plate`)
) ENGINE=InnoDB AUTO_INCREMENT=1638 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `forge_police_vehicle_clamps`
DROP TABLE IF EXISTS `forge_police_vehicle_clamps`;
CREATE TABLE `forge_police_vehicle_clamps` (
  `vehicle_id` int(10) unsigned NOT NULL,
  `bone` varchar(32) NOT NULL,
  `officer` varchar(100) DEFAULT NULL,
  `applied_at` bigint(20) NOT NULL,
  PRIMARY KEY (`vehicle_id`),
  KEY `applied_at` (`applied_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `fox_engine_ac_detections`
DROP TABLE IF EXISTS `fox_engine_ac_detections`;
CREATE TABLE `fox_engine_ac_detections` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `player_id` varchar(64) NOT NULL,
  `player_name` varchar(100) NOT NULL,
  `detection_type` varchar(50) NOT NULL,
  `action_taken` enum('log','kick','ban') NOT NULL DEFAULT 'log',
  `details` text DEFAULT NULL,
  `coords_x` float NOT NULL DEFAULT 0,
  `coords_y` float NOT NULL DEFAULT 0,
  `coords_z` float NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_player` (`player_id`),
  KEY `idx_type` (`detection_type`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- Structure for `fox_engine_bans`
DROP TABLE IF EXISTS `fox_engine_bans`;
CREATE TABLE `fox_engine_bans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(100) NOT NULL,
  `player_name` varchar(100) DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `banned_by` varchar(100) DEFAULT 'Fox Engine AC',
  `expires_at` datetime DEFAULT NULL COMMENT 'NULL = permanente',
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_identifier` (`identifier`),
  KEY `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- Structure for `fox_engine_configs`
DROP TABLE IF EXISTS `fox_engine_configs`;
CREATE TABLE `fox_engine_configs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `god_mode` tinyint(1) NOT NULL DEFAULT 0,
  `anti_explosion_damage` tinyint(1) NOT NULL DEFAULT 0,
  `anti_ragdoll` tinyint(1) NOT NULL DEFAULT 0,
  `AntiInvisible` tinyint(1) NOT NULL DEFAULT 0,
  `AntiRadar` tinyint(1) NOT NULL DEFAULT 0,
  `AntiExplosiveBullets` tinyint(1) NOT NULL DEFAULT 0,
  `AntiNoClip` tinyint(1) NOT NULL DEFAULT 0,
  `AntiSpectate` tinyint(1) NOT NULL DEFAULT 0,
  `AntiSpeedHacks` tinyint(1) NOT NULL DEFAULT 0,
  `AntiThermalVision` tinyint(1) NOT NULL DEFAULT 0,
  `AntiNightVision` tinyint(1) NOT NULL DEFAULT 0,
  `AntiLicenseClears` tinyint(1) NOT NULL DEFAULT 0,
  `AntiCheatEngine` tinyint(1) NOT NULL DEFAULT 0,
  `AntiXenos` tinyint(1) NOT NULL DEFAULT 0,
  `AntiPedChange` tinyint(1) NOT NULL DEFAULT 0,
  `AntiFreeCam` tinyint(1) NOT NULL DEFAULT 0,
  `AntiMenyoo` tinyint(1) NOT NULL DEFAULT 0,
  `AntiGiveArmor` tinyint(1) NOT NULL DEFAULT 0,
  `AntiBlips` tinyint(1) NOT NULL DEFAULT 0,
  `AntiWeaponModifiers` tinyint(1) NOT NULL DEFAULT 0,
  `AntiVehicleModifiers` tinyint(1) NOT NULL DEFAULT 0,
  `AntiVDM` tinyint(1) NOT NULL DEFAULT 0,
  `AntiAimAssist` tinyint(1) NOT NULL DEFAULT 0,
  `SuperJump` tinyint(1) NOT NULL DEFAULT 0,
  `AntiSuicide` tinyint(1) NOT NULL DEFAULT 0,
  `AntiResourceStartorStop` tinyint(1) NOT NULL DEFAULT 0,
  `DeleteBrokenCars` tinyint(1) NOT NULL DEFAULT 0,
  `ClearPedsAfterDetection` tinyint(1) NOT NULL DEFAULT 0,
  `ClearObjectsAfterDetection` tinyint(1) NOT NULL DEFAULT 0,
  `ClearVehiclesAfterDetection` tinyint(1) NOT NULL DEFAULT 0,
  `DisableVehicleWeapons` tinyint(1) NOT NULL DEFAULT 0,
  `AntiInfiniteStamina` tinyint(1) NOT NULL DEFAULT 0,
  `AntiAimbot` tinyint(1) NOT NULL DEFAULT 0,
  `AntiAFK` tinyint(1) NOT NULL DEFAULT 0,
  `AutoBan` tinyint(1) NOT NULL DEFAULT 0,
  `ScreenshotPlayer` tinyint(1) NOT NULL DEFAULT 0,
  `TransferAttempts` int(10) unsigned NOT NULL DEFAULT 0,
  `MaxTransferAttempts` int(10) unsigned NOT NULL DEFAULT 0,
  `AntiVPN` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `fox_engine_economy_bank`
DROP TABLE IF EXISTS `fox_engine_economy_bank`;
CREATE TABLE `fox_engine_economy_bank` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `player_id` varchar(64) NOT NULL,
  `player_name` varchar(100) NOT NULL,
  `variation` bigint(20) NOT NULL,
  `balance_after` bigint(20) NOT NULL,
  `transaction_type` enum('Entrada','Saída') NOT NULL,
  `highlight` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_player` (`player_id`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `fox_engine_economy_items`
DROP TABLE IF EXISTS `fox_engine_economy_items`;
CREATE TABLE `fox_engine_economy_items` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `player_id` varchar(64) NOT NULL,
  `player_name` varchar(100) NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `item_label` varchar(100) NOT NULL,
  `quantity` int(11) NOT NULL,
  `action` enum('recebeu','removeu') NOT NULL,
  `direction` varchar(100) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_player` (`player_id`),
  KEY `idx_item` (`item_name`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `fox_engine_economy_vehicles`
DROP TABLE IF EXISTS `fox_engine_economy_vehicles`;
CREATE TABLE `fox_engine_economy_vehicles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `player_id` varchar(64) NOT NULL,
  `player_name` varchar(100) NOT NULL,
  `model_name` varchar(100) NOT NULL,
  `model_hash` varchar(20) NOT NULL,
  `coords_x` float NOT NULL,
  `coords_y` float NOT NULL,
  `coords_z` float NOT NULL,
  `forbidden` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_player` (`player_id`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `fox_engine_kick_logs`
DROP TABLE IF EXISTS `fox_engine_kick_logs`;
CREATE TABLE `fox_engine_kick_logs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `player_id` varchar(100) NOT NULL,
  `player_name` varchar(100) NOT NULL,
  `reason` text DEFAULT NULL,
  `source_type` varchar(50) NOT NULL DEFAULT 'system',
  `source_name` varchar(100) DEFAULT NULL,
  `admin_id` varchar(50) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_player` (`player_id`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `fox_engine_vehicle_blacklist`
DROP TABLE IF EXISTS `fox_engine_vehicle_blacklist`;
CREATE TABLE `fox_engine_vehicle_blacklist` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vehicle_name` varchar(100) NOT NULL,
  `hash` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `hash` (`hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `fox_engine_weap_blacklist`
DROP TABLE IF EXISTS `fox_engine_weap_blacklist`;
CREATE TABLE `fox_engine_weap_blacklist` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `weapon_name` varchar(100) NOT NULL,
  `hash` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `hash` (`hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `fox_engine_webhooks`
DROP TABLE IF EXISTS `fox_engine_webhooks`;
CREATE TABLE `fox_engine_webhooks` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `webhook_name` varchar(100) NOT NULL,
  `webhook_url` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `webhook_url` (`webhook_url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- Structure for `gangs_metadata`
DROP TABLE IF EXISTS `gangs_metadata`;
CREATE TABLE `gangs_metadata` (
  `gang_name` varchar(50) NOT NULL,
  `level` int(11) NOT NULL DEFAULT 1,
  `xp` int(11) NOT NULL DEFAULT 0,
  `bank_money` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`gang_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

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

-- Structure for `housing_enterprises`
DROP TABLE IF EXISTS `housing_enterprises`;
CREATE TABLE `housing_enterprises` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `kind` varchar(20) NOT NULL,
  `name` varchar(100) NOT NULL,
  `access_data` longtext NOT NULL,
  `revision` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `housing_hotel_keys`
DROP TABLE IF EXISTS `housing_hotel_keys`;
CREATE TABLE `housing_hotel_keys` (
  `stay_id` bigint(20) unsigned NOT NULL,
  `citizenid` varchar(64) NOT NULL,
  PRIMARY KEY (`stay_id`,`citizenid`),
  CONSTRAINT `housing_hotel_key_stay` FOREIGN KEY (`stay_id`) REFERENCES `housing_hotel_stays` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `housing_hotel_stays`
DROP TABLE IF EXISTS `housing_hotel_stays`;
CREATE TABLE `housing_hotel_stays` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `property_id` int(11) NOT NULL,
  `active_slot` int(11) DEFAULT NULL,
  `citizenid` varchar(64) NOT NULL,
  `request_id` varchar(100) NOT NULL,
  `status` varchar(24) NOT NULL,
  `duration_seconds` int(11) NOT NULL,
  `total` bigint(20) NOT NULL,
  `payment_account` varchar(8) NOT NULL,
  `payout_id` varchar(32) DEFAULT NULL,
  `reception` longtext NOT NULL,
  `created_at` bigint(20) NOT NULL,
  `start_at` bigint(20) DEFAULT NULL,
  `expires_at` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `hotel_request` (`request_id`),
  UNIQUE KEY `hotel_active_room` (`active_slot`),
  KEY `hotel_expiry` (`status`,`expires_at`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- Structure for `mdt_arrests`
DROP TABLE IF EXISTS `mdt_arrests`;
CREATE TABLE `mdt_arrests` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `officer_citizenid` varchar(50) DEFAULT NULL,
  `officer_name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `reportid` (`reportid`),
  KEY `citizenid` (`citizenid`),
  CONSTRAINT `FK_mdt_arrests_profiles` FOREIGN KEY (`citizenid`) REFERENCES `mdt_profiles` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_mdt_arrests_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_audit_logs`
DROP TABLE IF EXISTS `mdt_audit_logs`;
CREATE TABLE `mdt_audit_logs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `actor_citizenid` varchar(50) DEFAULT NULL,
  `actor_name` varchar(100) DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `entity_type` varchar(50) NOT NULL,
  `entity_id` varchar(50) DEFAULT NULL,
  `details` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `entity_type` (`entity_type`),
  KEY `entity_id` (`entity_id`),
  KEY `actor_citizenid` (`actor_citizenid`),
  KEY `action` (`action`),
  KEY `created_at` (`created_at`),
  KEY `idx_entity_lookup` (`entity_type`,`entity_id`,`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=330 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_awards`
DROP TABLE IF EXISTS `mdt_awards`;
CREATE TABLE `mdt_awards` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `icon` varchar(50) NOT NULL DEFAULT 'emoji_events',
  `category` varchar(50) NOT NULL DEFAULT 'general',
  `goal_type` varchar(50) NOT NULL,
  `goal_amount` int(10) unsigned NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_bolos`
DROP TABLE IF EXISTS `mdt_bolos`;
CREATE TABLE `mdt_bolos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` enum('citizen','vehicle','weapon','property','other') NOT NULL DEFAULT 'citizen',
  `subject_id` varchar(50) NOT NULL COMMENT 'citizenid, plate, serial, etc depending on type',
  `subject_name` varchar(100) DEFAULT NULL COMMENT 'Full name, vehicle model, weapon type, etc',
  `reportId` int(11) unsigned DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `status` enum('active','inactive','resolved') NOT NULL DEFAULT 'active',
  PRIMARY KEY (`id`),
  KEY `type` (`type`),
  KEY `subject_id` (`subject_id`),
  KEY `status` (`status`),
  KEY `reportId` (`reportId`),
  CONSTRAINT `FK_mdt_bolos_reports` FOREIGN KEY (`reportId`) REFERENCES `mdt_reports` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_bulletin_categories`
DROP TABLE IF EXISTS `mdt_bulletin_categories`;
CREATE TABLE `mdt_bulletin_categories` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job` varchar(50) NOT NULL,
  `value` varchar(48) NOT NULL,
  `label` varchar(48) NOT NULL,
  `icon` varchar(48) NOT NULL DEFAULT 'label',
  `color` varchar(7) NOT NULL DEFAULT '#6B7280',
  `sort_order` int(11) NOT NULL DEFAULT 0,
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mdt_bulletin_categories_job_value` (`job`,`value`),
  KEY `idx_mdt_bulletin_categories_job` (`job`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_bulletin_posts`
DROP TABLE IF EXISTS `mdt_bulletin_posts`;
CREATE TABLE `mdt_bulletin_posts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `author` varchar(100) DEFAULT NULL,
  `author_rank` varchar(50) DEFAULT NULL,
  `category` varchar(48) NOT NULL DEFAULT 'general',
  `priority` enum('urgent','high','normal','low') NOT NULL DEFAULT 'normal',
  `pinned` tinyint(1) NOT NULL DEFAULT 0,
  `job` varchar(50) NOT NULL,
  `created_by` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_mdt_bulletin_posts_job` (`job`,`pinned`),
  KEY `idx_mdt_bulletin_posts_job_category` (`job`,`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_bulletins`
DROP TABLE IF EXISTS `mdt_bulletins`;
CREATE TABLE `mdt_bulletins` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `content` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_cameras`
DROP TABLE IF EXISTS `mdt_cameras`;
CREATE TABLE `mdt_cameras` (
  `cam_id` varchar(50) NOT NULL,
  `cam_label` varchar(100) NOT NULL,
  `cam_type` enum('placed','store','bank','jewelry','government','medical','other') NOT NULL DEFAULT 'placed',
  `model` varchar(50) NOT NULL DEFAULT 'security_cam_03',
  `coords` text NOT NULL,
  `rotation` text NOT NULL,
  `feed_coords` text DEFAULT NULL COMMENT 'Decoupled camera feed position (what the operator sees). NULL = use prop coords',
  `feed_rotation` text DEFAULT NULL COMMENT 'Decoupled camera feed rotation. NULL = use prop rotation + heading offset',
  `feed_fov` float DEFAULT NULL COMMENT 'Decoupled camera feed FOV. NULL = default FOV',
  `rotation_limits` text DEFAULT NULL,
  `image` longtext DEFAULT NULL,
  `can_rotate` tinyint(1) NOT NULL DEFAULT 1,
  `is_online` tinyint(1) NOT NULL DEFAULT 1,
  `spawns_model` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'TRUE = spawns 3D model (player-placed), FALSE = virtual camera (uses existing world model)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`cam_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_case_attachments`
DROP TABLE IF EXISTS `mdt_case_attachments`;
CREATE TABLE `mdt_case_attachments` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `case_id` int(10) unsigned NOT NULL,
  `type` enum('photo','document','other') NOT NULL DEFAULT 'document',
  `url` varchar(255) NOT NULL,
  `label` varchar(100) DEFAULT NULL,
  `uploaded_by` varchar(50) DEFAULT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`),
  CONSTRAINT `FK_mdt_case_attachments_cases` FOREIGN KEY (`case_id`) REFERENCES `mdt_cases` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_case_notes`
DROP TABLE IF EXISTS `mdt_case_notes`;
CREATE TABLE `mdt_case_notes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `case_id` int(10) unsigned NOT NULL,
  `content` text NOT NULL,
  `author_citizenid` varchar(50) DEFAULT NULL,
  `author_name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`),
  CONSTRAINT `FK_mdt_case_notes_cases` FOREIGN KEY (`case_id`) REFERENCES `mdt_cases` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_case_officers`
DROP TABLE IF EXISTS `mdt_case_officers`;
CREATE TABLE `mdt_case_officers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `case_id` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `role` enum('primary','assisting','supervisor') NOT NULL DEFAULT 'assisting',
  `assigned_by` varchar(50) DEFAULT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`),
  KEY `citizenid` (`citizenid`),
  CONSTRAINT `FK_mdt_case_officers_cases` FOREIGN KEY (`case_id`) REFERENCES `mdt_cases` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_mdt_case_officers_profiles` FOREIGN KEY (`citizenid`) REFERENCES `mdt_profiles` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_case_reports`
DROP TABLE IF EXISTS `mdt_case_reports`;
CREATE TABLE `mdt_case_reports` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `case_id` int(10) unsigned NOT NULL,
  `report_id` int(10) unsigned NOT NULL,
  `linked_by` varchar(50) DEFAULT NULL,
  `linked_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_case_report` (`case_id`,`report_id`),
  KEY `case_id` (`case_id`),
  KEY `report_id` (`report_id`),
  CONSTRAINT `FK_case_reports_cases` FOREIGN KEY (`case_id`) REFERENCES `mdt_cases` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_case_reports_reports` FOREIGN KEY (`report_id`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_cases`
DROP TABLE IF EXISTS `mdt_cases`;
CREATE TABLE `mdt_cases` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `case_number` varchar(30) NOT NULL,
  `title` varchar(100) NOT NULL,
  `summary` text DEFAULT NULL,
  `status` enum('open','in_progress','closed') NOT NULL DEFAULT 'open',
  `priority` enum('low','medium','high') NOT NULL DEFAULT 'medium',
  `assigned_department` varchar(50) DEFAULT NULL,
  `created_by` varchar(50) NOT NULL,
  `created_by_name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `case_number` (`case_number`),
  KEY `status` (`status`),
  KEY `assigned_department` (`assigned_department`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_charge_categories`
DROP TABLE IF EXISTS `mdt_charge_categories`;
CREATE TABLE `mdt_charge_categories` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(100) NOT NULL,
  `sort_order` int(10) unsigned NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `title` (`title`)
) ENGINE=InnoDB AUTO_INCREMENT=499 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_charge_tags`
DROP TABLE IF EXISTS `mdt_charge_tags`;
CREATE TABLE `mdt_charge_tags` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `color` varchar(7) NOT NULL DEFAULT '#f97316',
  `sort_order` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_citizen_licenses`
DROP TABLE IF EXISTS `mdt_citizen_licenses`;
CREATE TABLE `mdt_citizen_licenses` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `license_id` int(10) unsigned NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `granted_by` varchar(50) DEFAULT NULL,
  `granted_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_citizen_license` (`citizenid`,`license_id`),
  KEY `citizenid` (`citizenid`),
  KEY `license_id` (`license_id`),
  CONSTRAINT `FK_mdt_citizen_licenses_custom` FOREIGN KEY (`license_id`) REFERENCES `mdt_custom_licenses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_court_attendees`
DROP TABLE IF EXISTS `mdt_court_attendees`;
CREATE TABLE `mdt_court_attendees` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `hearing_id` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `display_name` varchar(100) DEFAULT NULL,
  `role` enum('prosecutor','defense','officer','witness','judge','trainee','instructor','attendee') NOT NULL DEFAULT 'officer',
  `notified_at` datetime DEFAULT NULL,
  `delivered_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mdt_court_attendees_hearing_cid` (`hearing_id`,`citizenid`),
  KEY `idx_mdt_court_attendees_citizen` (`citizenid`),
  CONSTRAINT `FK_mdt_court_attendees_hearing` FOREIGN KEY (`hearing_id`) REFERENCES `mdt_court_hearings` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_court_cases`
DROP TABLE IF EXISTS `mdt_court_cases`;
CREATE TABLE `mdt_court_cases` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `case_number` varchar(30) NOT NULL DEFAULT '',
  `title` varchar(255) NOT NULL,
  `summary` text DEFAULT NULL,
  `status` enum('pending','scheduled','in_trial','closed','dismissed','appealed') NOT NULL DEFAULT 'pending',
  `case_type` enum('criminal','civil','appeal','motion') NOT NULL DEFAULT 'criminal',
  `presiding_judge` varchar(50) DEFAULT NULL,
  `presiding_judge_name` varchar(100) DEFAULT NULL,
  `prosecutor` varchar(50) DEFAULT NULL,
  `prosecutor_name` varchar(100) DEFAULT NULL,
  `defense_attorney` varchar(50) DEFAULT NULL,
  `defense_attorney_name` varchar(100) DEFAULT NULL,
  `defendant_citizenid` varchar(50) DEFAULT NULL,
  `defendant_name` varchar(100) DEFAULT NULL,
  `hearing_date` datetime DEFAULT NULL,
  `filed_date` datetime DEFAULT current_timestamp(),
  `closed_date` datetime DEFAULT NULL,
  `linked_mdt_case_id` int(10) unsigned DEFAULT NULL,
  `referred_from_report_id` int(10) unsigned DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_by` varchar(50) NOT NULL,
  `created_by_name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`),
  KEY `idx_defendant` (`defendant_citizenid`),
  KEY `idx_hearing_date` (`hearing_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_court_hearings`
DROP TABLE IF EXISTS `mdt_court_hearings`;
CREATE TABLE `mdt_court_hearings` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `category` enum('court','training','meeting','other') NOT NULL DEFAULT 'court',
  `hearing_type` enum('arraignment','trial','sentencing','appeal','motion','hearing','other') NOT NULL DEFAULT 'trial',
  `case_id` int(10) unsigned DEFAULT NULL,
  `warrant_reportid` int(10) unsigned DEFAULT NULL,
  `defendant_cid` varchar(50) DEFAULT NULL,
  `defendant_name` varchar(100) DEFAULT NULL,
  `scheduled_at` datetime NOT NULL,
  `duration_minutes` int(11) NOT NULL DEFAULT 30,
  `location` varchar(255) DEFAULT NULL,
  `judge_cid` varchar(50) DEFAULT NULL,
  `judge_name` varchar(100) DEFAULT NULL,
  `status` enum('scheduled','in_session','completed','adjourned','cancelled') NOT NULL DEFAULT 'scheduled',
  `notes` text DEFAULT NULL,
  `created_by` varchar(50) NOT NULL,
  `created_by_name` varchar(100) DEFAULT NULL,
  `job_type` varchar(10) NOT NULL DEFAULT 'police',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_mdt_court_hearings_schedule` (`job_type`,`scheduled_at`),
  KEY `idx_mdt_court_hearings_status` (`status`),
  KEY `idx_mdt_court_hearings_case` (`case_id`),
  CONSTRAINT `FK_mdt_court_hearings_cases` FOREIGN KEY (`case_id`) REFERENCES `mdt_cases` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_court_orders`
DROP TABLE IF EXISTS `mdt_court_orders`;
CREATE TABLE `mdt_court_orders` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_number` varchar(30) NOT NULL DEFAULT '',
  `court_case_id` int(10) unsigned DEFAULT NULL,
  `type` enum('restraining_order','subpoena','bail_conditions','search_warrant','arrest_warrant','other') NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `target_citizenid` varchar(50) DEFAULT NULL,
  `target_name` varchar(100) DEFAULT NULL,
  `status` enum('active','expired','revoked') NOT NULL DEFAULT 'active',
  `issued_by` varchar(50) NOT NULL,
  `issued_by_name` varchar(100) DEFAULT NULL,
  `effective_date` datetime DEFAULT current_timestamp(),
  `expiry_date` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_court_case` (`court_case_id`),
  KEY `idx_target` (`target_citizenid`),
  KEY `idx_status` (`status`),
  KEY `idx_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_custom_licenses`
DROP TABLE IF EXISTS `mdt_custom_licenses`;
CREATE TABLE `mdt_custom_licenses` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `description` varchar(150) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_license_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_evidence_custody`
DROP TABLE IF EXISTS `mdt_evidence_custody`;
CREATE TABLE `mdt_evidence_custody` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `evidence_id` int(10) unsigned NOT NULL,
  `from_citizenid` varchar(50) DEFAULT NULL,
  `to_citizenid` varchar(50) DEFAULT NULL,
  `action` enum('collected','transferred','stored','released','updated','viewed') NOT NULL DEFAULT 'collected',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `evidence_id` (`evidence_id`),
  CONSTRAINT `FK_mdt_evidence_custody_items` FOREIGN KEY (`evidence_id`) REFERENCES `mdt_evidence_items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_evidence_images`
DROP TABLE IF EXISTS `mdt_evidence_images`;
CREATE TABLE `mdt_evidence_images` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `evidence_id` int(10) unsigned NOT NULL,
  `url` varchar(255) NOT NULL,
  `label` varchar(100) DEFAULT NULL,
  `uploaded_by` varchar(50) DEFAULT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `evidence_id` (`evidence_id`),
  CONSTRAINT `FK_mdt_evidence_images_items` FOREIGN KEY (`evidence_id`) REFERENCES `mdt_evidence_items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_evidence_items`
DROP TABLE IF EXISTS `mdt_evidence_items`;
CREATE TABLE `mdt_evidence_items` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `case_id` int(10) unsigned DEFAULT NULL,
  `report_id` int(10) unsigned DEFAULT NULL,
  `title` varchar(100) NOT NULL,
  `type` varchar(50) NOT NULL,
  `serial` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `location` varchar(100) DEFAULT NULL,
  `stash_id` varchar(100) DEFAULT NULL,
  `stored` tinyint(1) NOT NULL DEFAULT 0,
  `last_holder` varchar(50) DEFAULT NULL,
  `created_by` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`),
  KEY `report_id` (`report_id`),
  KEY `last_holder` (`last_holder`),
  CONSTRAINT `FK_mdt_evidence_items_cases` FOREIGN KEY (`case_id`) REFERENCES `mdt_cases` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `FK_mdt_evidence_items_reports` FOREIGN KEY (`report_id`) REFERENCES `mdt_reports` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_fto_assignments`
DROP TABLE IF EXISTS `mdt_fto_assignments`;
CREATE TABLE `mdt_fto_assignments` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `fto_number` varchar(20) NOT NULL DEFAULT '',
  `trainee_citizenid` varchar(50) NOT NULL,
  `trainee_name` varchar(100) NOT NULL,
  `trainer_citizenid` varchar(50) NOT NULL,
  `trainer_name` varchar(100) NOT NULL,
  `current_phase_id` int(10) unsigned DEFAULT NULL,
  `status` enum('active','completed','failed','suspended') NOT NULL DEFAULT 'active',
  `start_date` varchar(20) DEFAULT NULL,
  `end_date` varchar(20) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `job_type` varchar(10) NOT NULL DEFAULT 'police',
  PRIMARY KEY (`id`),
  UNIQUE KEY `fto_number` (`fto_number`),
  KEY `trainee_citizenid` (`trainee_citizenid`),
  KEY `trainer_citizenid` (`trainer_citizenid`),
  KEY `status` (`status`),
  KEY `current_phase_id` (`current_phase_id`),
  CONSTRAINT `FK_fto_assignments_phase` FOREIGN KEY (`current_phase_id`) REFERENCES `mdt_fto_phases` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_fto_competencies`
DROP TABLE IF EXISTS `mdt_fto_competencies`;
CREATE TABLE `mdt_fto_competencies` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job` varchar(50) NOT NULL DEFAULT 'police',
  `name` varchar(200) NOT NULL,
  `category` varchar(100) DEFAULT 'General',
  `sort_order` int(10) unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `job` (`job`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_fto_dor_ratings`
DROP TABLE IF EXISTS `mdt_fto_dor_ratings`;
CREATE TABLE `mdt_fto_dor_ratings` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `dor_id` int(10) unsigned NOT NULL,
  `competency_id` int(10) unsigned NOT NULL,
  `rating` int(1) unsigned NOT NULL DEFAULT 3,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `dor_id` (`dor_id`),
  KEY `competency_id` (`competency_id`),
  CONSTRAINT `FK_fto_dor_ratings_competency` FOREIGN KEY (`competency_id`) REFERENCES `mdt_fto_competencies` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_fto_dor_ratings_dor` FOREIGN KEY (`dor_id`) REFERENCES `mdt_fto_dors` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_fto_dors`
DROP TABLE IF EXISTS `mdt_fto_dors`;
CREATE TABLE `mdt_fto_dors` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `assignment_id` int(10) unsigned NOT NULL,
  `phase_id` int(10) unsigned DEFAULT NULL,
  `author_citizenid` varchar(50) NOT NULL,
  `author_name` varchar(100) NOT NULL,
  `shift_date` varchar(20) NOT NULL,
  `overall_rating` int(1) unsigned NOT NULL DEFAULT 3,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `assignment_id` (`assignment_id`),
  KEY `phase_id` (`phase_id`),
  CONSTRAINT `FK_fto_dors_assignment` FOREIGN KEY (`assignment_id`) REFERENCES `mdt_fto_assignments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_fto_dors_phase` FOREIGN KEY (`phase_id`) REFERENCES `mdt_fto_phases` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_fto_phases`
DROP TABLE IF EXISTS `mdt_fto_phases`;
CREATE TABLE `mdt_fto_phases` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job` varchar(50) NOT NULL DEFAULT 'police',
  `name` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `duration_days` int(10) unsigned DEFAULT 0,
  `sort_order` int(10) unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `job` (`job`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_ia_complaints`
DROP TABLE IF EXISTS `mdt_ia_complaints`;
CREATE TABLE `mdt_ia_complaints` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `complaint_number` varchar(20) NOT NULL,
  `complainant_citizenid` varchar(50) DEFAULT NULL,
  `complainant_name` varchar(100) NOT NULL,
  `complainant_phone` varchar(20) DEFAULT NULL,
  `officer_name` varchar(100) NOT NULL,
  `officer_badge` varchar(20) DEFAULT NULL,
  `category` enum('misconduct','excessive_force','corruption','negligence','discrimination','other') NOT NULL DEFAULT 'other',
  `description` text NOT NULL,
  `incident_date` varchar(20) DEFAULT NULL,
  `incident_location` varchar(200) DEFAULT NULL,
  `witnesses` text DEFAULT NULL,
  `evidence` text DEFAULT NULL,
  `status` enum('open','under_review','investigated','sustained','exonerated','unfounded','closed') NOT NULL DEFAULT 'open',
  `assigned_to` varchar(50) DEFAULT NULL,
  `assigned_to_name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `job_type` varchar(10) NOT NULL DEFAULT 'police',
  PRIMARY KEY (`id`),
  UNIQUE KEY `complaint_number` (`complaint_number`),
  KEY `status` (`status`),
  KEY `assigned_to` (`assigned_to`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_ia_notes`
DROP TABLE IF EXISTS `mdt_ia_notes`;
CREATE TABLE `mdt_ia_notes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `complaint_id` int(10) unsigned NOT NULL,
  `content` text NOT NULL,
  `author_citizenid` varchar(50) DEFAULT NULL,
  `author_name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `complaint_id` (`complaint_id`),
  CONSTRAINT `FK_ia_notes_complaints` FOREIGN KEY (`complaint_id`) REFERENCES `mdt_ia_complaints` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_impound`
DROP TABLE IF EXISTS `mdt_impound`;
CREATE TABLE `mdt_impound` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vehicleid` int(11) NOT NULL,
  `status` enum('active','released') NOT NULL DEFAULT 'active',
  `plate` varchar(16) DEFAULT NULL,
  `reason` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `photo` varchar(255) DEFAULT NULL,
  `lot` varchar(32) DEFAULT NULL,
  `linkedreport` int(10) unsigned DEFAULT NULL,
  `fee` int(11) NOT NULL DEFAULT 0,
  `fee_paid` tinyint(1) NOT NULL DEFAULT 0,
  `hold_type` enum('immediate','timed','indefinite') NOT NULL DEFAULT 'immediate',
  `hold_until` int(11) DEFAULT NULL,
  `hold_label` varchar(64) DEFAULT NULL,
  `officer_citizenid` varchar(50) DEFAULT NULL,
  `officer_name` varchar(100) DEFAULT NULL,
  `time` int(11) NOT NULL DEFAULT 0,
  `released_at` int(11) DEFAULT NULL,
  `released_by_citizenid` varchar(50) DEFAULT NULL,
  `released_by_name` varchar(100) DEFAULT NULL,
  `override_reason` varchar(300) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `vehicleid` (`vehicleid`),
  KEY `linkedreport` (`linkedreport`),
  KEY `idx_impound_status` (`status`,`time`),
  KEY `idx_impound_plate` (`plate`),
  CONSTRAINT `FK_mdt_impound_reports` FOREIGN KEY (`linkedreport`) REFERENCES `mdt_reports` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Structure for `mdt_legal_documents`
DROP TABLE IF EXISTS `mdt_legal_documents`;
CREATE TABLE `mdt_legal_documents` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `court_case_id` int(10) unsigned DEFAULT NULL,
  `type` enum('brief','motion','ruling','opinion','plea_deal','sentencing','other') NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` longtext DEFAULT NULL,
  `status` enum('draft','filed','approved','rejected') NOT NULL DEFAULT 'draft',
  `author_citizenid` varchar(50) NOT NULL,
  `author_name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_court_case` (`court_case_id`),
  KEY `idx_author` (`author_citizenid`),
  KEY `idx_type` (`type`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_messages`
DROP TABLE IF EXISTS `mdt_messages`;
CREATE TABLE `mdt_messages` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sender_citizenid` varchar(50) NOT NULL,
  `sender_name` varchar(100) DEFAULT NULL,
  `receiver_citizenid` varchar(50) NOT NULL,
  `receiver_name` varchar(100) DEFAULT NULL,
  `subject` varchar(120) DEFAULT NULL,
  `body` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `read_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sender_citizenid` (`sender_citizenid`),
  KEY `receiver_citizenid` (`receiver_citizenid`),
  CONSTRAINT `FK_mdt_messages_receiver` FOREIGN KEY (`receiver_citizenid`) REFERENCES `mdt_profiles` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_mdt_messages_sender` FOREIGN KEY (`sender_citizenid`) REFERENCES `mdt_profiles` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_officer_status`
DROP TABLE IF EXISTS `mdt_officer_status`;
CREATE TABLE `mdt_officer_status` (
  `citizenid` varchar(64) NOT NULL,
  `status` varchar(32) NOT NULL DEFAULT 'active',
  `note` varchar(120) DEFAULT NULL,
  `job_type` varchar(10) NOT NULL DEFAULT 'police',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`citizenid`),
  KEY `idx_mdt_officer_status_job` (`job_type`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_patrols`
DROP TABLE IF EXISTS `mdt_patrols`;
CREATE TABLE `mdt_patrols` (
  `id` varchar(64) NOT NULL,
  `name` varchar(64) NOT NULL,
  `color` varchar(7) NOT NULL DEFAULT '#3B82F6',
  `member_ids` longtext DEFAULT NULL,
  `sort_order` int(11) NOT NULL DEFAULT 0,
  `zone_points` longtext DEFAULT NULL,
  `job_type` varchar(10) NOT NULL DEFAULT 'police',
  PRIMARY KEY (`id`),
  KEY `idx_mdt_patrols_job_sort` (`job_type`,`sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_penal_code_tags`
DROP TABLE IF EXISTS `mdt_penal_code_tags`;
CREATE TABLE `mdt_penal_code_tags` (
  `charge_code` varchar(50) NOT NULL,
  `tag_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`charge_code`,`tag_id`),
  KEY `tag_id` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_penal_codes`
DROP TABLE IF EXISTS `mdt_penal_codes`;
CREATE TABLE `mdt_penal_codes` (
  `code` varchar(20) NOT NULL,
  `label` varchar(100) NOT NULL,
  `charge_class` enum('felony','misdemeanor','infraction') NOT NULL,
  `months` int(10) unsigned NOT NULL DEFAULT 0,
  `fine` int(10) unsigned NOT NULL DEFAULT 0,
  `color` varchar(20) NOT NULL,
  `description` varchar(255) NOT NULL,
  `category` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`code`),
  KEY `label` (`label`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_permission_roles`
DROP TABLE IF EXISTS `mdt_permission_roles`;
CREATE TABLE `mdt_permission_roles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job` varchar(50) NOT NULL,
  `grade` int(10) unsigned NOT NULL,
  `permissions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`permissions`)),
  `updated_by` varchar(50) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `job_grade` (`job`,`grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_ppr`
DROP TABLE IF EXISTS `mdt_ppr`;
CREATE TABLE `mdt_ppr` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ppr_number` varchar(20) NOT NULL DEFAULT '',
  `officer_citizenid` varchar(50) NOT NULL,
  `officer_name` varchar(100) NOT NULL,
  `author_citizenid` varchar(50) NOT NULL,
  `author_name` varchar(100) NOT NULL,
  `category` enum('positive','coaching','disciplinary') NOT NULL DEFAULT 'coaching',
  `title` varchar(200) NOT NULL,
  `description` text NOT NULL,
  `incident_date` varchar(20) DEFAULT NULL,
  `incident_location` varchar(200) DEFAULT NULL,
  `linked_report_id` int(10) unsigned DEFAULT NULL,
  `linked_case_id` int(10) unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `job_type` varchar(10) NOT NULL DEFAULT 'police',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ppr_number` (`ppr_number`),
  KEY `officer_citizenid` (`officer_citizenid`),
  KEY `author_citizenid` (`author_citizenid`),
  KEY `category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_ppr_notes`
DROP TABLE IF EXISTS `mdt_ppr_notes`;
CREATE TABLE `mdt_ppr_notes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ppr_id` int(10) unsigned NOT NULL,
  `content` text NOT NULL,
  `author_citizenid` varchar(50) DEFAULT NULL,
  `author_name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `ppr_id` (`ppr_id`),
  CONSTRAINT `FK_ppr_notes_ppr` FOREIGN KEY (`ppr_id`) REFERENCES `mdt_ppr` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_profile_sessions`
DROP TABLE IF EXISTS `mdt_profile_sessions`;
CREATE TABLE `mdt_profile_sessions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `profile_id` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `source` int(11) DEFAULT NULL,
  `login_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `logout_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `profile_id` (`profile_id`),
  KEY `citizenid` (`citizenid`),
  KEY `idx_profile_logout` (`profile_id`,`logout_at`),
  CONSTRAINT `FK_mdt_profile_sessions_profiles` FOREIGN KEY (`profile_id`) REFERENCES `mdt_profiles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=148 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_profiles`
DROP TABLE IF EXISTS `mdt_profiles`;
CREATE TABLE `mdt_profiles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `fullname` varchar(50) NOT NULL,
  `callsign` varchar(50) DEFAULT NULL,
  `badge_number` varchar(20) DEFAULT NULL,
  `rank` varchar(50) DEFAULT NULL,
  `department` varchar(50) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `profilepicture` varchar(255) DEFAULT NULL,
  `certifications` text DEFAULT NULL,
  `last_login_at` timestamp NULL DEFAULT NULL,
  `last_logout_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid` (`citizenid`),
  UNIQUE KEY `callsign` (`callsign`),
  KEY `badge_number` (`badge_number`),
  KEY `idx_department` (`department`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_profiles_clocking`
DROP TABLE IF EXISTS `mdt_profiles_clocking`;
CREATE TABLE `mdt_profiles_clocking` (
  `profileId` int(10) unsigned NOT NULL,
  `clockindate` timestamp NOT NULL DEFAULT current_timestamp(),
  `clockoutdate` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  KEY `FK_mdt_profiles_clocking_mdt_profiles` (`profileId`),
  CONSTRAINT `FK_mdt_profiles_clocking_mdt_profiles` FOREIGN KEY (`profileId`) REFERENCES `mdt_profiles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_profiles_gallery`
DROP TABLE IF EXISTS `mdt_profiles_gallery`;
CREATE TABLE `mdt_profiles_gallery` (
  `profileId` int(10) unsigned NOT NULL,
  `image` varchar(255) NOT NULL,
  `label` varchar(50) DEFAULT NULL,
  `datecreated` timestamp NOT NULL DEFAULT current_timestamp(),
  KEY `FK_mdt_profiles_gallery_mdt_profiles` (`profileId`),
  CONSTRAINT `FK_mdt_profiles_gallery_mdt_profiles` FOREIGN KEY (`profileId`) REFERENCES `mdt_profiles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_profiles_identifiers`
DROP TABLE IF EXISTS `mdt_profiles_identifiers`;
CREATE TABLE `mdt_profiles_identifiers` (
  `profileId` int(10) unsigned NOT NULL,
  `content` varchar(50) NOT NULL,
  `datecreated` timestamp NOT NULL DEFAULT current_timestamp(),
  KEY `FK_mdt_profiles_identifiers_mdt_profiles` (`profileId`),
  CONSTRAINT `FK_mdt_profiles_identifiers_mdt_profiles` FOREIGN KEY (`profileId`) REFERENCES `mdt_profiles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_profiles_tags`
DROP TABLE IF EXISTS `mdt_profiles_tags`;
CREATE TABLE `mdt_profiles_tags` (
  `profileId` int(10) unsigned NOT NULL,
  `tag` varchar(15) NOT NULL,
  UNIQUE KEY `unique_profile_tag` (`profileId`,`tag`),
  KEY `FK_mdt_profiles_tags_mdt_profiles` (`profileId`),
  CONSTRAINT `FK_mdt_profiles_tags_mdt_profiles` FOREIGN KEY (`profileId`) REFERENCES `mdt_profiles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_report_templates`
DROP TABLE IF EXISTS `mdt_report_templates`;
CREATE TABLE `mdt_report_templates` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `type` varchar(50) NOT NULL,
  `content` longtext NOT NULL,
  `job_type` varchar(50) DEFAULT 'all',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_type` (`type`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_report_vehicles`
DROP TABLE IF EXISTS `mdt_report_vehicles`;
CREATE TABLE `mdt_report_vehicles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `plate` varchar(50) NOT NULL,
  `vehicle_label` varchar(100) DEFAULT NULL,
  `owner_name` varchar(100) DEFAULT NULL,
  `owner_citizenid` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_mdt_report_vehicles_mdt_reports` (`reportid`),
  KEY `idx_report_vehicles_plate` (`plate`),
  CONSTRAINT `FK_mdt_report_vehicles_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_reports`
DROP TABLE IF EXISTS `mdt_reports`;
CREATE TABLE `mdt_reports` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(50) DEFAULT NULL,
  `type` varchar(25) NOT NULL,
  `contentyjs` longblob DEFAULT NULL,
  `contentplaintext` text DEFAULT NULL,
  `author` varchar(50) DEFAULT NULL,
  `authorplaintext` varchar(100) DEFAULT NULL,
  `datecreated` timestamp NOT NULL DEFAULT current_timestamp(),
  `dateupdated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `lawyer_requested` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_author` (`author`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_reports_charges`
DROP TABLE IF EXISTS `mdt_reports_charges`;
CREATE TABLE `mdt_reports_charges` (
  `reportid` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `charge` varchar(100) DEFAULT NULL,
  `count` int(10) unsigned NOT NULL DEFAULT 1,
  `time` int(10) unsigned DEFAULT NULL,
  `fine` int(10) unsigned DEFAULT NULL,
  KEY `FK_mdt_reports_charges_mdt_reports` (`reportid`),
  KEY `FK_mdt_reports_charges_mdt_penal_codes` (`charge`),
  KEY `idx_charges_citizenid` (`citizenid`),
  CONSTRAINT `FK_mdt_reports_charges_mdt_penal_codes` FOREIGN KEY (`charge`) REFERENCES `mdt_penal_codes` (`label`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_mdt_reports_charges_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_reports_evidence`
DROP TABLE IF EXISTS `mdt_reports_evidence`;
CREATE TABLE `mdt_reports_evidence` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `title` varchar(255) NOT NULL DEFAULT '',
  `type` varchar(50) NOT NULL,
  `content` varchar(255) NOT NULL,
  `note` text DEFAULT NULL,
  `stored` tinyint(4) NOT NULL DEFAULT 0,
  `images` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_mdt_reports_evidence_mdt_reports` (`reportid`),
  CONSTRAINT `FK_mdt_reports_evidence_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_reports_involved`
DROP TABLE IF EXISTS `mdt_reports_involved`;
CREATE TABLE `mdt_reports_involved` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `type` varchar(15) NOT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_mdt_reports_involved_mdt_reports` (`reportid`),
  KEY `idx_involved_citizenid` (`citizenid`),
  CONSTRAINT `FK_mdt_reports_involved_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_reports_restrictions`
DROP TABLE IF EXISTS `mdt_reports_restrictions`;
CREATE TABLE `mdt_reports_restrictions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `type` varchar(7) NOT NULL,
  `identifier` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_mdt_reports_restrictions_mdt_reports` (`reportid`),
  CONSTRAINT `FK_mdt_reports_restrictions_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_reports_tags`
DROP TABLE IF EXISTS `mdt_reports_tags`;
CREATE TABLE `mdt_reports_tags` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `tag` varchar(25) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_mdt_reports_tags_mdt_reports` (`reportid`),
  CONSTRAINT `FK_mdt_reports_tags_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_reports_warrants`
DROP TABLE IF EXISTS `mdt_reports_warrants`;
CREATE TABLE `mdt_reports_warrants` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL DEFAULT '',
  `felonies` int(10) unsigned NOT NULL DEFAULT 0,
  `misdemeanors` int(10) unsigned NOT NULL DEFAULT 0,
  `infractions` int(10) unsigned NOT NULL DEFAULT 0,
  `expirydate` timestamp NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_warrant` (`reportid`,`citizenid`),
  KEY `FK_mdt_reports_warrants_mdt_reports` (`reportid`),
  KEY `FK_mdt_reports_warrants_mdt_profiles` (`citizenid`),
  CONSTRAINT `FK_mdt_reports_warrants_mdt_profiles` FOREIGN KEY (`citizenid`) REFERENCES `mdt_profiles` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_mdt_reports_warrants_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_settings`
DROP TABLE IF EXISTS `mdt_settings`;
CREATE TABLE `mdt_settings` (
  `key` varchar(100) NOT NULL,
  `value` longtext DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_sop_acknowledgements`
DROP TABLE IF EXISTS `mdt_sop_acknowledgements`;
CREATE TABLE `mdt_sop_acknowledgements` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `job` varchar(50) NOT NULL,
  `version` int(10) unsigned NOT NULL,
  `agreed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid_job` (`citizenid`,`job`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_sop_categories`
DROP TABLE IF EXISTS `mdt_sop_categories`;
CREATE TABLE `mdt_sop_categories` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job` varchar(50) NOT NULL,
  `title` varchar(200) NOT NULL,
  `icon` varchar(50) DEFAULT 'description',
  `sort_order` int(10) unsigned DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `job` (`job`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_sop_sections`
DROP TABLE IF EXISTS `mdt_sop_sections`;
CREATE TABLE `mdt_sop_sections` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `category_id` int(10) unsigned NOT NULL,
  `title` varchar(200) NOT NULL,
  `content` text NOT NULL,
  `sort_order` int(10) unsigned DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `category_id` (`category_id`),
  CONSTRAINT `FK_sop_sections_category` FOREIGN KEY (`category_id`) REFERENCES `mdt_sop_categories` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_sop_settings`
DROP TABLE IF EXISTS `mdt_sop_settings`;
CREATE TABLE `mdt_sop_settings` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job` varchar(50) NOT NULL,
  `mission_statement` text DEFAULT NULL,
  `introduction` text DEFAULT NULL,
  `version` int(10) unsigned DEFAULT 0,
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `job` (`job`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_tags`
DROP TABLE IF EXISTS `mdt_tags`;
CREATE TABLE `mdt_tags` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(25) NOT NULL,
  `type` enum('report','officer','citizen') NOT NULL DEFAULT 'citizen',
  `color` varchar(7) NOT NULL DEFAULT '#6b7280',
  `job_type` varchar(10) NOT NULL DEFAULT 'all',
  `description` varchar(120) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_tag_name_job` (`name`,`job_type`)
) ENGINE=InnoDB AUTO_INCREMENT=52 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_warrant_requests`
DROP TABLE IF EXISTS `mdt_warrant_requests`;
CREATE TABLE `mdt_warrant_requests` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `citizen_name` varchar(100) NOT NULL DEFAULT '',
  `requesting_officer` varchar(50) NOT NULL,
  `officer_name` varchar(100) NOT NULL DEFAULT '',
  `charges` text DEFAULT NULL,
  `reason` text NOT NULL,
  `linked_report_id` int(10) unsigned DEFAULT NULL,
  `status` enum('pending','approved','denied','closed') NOT NULL DEFAULT 'pending',
  `reviewer_citizenid` varchar(50) DEFAULT NULL,
  `reviewer_name` varchar(100) DEFAULT NULL,
  `review_reason` text DEFAULT NULL,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_citizenid` (`citizenid`),
  KEY `idx_status` (`status`),
  KEY `idx_requesting_officer` (`requesting_officer`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_warrant_reviews`
DROP TABLE IF EXISTS `mdt_warrant_reviews`;
CREATE TABLE `mdt_warrant_reviews` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `warrant_request_id` int(10) unsigned NOT NULL,
  `reviewer_citizenid` varchar(50) NOT NULL,
  `reviewer_name` varchar(100) DEFAULT NULL,
  `decision` enum('approved','denied') NOT NULL,
  `reason` text DEFAULT NULL,
  `reviewed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_warrant_request` (`warrant_request_id`),
  KEY `idx_reviewer` (`reviewer_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_weapon_ownership_history`
DROP TABLE IF EXISTS `mdt_weapon_ownership_history`;
CREATE TABLE `mdt_weapon_ownership_history` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `serial` varchar(50) NOT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `weapon_model` varchar(50) DEFAULT NULL,
  `weapon_class` varchar(50) DEFAULT NULL,
  `information` text DEFAULT NULL,
  `changed_by` varchar(50) DEFAULT NULL,
  `reason` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_mdt_weapon_history_serial` (`serial`),
  KEY `idx_mdt_weapon_history_owner` (`owner`),
  CONSTRAINT `FK_mdt_weapon_history_weapons` FOREIGN KEY (`serial`) REFERENCES `mdt_weapons` (`serial`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `mdt_weapons`
DROP TABLE IF EXISTS `mdt_weapons`;
CREATE TABLE `mdt_weapons` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `serial` varchar(50) NOT NULL DEFAULT '',
  `scratched` tinyint(1) NOT NULL DEFAULT 0,
  `owner` varchar(50) DEFAULT NULL,
  `information` text DEFAULT NULL,
  `weaponClass` varchar(50) DEFAULT NULL,
  `weaponModel` varchar(50) DEFAULT NULL,
  `flags` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`flags`)),
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_serial` (`serial`),
  KEY `FK_mdt_weapons_mdt_profiles` (`owner`),
  CONSTRAINT `FK_mdt_weapons_mdt_profiles` FOREIGN KEY (`owner`) REFERENCES `mdt_profiles` (`citizenid`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=MyISAM AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

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
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

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
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Structure for `npwd_messages_participants`
DROP TABLE IF EXISTS `npwd_messages_participants`;
CREATE TABLE `npwd_messages_participants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `conversation_id` int(11) NOT NULL,
  `participant` varchar(225) CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci NOT NULL,
  `unread_count` int(11) DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `message_participants_npwd_messages_conversations_id_fk` (`conversation_id`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

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
) ENGINE=MyISAM AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=93 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `ox_inventory`
DROP TABLE IF EXISTS `ox_inventory`;
CREATE TABLE `ox_inventory` (
  `owner` varchar(60) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `data` longtext DEFAULT NULL,
  `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  UNIQUE KEY `owner` (`owner`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `player_transactions`
DROP TABLE IF EXISTS `player_transactions`;
CREATE TABLE `player_transactions` (
  `id` varchar(50) NOT NULL,
  `isFrozen` int(11) DEFAULT 0,
  `transactions` longtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
  `mdt_vehicle_information` text DEFAULT NULL,
  `mdt_vehicle_points` int(11) NOT NULL DEFAULT 0,
  `mdt_vehicle_status` varchar(500) NOT NULL DEFAULT 'valid',
  `mdt_vehicle_stolen` tinyint(1) NOT NULL DEFAULT 0,
  `mdt_vehicle_boloactive` tinyint(1) NOT NULL DEFAULT 0,
  `mdt_vehicle_image` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate` (`plate`),
  UNIQUE KEY `UK_playervehicles_plate` (`plate`),
  KEY `FK_playervehicles_players` (`citizenid`),
  CONSTRAINT `FK_playervehicles_players` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `player_vehicles_ibfk_1` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=91 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=8687 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=52 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
  `garage` longtext NOT NULL,
  `reason` varchar(100) DEFAULT NULL,
  `deformation` longtext DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `bank_invoice_id` varchar(120) DEFAULT NULL
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
) ENGINE=InnoDB AUTO_INCREMENT=164 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci COMMENT='Configurações individuais das chaves de veículo';

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
  `category` varchar(20) DEFAULT NULL,
  `sold_at` bigint(20) DEFAULT NULL,
  `purchase_price` bigint(20) DEFAULT NULL,
  `enterprise_id` int(11) DEFAULT NULL,
  `unit_number` varchar(32) DEFAULT NULL,
  `unit_floor` int(11) DEFAULT NULL,
  `hourly_rate` bigint(20) DEFAULT NULL,
  `daily_rate` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`property_id`),
  UNIQUE KEY `UQ_owner_apartment` (`owner_citizenid`,`apartment`),
  UNIQUE KEY `housing_enterprise_unit` (`enterprise_id`,`unit_number`),
  CONSTRAINT `FK_owner_citizenid` FOREIGN KEY (`owner_citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `housing_enterprise_fk` FOREIGN KEY (`enterprise_id`) REFERENCES `housing_enterprises` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- Structure for `ps_dispatch_settings`
DROP TABLE IF EXISTS `ps_dispatch_settings`;
CREATE TABLE `ps_dispatch_settings` (
  `id` tinyint(3) unsigned NOT NULL,
  `settings` longtext NOT NULL,
  `updated_by` varchar(64) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- Structure for `qbx_character_slot_blocks`
DROP TABLE IF EXISTS `qbx_character_slot_blocks`;
CREATE TABLE `qbx_character_slot_blocks` (
  `user_id` int(10) unsigned NOT NULL,
  `slot_id` tinyint(3) unsigned NOT NULL,
  `blocked_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`user_id`,`slot_id`),
  KEY `idx_qbx_character_slot_blocks_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `qbx_character_slot_settings`
DROP TABLE IF EXISTS `qbx_character_slot_settings`;
CREATE TABLE `qbx_character_slot_settings` (
  `id` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `settings` longtext NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `qbx_character_slots`
DROP TABLE IF EXISTS `qbx_character_slots`;
CREATE TABLE `qbx_character_slots` (
  `user_id` int(10) unsigned NOT NULL,
  `slot_id` tinyint(3) unsigned NOT NULL,
  `acquired_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`user_id`,`slot_id`),
  KEY `idx_qbx_character_slots_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `qbx_character_terms_acceptance`
DROP TABLE IF EXISTS `qbx_character_terms_acceptance`;
CREATE TABLE `qbx_character_terms_acceptance` (
  `user_id` int(10) unsigned NOT NULL,
  `terms_version` varchar(40) NOT NULL,
  `accepted_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`user_id`,`terms_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- Structure for `renewed_account_members`
DROP TABLE IF EXISTS `renewed_account_members`;
CREATE TABLE `renewed_account_members` (
  `account_id` varchar(60) NOT NULL,
  `member_cid` varchar(60) NOT NULL,
  `member_name` varchar(120) NOT NULL,
  `can_withdraw` tinyint(1) NOT NULL DEFAULT 0,
  `can_transfer` tinyint(1) NOT NULL DEFAULT 0,
  `can_pay_invoices` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` bigint(20) NOT NULL,
  `updated_at` bigint(20) NOT NULL,
  PRIMARY KEY (`account_id`,`member_cid`),
  KEY `idx_renewed_member` (`member_cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `renewed_invoice_settings`
DROP TABLE IF EXISTS `renewed_invoice_settings`;
CREATE TABLE `renewed_invoice_settings` (
  `id` tinyint(3) unsigned NOT NULL,
  `settings` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `renewed_invoices`
DROP TABLE IF EXISTS `renewed_invoices`;
CREATE TABLE `renewed_invoices` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(120) DEFAULT NULL,
  `recipient` varchar(60) NOT NULL,
  `issuer_resource` varchar(80) NOT NULL,
  `issuer` varchar(120) NOT NULL,
  `receiver_account` varchar(50) DEFAULT NULL,
  `title` varchar(120) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `principal` int(10) unsigned NOT NULL,
  `interest_rate` decimal(8,4) NOT NULL DEFAULT 0.0000,
  `interest_interval` enum('hour','day') NOT NULL DEFAULT 'day',
  `due_at` bigint(20) NOT NULL,
  `status` enum('active','processing','paid','cancelled') NOT NULL DEFAULT 'active',
  `metadata` longtext DEFAULT NULL,
  `created_at` bigint(20) NOT NULL,
  `paid_at` bigint(20) DEFAULT NULL,
  `paid_amount` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_invoice_external` (`issuer_resource`,`external_id`),
  KEY `idx_invoice_recipient_status` (`recipient`,`status`),
  KEY `idx_invoice_due` (`due_at`)
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- Structure for `xt_prison`
DROP TABLE IF EXISTS `xt_prison`;
CREATE TABLE `xt_prison` (
  `identifier` varchar(100) NOT NULL,
  `jailtime` int(11) NOT NULL DEFAULT 0,
  `sentence` longtext DEFAULT NULL,
  PRIMARY KEY (`identifier`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `xt_prison_items`
DROP TABLE IF EXISTS `xt_prison_items`;
CREATE TABLE `xt_prison_items` (
  `owner` varchar(60) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `data` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  UNIQUE KEY `owner` (`owner`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Structure for `xt_prison_settings`
DROP TABLE IF EXISTS `xt_prison_settings`;
CREATE TABLE `xt_prison_settings` (
  `id` varchar(50) NOT NULL,
  `data` longtext NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS=1;
