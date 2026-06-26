-- 1. Currencies
CREATE TEMP TABLE tmp_currencies (LIKE Currencies);
COPY tmp_currencies FROM 'C:\1.2 Prepare data to load to your DB\currencies.csv' DELIMITER ';' CSV HEADER;

INSERT INTO Currencies
SELECT * FROM tmp_currencies
ON CONFLICT (currency_code) DO NOTHING;

DROP TABLE tmp_currencies;

-- 2. Users
CREATE TEMP TABLE tmp_users (LIKE Users);
COPY tmp_users FROM 'C:\1.2 Prepare data to load to your DB\users.csv' DELIMITER ';' CSV HEADER;

INSERT INTO Users
SELECT * FROM tmp_users
ON CONFLICT (email) DO NOTHING;

DROP TABLE tmp_users;


-- 3. Categories
CREATE TEMP TABLE tmp_categories (LIKE Categories);
COPY tmp_categories FROM 'C:\1.2 Prepare data to load to your DB\categories.csv' DELIMITER ';' CSV HEADER;

INSERT INTO Categories
SELECT * FROM tmp_categories
ON CONFLICT (category_name) DO NOTHING;

DROP TABLE tmp_categories;


-- 4. Subcategories
CREATE TEMP TABLE tmp_subcategories (LIKE Subcategories);
COPY tmp_subcategories FROM 'C:\1.2 Prepare data to load to your DB\subcategories.csv' DELIMITER ';' CSV HEADER;

INSERT INTO Subcategories
SELECT * FROM tmp_subcategories
ON CONFLICT (category_name, subcategory_name) DO NOTHING;

DROP TABLE tmp_subcategories;


-- 5. Accounts
CREATE TEMP TABLE tmp_accounts (LIKE Accounts);
COPY tmp_accounts FROM 'C:\1.2 Prepare data to load to your DB\accounts.csv' DELIMITER ';' CSV HEADER;

INSERT INTO Accounts
SELECT * FROM tmp_accounts
ON CONFLICT (user_email, account_name) DO NOTHING;

DROP TABLE tmp_accounts;


-- 6. Payees
CREATE TEMP TABLE tmp_payees (LIKE Payees);
COPY tmp_payees FROM 'C:\1.2 Prepare data to load to your DB\payees.csv' DELIMITER ';' CSV HEADER;

INSERT INTO Payees
SELECT * FROM tmp_payees
ON CONFLICT (payee_name) DO NOTHING;

DROP TABLE tmp_payees;


-- 7. Exchange_Rates
CREATE TEMP TABLE tmp_exchange_rates (LIKE Exchange_Rates);
COPY tmp_exchange_rates FROM 'C:\1.2 Prepare data to load to your DB\exchange_rates.csv' DELIMITER ';' CSV HEADER;

INSERT INTO Exchange_Rates
SELECT * FROM tmp_exchange_rates
ON CONFLICT (currency_code, rate_date) DO NOTHING;

DROP TABLE tmp_exchange_rates;


-- 8. Transactions
CREATE TEMP TABLE tmp_transactions (LIKE Transactions);
COPY tmp_transactions FROM 'C:\1.2 Prepare data to load to your DB\transactions.csv' DELIMITER ';' CSV HEADER;

INSERT INTO Transactions
SELECT * FROM tmp_transactions
ON CONFLICT (user_email, account_name, transaction_timestamp) DO NOTHING;

DROP TABLE tmp_transactions;