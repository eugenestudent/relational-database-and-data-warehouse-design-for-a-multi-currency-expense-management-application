-- 1. Справочник валют
CREATE TABLE Currencies (
    currency_code CHAR(3) PRIMARY KEY,
    currency_name VARCHAR(50) NOT NULL
);

-- 2. Пользователи
CREATE TABLE Users (
    email VARCHAR(100) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50),
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- 3. Категории транзакций
CREATE TABLE Categories (
    category_name VARCHAR(50) PRIMARY KEY, 
    is_income BOOLEAN NOT NULL DEFAULT FALSE
);

-- 4. Подкатегории транзакций
CREATE TABLE Subcategories (
    category_name VARCHAR(50) REFERENCES Categories(category_name),
    subcategory_name VARCHAR(50),
    PRIMARY KEY (category_name, subcategory_name)
);

-- 5. Места (Магазины, сервисы, работодатели)
CREATE TABLE Payees (
    payee_name VARCHAR(100) PRIMARY KEY,
    description TEXT
);

-- 6. Счета 
CREATE TABLE Accounts (
    user_email VARCHAR(100) REFERENCES Users(email),
    account_name VARCHAR(50),
    currency_code CHAR(3) REFERENCES Currencies(currency_code),
    balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (user_email, account_name)
);

-- 7. Курсы валют
CREATE TABLE Exchange_Rates (
    currency_code CHAR(3) REFERENCES Currencies(currency_code),
    rate_date DATE NOT NULL,
    rate_to_usd NUMERIC(15, 6) NOT NULL,
    PRIMARY KEY (currency_code, rate_date) 
);

-- 8. Транзакции
CREATE TABLE Transactions (
    user_email VARCHAR(100),
    account_name VARCHAR(50),
    transaction_timestamp TIMESTAMP NOT NULL,
    category_name VARCHAR(50),
    subcategory_name VARCHAR(50),
    payee_name VARCHAR(100) REFERENCES Payees(payee_name),
    amount NUMERIC(15, 2) NOT NULL, -- Положительное значение для дохода, отрицательное для расхода
    description TEXT,
    
    -- Составной первичный ключ
    PRIMARY KEY (user_email, account_name, transaction_timestamp),
    
    -- Внешние ключи
    FOREIGN KEY (user_email, account_name) REFERENCES Accounts(user_email, account_name),
    FOREIGN KEY (category_name, subcategory_name) REFERENCES Subcategories(category_name, subcategory_name)
);