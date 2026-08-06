-- Reference schema (MariaDB 11) — one database per microservice.
-- TypeORM synchronize creates these when DB_ENABLED=true and DB_SYNCHRONIZE=true.
-- Cross-service IDs (user_id, squad_id, building_id) are logical FKs only (no cross-DB constraints).

USE myboss_auth;

CREATE TABLE IF NOT EXISTS eligible_participants (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  first_name VARCHAR(120) NOT NULL,
  last_name VARCHAR(120) NOT NULL,
  invited_at DATETIME NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY uq_eligible_participants_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS otp_sessions (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  participant_id VARCHAR(36) NOT NULL,
  code_hash VARCHAR(255) NOT NULL,
  expires_at DATETIME NOT NULL,
  attempts SMALLINT NOT NULL DEFAULT 0,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY idx_otp_sessions_participant (participant_id),
  CONSTRAINT fk_otp_sessions_participant
    FOREIGN KEY (participant_id) REFERENCES eligible_participants (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

USE myboss_user;

CREATE TABLE IF NOT EXISTS user_profiles (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  first_name VARCHAR(120) NOT NULL,
  last_name VARCHAR(120) NOT NULL,
  role VARCHAR(32) NOT NULL DEFAULT 'employee',
  onboarding_completed TINYINT(1) NOT NULL DEFAULT 0,
  terms_accepted_at DATETIME NULL,
  vest_size VARCHAR(16) NULL,
  building_id VARCHAR(36) NULL COMMENT 'logical FK → myboss_config.buildings.id',
  building_name VARCHAR(255) NULL,
  governorate VARCHAR(120) NULL,
  open_to_travel TINYINT(1) NOT NULL DEFAULT 0,
  preferred_governorates JSON NULL,
  squad_id VARCHAR(36) NULL COMMENT 'logical FK → myboss_squad.squads.id',
  profile_edit_count SMALLINT NOT NULL DEFAULT 0,
  UNIQUE KEY uq_user_profiles_email (email),
  KEY idx_user_profiles_squad (squad_id),
  KEY idx_user_profiles_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS device_tokens (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  employee_id VARCHAR(36) NOT NULL COMMENT 'logical FK → user_profiles.id',
  token VARCHAR(512) NOT NULL,
  platform ENUM('android', 'ios') NOT NULL,
  app_version VARCHAR(32) NULL,
  locale VARCHAR(16) NULL,
  timezone VARCHAR(64) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  last_seen_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  revoked_at DATETIME NULL,
  UNIQUE KEY uq_device_tokens_token (token),
  KEY idx_device_tokens_employee (employee_id),
  KEY idx_device_tokens_active (employee_id, revoked_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

USE myboss_config;

CREATE TABLE IF NOT EXISTS buildings (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  governorate VARCHAR(120) NOT NULL,
  address VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS app_config (
  `key` VARCHAR(64) NOT NULL PRIMARY KEY,
  value JSON NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

USE myboss_squad;

CREATE TABLE IF NOT EXISTS squads (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  squad_code VARCHAR(16) NOT NULL,
  name VARCHAR(255) NOT NULL,
  badge VARCHAR(32) NOT NULL,
  governorate VARCHAR(120) NOT NULL,
  leader_id VARCHAR(36) NOT NULL COMMENT 'logical FK → myboss_user.user_profiles.id',
  survey_target INT NOT NULL DEFAULT 50,
  destination VARCHAR(255) NULL,
  destination_validated TINYINT(1) NOT NULL DEFAULT 0,
  locked_at DATETIME NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY uq_squads_code (squad_code),
  UNIQUE KEY uq_squads_name (name),
  KEY idx_squads_leader (leader_id),
  KEY idx_squads_governorate (governorate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS squad_members (
  squad_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  first_name VARCHAR(120) NOT NULL,
  last_name VARCHAR(120) NOT NULL,
  role ENUM('leader', 'member') NOT NULL,
  building VARCHAR(255) NULL,
  open_to_travel TINYINT(1) NULL,
  PRIMARY KEY (squad_id, user_id),
  KEY idx_squad_members_user (user_id),
  CONSTRAINT fk_squad_members_squad
    FOREIGN KEY (squad_id) REFERENCES squads (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS squad_join_requests (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  squad_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  first_name VARCHAR(120) NOT NULL,
  last_name VARCHAR(120) NOT NULL,
  building VARCHAR(255) NULL,
  status ENUM('pending', 'accepted', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY idx_join_requests_squad (squad_id),
  KEY idx_join_requests_user (user_id),
  KEY idx_join_requests_status (status),
  CONSTRAINT fk_join_requests_squad
    FOREIGN KEY (squad_id) REFERENCES squads (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

USE myboss_survey;

CREATE TABLE IF NOT EXISTS surveys (
  id VARCHAR(64) NOT NULL PRIMARY KEY,
  segment VARCHAR(64) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  questions JSON NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  KEY idx_surveys_segment (segment),
  KEY idx_surveys_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS survey_responses (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  survey_id VARCHAR(64) NOT NULL,
  segment VARCHAR(64) NOT NULL,
  squad_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  governorate VARCHAR(120) NOT NULL,
  answers JSON NOT NULL,
  anonymous TINYINT(1) NOT NULL DEFAULT 0,
  submitted_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY idx_responses_survey (survey_id),
  KEY idx_responses_squad (squad_id),
  KEY idx_responses_user (user_id),
  CONSTRAINT fk_responses_survey
    FOREIGN KEY (survey_id) REFERENCES surveys (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notifications (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  audience VARCHAR(64) NOT NULL,
  gallery_item_id VARCHAR(36) NOT NULL,
  target_user_ids JSON NULL,
  read_by JSON NOT NULL,
  payload_version VARCHAR(8) NULL,
  pointer_type VARCHAR(64) NULL,
  entity_id VARCHAR(36) NULL,
  route VARCHAR(128) NULL,
  sent_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY uq_notifications_gallery (gallery_item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS gallery_items (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL,
  squad_id VARCHAR(36) NOT NULL,
  governorate VARCHAR(120) NOT NULL,
  type ENUM('image', 'video', 'announcement') NOT NULL,
  source ENUM('employee', 'admin') NOT NULL,
  url TEXT NOT NULL,
  caption TEXT NULL,
  title VARCHAR(255) NULL,
  audience VARCHAR(64) NULL,
  notification_id VARCHAR(36) NULL,
  route VARCHAR(128) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY idx_gallery_squad (squad_id),
  KEY idx_gallery_governorate (governorate),
  KEY idx_gallery_source (source),
  KEY idx_gallery_notification (notification_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
