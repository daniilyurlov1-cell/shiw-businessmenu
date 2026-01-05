-- Таблица для настроек доступа к хранилищам
CREATE TABLE IF NOT EXISTS `business_storage_access` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `business_id` VARCHAR(50) NOT NULL,
    `storage_index` INT NOT NULL,
    `min_grade` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_storage` (`business_id`, `storage_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;