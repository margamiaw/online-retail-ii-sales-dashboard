-- ============================================================================
-- 03_clean_and_model.sql
-- Purpose: Build cleaned star-schema analytical tables (fact_sales,
--          dim_product, dim_date) while leaving online_retail_raw untouched.
-- ============================================================================

-- 1. Build fact_sales
DROP TABLE IF EXISTS fact_sales;

CREATE TABLE fact_sales AS
WITH standardized AS (
    SELECT
        raw_row_id,
        TRIM(invoice) AS invoice,
        UPPER(TRIM(stock_code)) AS stock_code,
        NULLIF(TRIM(description), '') AS description,
        CAST(CAST(quantity_raw AS NUMERIC) AS INTEGER) AS quantity,
        CAST(invoice_date_raw AS TIMESTAMP) AS sale_timestamp,
        CAST(invoice_date_raw AS DATE) AS sale_date,
        EXTRACT(HOUR FROM CAST(invoice_date_raw AS TIMESTAMP))::INTEGER AS sale_hour,
        CAST(price_raw AS NUMERIC(12, 4)) AS unit_price,
        NULLIF(TRIM(customer_id_raw), '') AS customer_id,
        TRIM(country) AS country
    FROM online_retail_raw
    WHERE
        -- Resolve December 2010 worksheet overlap
        (
            (source_sheet = '2009-2010' AND CAST(invoice_date_raw AS TIMESTAMP) < '2010-12-01')
            OR
            (source_sheet = '2010-2011' AND CAST(invoice_date_raw AS TIMESTAMP) >= '2010-12-01')
        )
        -- Keep valid positive sales (exclude cancellations & debt adjustments)
        AND TRIM(invoice) NOT ILIKE 'C%'
        AND TRIM(invoice) NOT ILIKE 'A%'
        AND CAST(quantity_raw AS NUMERIC) > 0
        AND CAST(price_raw AS NUMERIC) > 0
        -- Exclude non-merchandise fees, adjustments, and test codes
        AND UPPER(TRIM(stock_code)) NOT IN (
            'POST', 'DOT', 'M', 'C2', 'D', 'S', 'BANK CHARGES',
            'ADJUST', 'ADJUST2', 'AMAZONFEE', 'CRUK', 'B',
            'TEST001', 'TEST002', 'GIFT'
        )
        AND UPPER(TRIM(stock_code)) NOT LIKE 'GIFT_0001_%'
),
deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY invoice, stock_code, quantity, sale_timestamp, unit_price, customer_id, country
            ORDER BY raw_row_id
        ) AS rn
    FROM standardized
)
SELECT
    ROW_NUMBER() OVER (ORDER BY sale_timestamp, invoice, stock_code) AS sales_line_id,
    invoice,
    stock_code,
    sale_date,
    sale_timestamp,
    sale_hour,
    quantity,
    unit_price,
    ROUND(quantity * unit_price, 2) AS line_sales,
    customer_id,
    country
FROM deduplicated
WHERE rn = 1;

-- 2. Build dim_product (one standardized product name per stock_code)
DROP TABLE IF EXISTS dim_product;

CREATE TABLE dim_product AS
WITH product_descriptions AS (
    SELECT
        UPPER(TRIM(stock_code)) AS stock_code,
        TRIM(description) AS product_name,
        COUNT(*) AS usage_count
    FROM online_retail_raw
    WHERE description IS NOT NULL
      AND TRIM(description) <> ''
      AND LOWER(TRIM(description)) NOT IN ('ebay', 'update', 'check', '?', 'damages', 'found')
      AND UPPER(TRIM(stock_code)) IN (SELECT DISTINCT stock_code FROM fact_sales)
    GROUP BY UPPER(TRIM(stock_code)), TRIM(description)
),
ranked_products AS (
    SELECT
        stock_code,
        product_name,
        ROW_NUMBER() OVER (
            PARTITION BY stock_code
            ORDER BY usage_count DESC, LENGTH(product_name) DESC, product_name
        ) AS rn
    FROM product_descriptions
)
SELECT
    fs.stock_code,
    COALESCE(rp.product_name, 'Unknown Product (' || fs.stock_code || ')') AS product_name
FROM (SELECT DISTINCT stock_code FROM fact_sales) fs
LEFT JOIN ranked_products rp
    ON fs.stock_code = rp.stock_code
   AND rp.rn = 1;

ALTER TABLE dim_product ADD PRIMARY KEY (stock_code);

-- 3. Build dim_date (continuous calendar from 2009-12-01 to 2011-12-09)
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date AS
SELECT
    d::DATE AS calendar_date,
    EXTRACT(YEAR FROM d)::INTEGER AS year,
    EXTRACT(MONTH FROM d)::INTEGER AS month_num,
    TO_CHAR(d, 'FMMonth') AS month_name,
    TO_CHAR(d, 'YYYY-MM') AS year_month,
    EXTRACT(DAY FROM d)::INTEGER AS day_of_month,
    EXTRACT(ISODOW FROM d)::INTEGER AS weekday_num,
    TO_CHAR(d, 'FMDay') AS weekday,
    CASE
        WHEN EXTRACT(ISODOW FROM d) IN (6, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type
FROM GENERATE_SERIES('2009-12-01'::DATE, '2011-12-09'::DATE, '1 day'::INTERVAL) AS d;

ALTER TABLE dim_date ADD PRIMARY KEY (calendar_date);

-- 4. Verify star schema row counts
SELECT
    (SELECT COUNT(*) FROM fact_sales) AS fact_sales_rows,
    (SELECT COUNT(DISTINCT stock_code) FROM fact_sales) AS fact_distinct_products,
    (SELECT COUNT(*) FROM dim_product) AS dim_product_rows,
    (SELECT COUNT(*) FROM dim_date) AS dim_date_rows;