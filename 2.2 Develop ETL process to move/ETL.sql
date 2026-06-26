CREATE EXTENSION IF NOT EXISTS postgres_fdw;

CREATE SERVER IF NOT EXISTS oltp_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'expense_tracker_oltp', port '5432');

CREATE USER MAPPING IF NOT EXISTS FOR current_user
SERVER oltp_server
OPTIONS (user 'postgres', password 'jeny2001');

DROP SCHEMA IF EXISTS staging CASCADE;

CREATE SCHEMA staging;

IMPORT FOREIGN SCHEMA public FROM SERVER oltp_server INTO staging;

------------------------------------

INSERT INTO Dim_Currency (currency_code, currency_name)
SELECT currency_code, currency_name 
FROM staging.currencies
ON CONFLICT (currency_code) DO NOTHING;

INSERT INTO Dim_Category (category_name, is_income)
SELECT category_name, is_income 
FROM staging.categories
ON CONFLICT (category_name) DO NOTHING;

INSERT INTO Dim_Subcategory (subcategory_name, category_sk)
SELECT 
    s.subcategory_name,
    c.category_sk
FROM staging.subcategories s
JOIN Dim_Category c ON c.category_name = s.category_name
ON CONFLICT (subcategory_name) DO NOTHING;

INSERT INTO Dim_Account (account_name, currency_sk)
SELECT 
    a.account_name,
    c.currency_sk
FROM staging.accounts a
JOIN Dim_Currency c ON c.currency_code = a.currency_code
ON CONFLICT (account_name) DO NOTHING;


-- ==========================================
-- 		(SCD Type 2 для Пользователей)
-- ==========================================
-- Если у юзера изменилось имя/фамилия, мы закрываем старую запись и открываем новую.
-- Если юзер новый, просто добавляем.

UPDATE Dim_User du
SET valid_to = CURRENT_DATE, is_current = FALSE
FROM staging.users su
WHERE du.email = su.email 
  AND du.is_current = TRUE
  AND (du.first_name <> su.first_name OR du.last_name <> su.last_name);

INSERT INTO Dim_User (email, first_name, last_name, valid_from, is_current)
SELECT 
    su.email, 
    su.first_name, 
    su.last_name, 
    CURRENT_DATE, 
    TRUE
FROM staging.users su
WHERE NOT EXISTS (
    SELECT 1 FROM Dim_User du 
    WHERE du.email = su.email AND du.is_current = TRUE
);

-- ==========================================
-- LOAD DIMENSIONS (Генерация Дат)
-- ==========================================

INSERT INTO Dim_Date (date_sk, full_date, month, quarter, year)
SELECT DISTINCT
    CAST(TO_CHAR(transaction_timestamp, 'YYYYMMDD') AS INT) AS date_sk,
    DATE(transaction_timestamp) AS full_date,
    EXTRACT(MONTH FROM transaction_timestamp) AS month,
    EXTRACT(QUARTER FROM transaction_timestamp) AS quarter,
    EXTRACT(YEAR FROM transaction_timestamp) AS year
FROM staging.transactions
ON CONFLICT (date_sk) DO NOTHING;

INSERT INTO Dim_Date (date_sk, full_date, month, quarter, year)
SELECT DISTINCT
    CAST(TO_CHAR(rate_date, 'YYYYMMDD') AS INT) AS date_sk,
    rate_date AS full_date,
    EXTRACT(MONTH FROM rate_date) AS month,
    EXTRACT(QUARTER FROM rate_date) AS quarter,
    EXTRACT(YEAR FROM rate_date) AS year
FROM staging.exchange_rates
ON CONFLICT (date_sk) DO NOTHING;

-- ==========================================
-- LOAD FACTS (Агрегация и Трансформация)
-- ==========================================

INSERT INTO Fact_Daily_Transactions (date_sk, user_sk, account_sk, subcategory_sk, total_amount, transaction_count)
SELECT 
    CAST(TO_CHAR(t.transaction_timestamp, 'YYYYMMDD') AS INT) AS date_sk,
    u.user_sk,
    a.account_sk,
    s.subcategory_sk,
    SUM(t.amount) AS total_amount,                   
    COUNT(t.transaction_timestamp) AS transaction_count
FROM staging.transactions t
JOIN Dim_User u ON u.email = t.user_email AND u.is_current = TRUE
JOIN Dim_Account a ON a.account_name = t.account_name
JOIN Dim_Subcategory s ON s.subcategory_name = t.subcategory_name
GROUP BY 
    CAST(TO_CHAR(t.transaction_timestamp, 'YYYYMMDD') AS INT),
    u.user_sk,
    a.account_sk,
    s.subcategory_sk
ON CONFLICT (date_sk, user_sk, account_sk, subcategory_sk) DO NOTHING;


INSERT INTO Fact_Daily_Exchange_Rates (date_sk, currency_sk, rate_to_usd)
SELECT 
    CAST(TO_CHAR(er.rate_date, 'YYYYMMDD') AS INT) AS date_sk,
    c.currency_sk,
    er.rate_to_usd
FROM staging.exchange_rates er
JOIN Dim_Currency c ON c.currency_code = er.currency_code
ON CONFLICT (date_sk, currency_sk) DO NOTHING;


select * from public.fact_daily_transactions fdt 