CREATE TABLE `business_cash` (
  `id` int(11) NOT NULL,
  `business_id` varchar(50) NOT NULL,
  `cash_balance` int(11) NOT NULL DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `business_salaries` (
  `id` int(11) NOT NULL,
  `business_id` varchar(50) NOT NULL,
  `grade` int(11) NOT NULL DEFAULT 0,
  `salary` int(11) NOT NULL DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `business_storage_access` (
  `id` int(11) NOT NULL,
  `business_id` varchar(50) NOT NULL,
  `storage_index` int(11) NOT NULL,
  `min_grade` int(11) NOT NULL DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `business_work_time` (
  `id` int(11) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `business_id` varchar(50) NOT NULL,
  `minutes_worked` int(11) DEFAULT 0,
  `last_login` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
