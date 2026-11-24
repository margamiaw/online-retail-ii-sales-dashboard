-- ============================================================================
-- 04_analysis_queries.sql
-- Project: Online Retail II (PostgreSQL + Power BI)
-- Purpose: Calculate headline KPIs, monthly MoM trends, country revenue,
--          top 10 products, day-of-week performance, and hourly demand.
-- ============================================================================

-- Query 1: Headline Business KPIs
SELECT
    ROUND(SUM(line_sales), 2) AS total_sales_gbp,
    COUNT(DISTINCT invoice) AS total_orders,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(line_sales) / NULLIF(COUNT(DISTINCT invoice), 0), 2) AS average_order_value_gbp
FROM fact_sales;

-- Query 2: Monthly Revenue & Month-over-Month Growth (%)
WITH monthly_sales AS (
    SELECT
        d.year_month,
        COUNT(DISTINCT f.invoice) AS monthly_orders,
        ROUND(SUM(f.line_sales), 2) AS monthly_sales_gbp
    FROM fact_sales f
    JOIN dim_date d ON f.sale_date = d.calendar_date
    GROUP BY d.year_month
)
SELECT
    year_month,
    monthly_orders,
    monthly_sales_gbp,
    ROUND(
        100.0 * (monthly_sales_gbp - LAG(monthly_sales_gbp) OVER (ORDER BY year_month))
        / NULLIF(LAG(monthly_sales_gbp) OVER (ORDER BY year_month), 0),
        2
    ) AS mom_growth_pct
FROM monthly_sales
ORDER BY year_month;

-- Query 3: Top 10 Customer Countries by Revenue
SELECT
    country,
    COUNT(DISTINCT invoice) AS total_orders,
    ROUND(SUM(line_sales), 2) AS total_sales_gbp,
    ROUND(100.0 * SUM(line_sales) / SUM(SUM(line_sales)) OVER (), 2) AS pct_of_total_sales
FROM fact_sales
GROUP BY country
ORDER BY total_sales_gbp DESC
LIMIT 10;

-- Query 4: Top 10 Best-Selling Products
SELECT
    p.stock_code,
    p.product_name,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.line_sales), 2) AS total_sales_gbp
FROM fact_sales f
JOIN dim_product p ON f.stock_code = p.stock_code
GROUP BY p.stock_code, p.product_name
ORDER BY total_sales_gbp DESC
LIMIT 10;

-- Query 5: Performance by Day of Week
SELECT
    d.weekday_num,
    d.weekday,
    d.day_type,
    COUNT(DISTINCT f.invoice) AS total_orders,
    ROUND(SUM(f.line_sales), 2) AS total_sales_gbp
FROM fact_sales f
JOIN dim_date d ON f.sale_date = d.calendar_date
GROUP BY d.weekday_num, d.weekday, d.day_type
ORDER BY d.weekday_num;

-- Query 6: Order Volume and Revenue by Hour of Day
SELECT
    sale_hour,
    COUNT(DISTINCT invoice) AS total_orders,
    ROUND(SUM(line_sales), 2) AS total_sales_gbp
FROM fact_sales
GROUP BY sale_hour
ORDER BY sale_hour;