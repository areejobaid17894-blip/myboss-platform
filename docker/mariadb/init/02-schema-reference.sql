-- Unified schema (MariaDB 11) — single database `myboss` for all services.
-- TypeORM synchronize creates these when DB_ENABLED=true and DB_SYNCHRONIZE=true.
-- Real FK constraints enforce referential integrity (no duplicate cross-service copies).

USE myboss;

-- ── Reference data ───────────────────────────────────────────────────────────

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

-- ── Users (auth eligibility + employee profile — single source of truth) ─────

CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  first_name VARCHAR(120) NOT NULL,
  last_name VARCHAR(120) NOT NULL,
  role VARCHAR(32) NOT NULL DEFAULT 'employee',
  invited_at DATETIME NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  onboarding_completed TINYINT(1) NOT NULL DEFAULT 0,
  terms_accepted_at DATETIME NULL,
  vest_size VARCHAR(16) NULL,
  building_id VARCHAR(36) NULL,
  open_to_travel TINYINT(1) NOT NULL DEFAULT 0,
  preferred_governorates JSON NULL,
  profile_edit_count SMALLINT NOT NULL DEFAULT 0,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_building (building_id),
  KEY idx_users_role (role),
  CONSTRAINT fk_users_building
    FOREIGN KEY (building_id) REFERENCES buildings (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS otp_sessions (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL,
  code_hash VARCHAR(255) NOT NULL,
  expires_at DATETIME NOT NULL,
  attempts SMALLINT NOT NULL DEFAULT 0,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY idx_otp_sessions_user (user_id),
  CONSTRAINT fk_otp_sessions_user
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS device_tokens (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  employee_id VARCHAR(36) NOT NULL,
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
  KEY idx_device_tokens_active (employee_id, revoked_at),
  CONSTRAINT fk_device_tokens_user
    FOREIGN KEY (employee_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Squads (membership is authoritative; no name/building snapshots) ─────────

CREATE TABLE IF NOT EXISTS squads (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  squad_code VARCHAR(16) NOT NULL,
  name VARCHAR(255) NOT NULL,
  badge VARCHAR(32) NOT NULL,
  governorate VARCHAR(120) NOT NULL,
  leader_id VARCHAR(36) NOT NULL,
  survey_target INT NOT NULL DEFAULT 50,
  destination VARCHAR(255) NULL,
  destination_validated TINYINT(1) NOT NULL DEFAULT 0,
  locked_at DATETIME NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY uq_squads_code (squad_code),
  UNIQUE KEY uq_squads_name (name),
  KEY idx_squads_leader (leader_id),
  KEY idx_squads_governorate (governorate),
  CONSTRAINT fk_squads_leader
    FOREIGN KEY (leader_id) REFERENCES users (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS squad_members (
  squad_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  role ENUM('leader', 'member') NOT NULL,
  PRIMARY KEY (squad_id, user_id),
  KEY idx_squad_members_user (user_id),
  CONSTRAINT fk_squad_members_squad
    FOREIGN KEY (squad_id) REFERENCES squads (id) ON DELETE CASCADE,
  CONSTRAINT fk_squad_members_user
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS squad_join_requests (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  squad_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  status ENUM('pending', 'accepted', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY idx_join_requests_squad (squad_id),
  KEY idx_join_requests_user (user_id),
  KEY idx_join_requests_status (status),
  CONSTRAINT fk_join_requests_squad
    FOREIGN KEY (squad_id) REFERENCES squads (id) ON DELETE CASCADE,
  CONSTRAINT fk_join_requests_user
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Surveys & gallery ────────────────────────────────────────────────────────

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
  answers JSON NOT NULL,
  anonymous TINYINT(1) NOT NULL DEFAULT 0,
  submitted_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY idx_responses_survey (survey_id),
  KEY idx_responses_squad (squad_id),
  KEY idx_responses_user (user_id),
  CONSTRAINT fk_responses_survey
    FOREIGN KEY (survey_id) REFERENCES surveys (id) ON DELETE CASCADE,
  CONSTRAINT fk_responses_squad
    FOREIGN KEY (squad_id) REFERENCES squads (id) ON DELETE CASCADE,
  CONSTRAINT fk_responses_user
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
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
  KEY idx_gallery_source (source),
  KEY idx_gallery_notification (notification_id),
  CONSTRAINT fk_gallery_user
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_gallery_squad
    FOREIGN KEY (squad_id) REFERENCES squads (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Chat (config-service) ────────────────────────────────────────────────────

INSERT IGNORE INTO users (
  id, email, first_name, last_name, role, is_active, onboarding_completed, open_to_travel, profile_edit_count
) VALUES (
  'support', 'support@orange.com', 'Support', 'Team', 'employee', 1, 1, 0, 0
);

CREATE TABLE IF NOT EXISTS chat_messages (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  conversation_id VARCHAR(80) NOT NULL,
  sender_id VARCHAR(36) NOT NULL,
  recipient_id VARCHAR(36) NOT NULL,
  text VARCHAR(2000) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY idx_chat_conversation (conversation_id, created_at),
  KEY idx_chat_sender (sender_id),
  KEY idx_chat_recipient (recipient_id),
  CONSTRAINT fk_chat_sender
    FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_chat_recipient
    FOREIGN KEY (recipient_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
