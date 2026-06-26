-- Expense Trend by Year, Quarter, and Month
SELECT 
    dd.year,
    dd.quarter,
    dd.month,
    ABS(SUM(fdt.total_amount)) AS monthly_expenses,
    SUM(fdt.transaction_count) AS total_operations
FROM Fact_Daily_Transactions fdt
JOIN Dim_Date dd ON fdt.date_sk = dd.date_sk
JOIN Dim_Subcategory ds ON fdt.subcategory_sk = ds.subcategory_sk
JOIN Dim_Category dc ON ds.category_sk = dc.category_sk
WHERE dc.is_income = FALSE
GROUP BY 
    dd.year, 
    dd.quarter, 
    dd.month
ORDER BY 
    dd.year DESC, 
    dd.month DESC;

-- Total Expenses in USD using the Latest Available Exchange Rates
WITH RankedRates AS (
    SELECT 
        currency_sk,
        rate_to_usd,
        ROW_NUMBER() OVER(PARTITION BY currency_sk ORDER BY date_sk DESC) as rn
    FROM Fact_Daily_Exchange_Rates
),
LatestRates AS (
    SELECT currency_sk, rate_to_usd
    FROM RankedRates
    WHERE rn = 1
)
SELECT 
    du.first_name,
    du.last_name,
    ABS(SUM(fdt.total_amount * COALESCE(lr.rate_to_usd, 1.000000))) AS total_spent_in_usd
FROM Fact_Daily_Transactions fdt
JOIN Dim_User du ON fdt.user_sk = du.user_sk
JOIN Dim_Account da ON fdt.account_sk = da.account_sk
LEFT JOIN LatestRates lr ON da.currency_sk = lr.currency_sk
JOIN Dim_Subcategory ds ON fdt.subcategory_sk = ds.subcategory_sk
JOIN Dim_Category dc ON ds.category_sk = dc.category_sk
WHERE dc.is_income = FALSE
GROUP BY 
    du.first_name, 
    du.last_name
ORDER BY 
    total_spent_in_usd DESC;

-- Category Expense Breakdown and Percentage of Total per User
WITH UserCategoryExpenses AS (
    SELECT 
        du.first_name,
        du.last_name,
        dc.category_name,
        ABS(SUM(fdt.total_amount)) AS category_spent
    FROM Fact_Daily_Transactions fdt
    JOIN Dim_User du ON fdt.user_sk = du.user_sk
    JOIN Dim_Subcategory ds ON fdt.subcategory_sk = ds.subcategory_sk
    JOIN Dim_Category dc ON ds.category_sk = dc.category_sk
    WHERE dc.is_income = FALSE
    GROUP BY 
        du.first_name, 
        du.last_name, 
        dc.category_name
)
SELECT 
    first_name,
    last_name,
    category_name,
    category_spent,
    SUM(category_spent) OVER(PARTITION BY first_name, last_name) AS user_total_spent,
    ROUND((category_spent / SUM(category_spent) OVER(PARTITION BY first_name, last_name)) * 100, 2) AS pct_of_total
FROM UserCategoryExpenses
ORDER BY 
    first_name, 
    pct_of_total DESC;