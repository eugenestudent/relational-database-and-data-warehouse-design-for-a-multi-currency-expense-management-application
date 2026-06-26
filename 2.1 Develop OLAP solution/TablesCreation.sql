CREATE TABLE Dim_Category (
    category_sk SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    is_income BOOLEAN
);

CREATE TABLE Dim_Subcategory (
    subcategory_sk SERIAL PRIMARY KEY,
    subcategory_name VARCHAR(50) NOT NULL,
    category_sk INT REFERENCES Dim_Category(category_sk)
);

CREATE TABLE Dim_Date (
    date_sk INT PRIMARY KEY, -- YYYYMMDD
    full_date DATE NOT NULL,
    month INT NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL
);

CREATE TABLE Dim_Currency (
    currency_sk SERIAL PRIMARY KEY,
    currency_code CHAR(3) NOT NULL,
    currency_name VARCHAR(50)
);

-- SCD Type 2 
CREATE TABLE Dim_User (
    user_sk SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    -- Атрибуты SCD Type 2:
    valid_from DATE NOT NULL,
    valid_to DATE,
    is_current BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE Dim_Account (
    account_sk SERIAL PRIMARY KEY,
    account_name VARCHAR(50),
    currency_sk INT REFERENCES Dim_Currency(currency_sk)
);


CREATE TABLE Dim_Household (
    household_sk SERIAL PRIMARY KEY,
    household_name VARCHAR(100)
);

-- Bridge Table
CREATE TABLE Bridge_User_Household (
    user_sk INT REFERENCES Dim_User(user_sk),
    household_sk INT REFERENCES Dim_Household(household_sk),
    PRIMARY KEY (user_sk, household_sk)
);

-- Fact 1
CREATE TABLE Fact_Daily_Transactions (
    date_sk INT REFERENCES Dim_Date(date_sk),
    user_sk INT REFERENCES Dim_User(user_sk),
    account_sk INT REFERENCES Dim_Account(account_sk),
    subcategory_sk INT REFERENCES Dim_Subcategory(subcategory_sk),
    
    total_amount NUMERIC(15, 2) NOT NULL,
    transaction_count INT NOT NULL, 

    PRIMARY KEY (date_sk, user_sk, account_sk, subcategory_sk)
);

-- Fact 2
CREATE TABLE Fact_Daily_Exchange_Rates (
    date_sk INT REFERENCES Dim_Date(date_sk),
    currency_sk INT REFERENCES Dim_Currency(currency_sk),
    
    rate_to_usd NUMERIC(15, 6) NOT NULL,
    
    PRIMARY KEY (date_sk, currency_sk)
);