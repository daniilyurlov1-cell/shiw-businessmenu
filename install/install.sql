-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1
-- Время создания: Янв 05 2026 г., 23:43
-- Версия сервера: 10.4.32-MariaDB
-- Версия PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `rexshackredmbuild_319a63`
--

-- --------------------------------------------------------

--
-- Структура таблицы `business_cash`
--

CREATE TABLE `business_cash` (
  `id` int(11) NOT NULL,
  `business_id` varchar(50) NOT NULL,
  `cash_balance` int(11) NOT NULL DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `business_cash`
--

INSERT INTO `business_cash` (`id`, `business_id`, `cash_balance`, `updated_at`) VALUES
(1, 'valsaloon', 4460, '2025-12-29 23:06:52'),
(5, 'blasaloon', 0, '2025-12-12 12:40:34'),
(6, 'valblacksmith', 0, '2025-12-12 14:13:16'),
(7, 'macfarranch', 0, '2025-12-14 22:25:39');

-- --------------------------------------------------------

--
-- Структура таблицы `business_salaries`
--

CREATE TABLE `business_salaries` (
  `id` int(11) NOT NULL,
  `business_id` varchar(50) NOT NULL,
  `grade` int(11) NOT NULL DEFAULT 0,
  `salary` int(11) NOT NULL DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `business_salaries`
--

INSERT INTO `business_salaries` (`id`, `business_id`, `grade`, `salary`, `updated_at`) VALUES
(1, 'valsaloon', 0, 0, '2026-01-05 13:43:07'),
(2, 'valsaloon', 1, 0, '2026-01-05 13:43:11'),
(3, 'valsaloon', 2, 0, '2025-12-29 22:36:33'),
(8, 'annesburgminer', 0, 5, '2025-12-30 00:06:40'),
(9, 'annesburgminer', 1, 10, '2025-12-30 00:06:43'),
(10, 'annesburgminer', 2, 25, '2025-12-30 00:06:46');

-- --------------------------------------------------------

--
-- Структура таблицы `business_storage_access`
--

CREATE TABLE `business_storage_access` (
  `id` int(11) NOT NULL,
  `business_id` varchar(50) NOT NULL,
  `storage_index` int(11) NOT NULL,
  `min_grade` int(11) NOT NULL DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `business_work_time`
--

CREATE TABLE `business_work_time` (
  `id` int(11) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `business_id` varchar(50) NOT NULL,
  `minutes_worked` int(11) DEFAULT 0,
  `last_login` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `business_work_time`
--

INSERT INTO `business_work_time` (`id`, `citizenid`, `business_id`, `minutes_worked`, `last_login`, `updated_at`) VALUES
(1, 'NFJ75520', 'valsaloon', 36, '2025-12-29 22:07:31', '2025-12-29 23:49:55'),
(2, 'MEG20356', 'valsaloon', 221, '2025-12-29 22:09:01', '2025-12-30 19:59:51'),
(3, 'NFJ75520', 'annesburgminer', 31, '2025-12-30 00:00:11', '2025-12-30 11:33:43'),
(4, 'MEG20356', 'annesburgminer', 100, '2025-12-30 00:08:12', '2025-12-30 01:51:07'),
(5, 'ZTD31330', 'valsaloon', 90, '2026-01-05 13:41:43', '2026-01-05 17:06:34'),
(6, 'POO60114', 'newspaper', 67, '2026-01-05 21:22:56', '2026-01-05 22:30:40');

-- --------------------------------------------------------

--
-- Структура таблицы `player_businesses`
--

CREATE TABLE `player_businesses` (
  `id` int(11) NOT NULL,
  `business_id` varchar(50) NOT NULL,
  `owner_citizenid` varchar(50) DEFAULT NULL,
  `owner_name` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `purchase_price` int(11) NOT NULL DEFAULT 0,
  `purchase_date` timestamp NULL DEFAULT current_timestamp(),
  `next_rent` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `player_businesses`
--

INSERT INTO `player_businesses` (`id`, `business_id`, `owner_citizenid`, `owner_name`, `purchase_price`, `purchase_date`, `next_rent`) VALUES
(1, 'blackwater_saloon', NULL, NULL, 75000, '2025-12-10 21:54:27', NULL),
(2, 'valentine_general', NULL, NULL, 30000, '2025-12-10 21:54:27', NULL),
(4, 'strawberry_general', NULL, NULL, 25000, '2025-12-10 21:54:27', NULL),
(5, 'valentine_stable', NULL, NULL, 40000, '2025-12-10 21:54:27', NULL),
(6, 'valblacksmith', NULL, NULL, 50, '2025-12-14 23:50:28', NULL),
(8, 'valsaloon', 'ZTD31330', 'Тесса Риверс', 3200, '2026-01-05 13:41:43', '2026-01-12 13:41:43'),
(9, 'pronghornranch', NULL, NULL, 50, '2025-12-14 22:03:52', NULL),
(10, 'macfarranch', NULL, NULL, 75, '2025-12-13 02:18:03', NULL),
(11, 'hangingdogranch', NULL, NULL, 75, '2025-12-14 22:02:41', NULL),
(12, 'hillhavenranch', NULL, NULL, 50, '2025-12-13 01:14:19', NULL),
(13, 'emeraldranch', NULL, NULL, 75, '2025-12-13 01:14:19', NULL),
(14, 'downesranch', NULL, NULL, 75, '2025-12-13 01:14:19', NULL),
(15, 'annesburgminer', NULL, NULL, 0, '2025-12-30 00:00:11', NULL),
(16, 'valmedic', NULL, NULL, 0, '2025-12-31 08:00:51', NULL);

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `business_cash`
--
ALTER TABLE `business_cash`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_business` (`business_id`);

--
-- Индексы таблицы `business_salaries`
--
ALTER TABLE `business_salaries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_business_grade` (`business_id`,`grade`);

--
-- Индексы таблицы `business_storage_access`
--
ALTER TABLE `business_storage_access`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_storage` (`business_id`,`storage_index`);

--
-- Индексы таблицы `business_work_time`
--
ALTER TABLE `business_work_time`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_citizen_business` (`citizenid`,`business_id`);

--
-- Индексы таблицы `player_businesses`
--
ALTER TABLE `player_businesses`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `business_id` (`business_id`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `business_cash`
--
ALTER TABLE `business_cash`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT для таблицы `business_salaries`
--
ALTER TABLE `business_salaries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT для таблицы `business_storage_access`
--
ALTER TABLE `business_storage_access`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `business_work_time`
--
ALTER TABLE `business_work_time`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT для таблицы `player_businesses`
--
ALTER TABLE `player_businesses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
