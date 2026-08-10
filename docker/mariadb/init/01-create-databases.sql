-- MariaDB init — single shared database for all microservices (see docs/database/DATABASE.md)

CREATE DATABASE IF NOT EXISTS myboss CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON myboss.* TO 'myboss'@'%';
FLUSH PRIVILEGES;
