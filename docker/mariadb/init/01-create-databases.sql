-- MariaDB init — one database per microservice (see docs/database/DATABASE.md)

CREATE DATABASE IF NOT EXISTS myboss_auth CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS myboss_user CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS myboss_config CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS myboss_squad CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS myboss_survey CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON myboss_auth.* TO 'myboss'@'%';
GRANT ALL PRIVILEGES ON myboss_user.* TO 'myboss'@'%';
GRANT ALL PRIVILEGES ON myboss_config.* TO 'myboss'@'%';
GRANT ALL PRIVILEGES ON myboss_squad.* TO 'myboss'@'%';
GRANT ALL PRIVILEGES ON myboss_survey.* TO 'myboss'@'%';
FLUSH PRIVILEGES;
