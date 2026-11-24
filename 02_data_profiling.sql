-- ============================================================================
-- 02_data_profiling.sql
-- Purpose: Profile online_retail_raw for missing values, cancellations,
--          invalid quantities/prices, worksheet date overlap, non-standard
--          stock codes, and exact duplicates prior to cleaning.
-- ============================================================================

-- 1. Check missing customer IDs and product descriptions
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id_raw IS NULL OR TRIM(customer_id_raw) = '') AS missing_customer_ids,
    COUNT(*) FILTER (WHERE description IS NULL OR TRIM(description) = '') AS missing_descriptions
FROM online_retail_raw;

-- 2. Check cancelled invoices (C-prefixed) and zero/negative quantities or prices
SELECT
    COUNT(*) FILTER (WHERE invoice ILIKE 'C%') AS cancelled_rows,
    COUNT(*) FILTER (WHERE CAST(quantity_raw AS NUMERIC) <= 0) AS zero_or_neg_qty,
    COUNT(*) FILTER (WHERE CAST(price_raw AS NUMERIC) <= 0) AS zero_or_neg_price
FROM online_retail_raw;

-- 3. Check December 2010 date overlap between worksheets
SELECT
    source_sheet,
    MIN(CAST(invoice_date_raw AS TIMESTAMP)) AS min_date,
    MAX(CAST(invoice_date_raw AS TIMESTAMP)) AS max_date,
    COUNT(*) FILTER (
        WHERE CAST(invoice_date_raw AS TIMESTAMP) >= '2010-12-01'
          AND CAST(invoice_date_raw AS TIMESTAMP) < '2011-01-01'
    ) AS dec_2010_rows
FROM online_retail_raw
GROUP BY source_sheet
ORDER BY source_sheet;

-- 4. Inspect non-standard stock codes (postage, fees, adjustments, tests)
SELECT
    stock_code,
    MAX(description) AS sample_description,
    COUNT(*) AS row_count
FROM online_retail_raw
WHERE stock_code !~ '^[0-9]{5}[A-Za-z]*$'
GROUP BY stock_code
ORDER BY row_count DESC;

-- 5. Count exact duplicate rows across all 8 data columns
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (
        invoice, stock_code, description, quantity_raw,
        invoice_date_raw, price_raw, customer_id_raw, country
    )) AS unique_content_rows,
    COUNT(*) - COUNT(DISTINCT (
        invoice, stock_code, description, quantity_raw,
        invoice_date_raw, price_raw, customer_id_raw, country
    )) AS exact_duplicate_rows
FROM online_retail_raw;