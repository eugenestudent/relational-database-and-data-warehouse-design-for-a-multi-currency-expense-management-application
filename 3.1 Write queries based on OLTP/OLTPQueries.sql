-- (Income vs Expense) per User
SELECT 
    u.first_name || ' ' || COALESCE(u.last_name, '') AS full_name,
    TO_CHAR(t.transaction_timestamp, 'YYYY-MM') AS transaction_month,
    SUM(CASE WHEN c.is_income = TRUE THEN t.amount ELSE 0 END) AS total_income,
    SUM(CASE WHEN c.is_income = FALSE THEN t.amount ELSE 0 END) AS total_expense,
    SUM(t.amount) AS net_savings
FROM Users u
JOIN Accounts a ON u.email = a.user_email
JOIN Transactions t ON a.user_email = t.user_email AND a.account_name = t.account_name
JOIN Categories c ON t.category_name = c.category_name
GROUP BY 
    u.first_name, 
    u.last_name, 
    TO_CHAR(t.transaction_timestamp, 'YYYY-MM')
ORDER BY 
    transaction_month DESC, 
    total_expense ASC;

-- Top Expenses Breakdown by Category and Subcategory
SELECT 
    t.category_name,
    t.subcategory_name,
    COUNT(t.transaction_timestamp) AS total_transactions,
    ABS(SUM(t.amount)) AS total_spent
FROM Transactions t
JOIN Categories c ON t.category_name = c.category_name
WHERE c.is_income = FALSE
GROUP BY 
    t.category_name, 
    t.subcategory_name
ORDER BY 
    total_spent DESC;

-- Multi-currency Account Balances Converted to USD
WITH LatestRates AS (
    SELECT currency_code, rate_to_usd
    FROM Exchange_Rates
    WHERE rate_date = (SELECT MAX(rate_date) FROM Exchange_Rates)
)
SELECT 
    a.user_email,
    a.account_name,
    a.balance AS original_balance,
    a.currency_code,
    COALESCE(lr.rate_to_usd, 1.000000) AS exchange_rate,
    ROUND(a.balance * COALESCE(lr.rate_to_usd, 1.000000), 2) AS balance_in_usd
FROM Accounts a
LEFT JOIN LatestRates lr ON a.currency_code = lr.currency_code
ORDER BY 
    balance_in_usd DESC;