-- ============================================================================
-- 01_staging_and_raw_import.sql
-- Project: Online Retail II (PostgreSQL + Power BI)
-- Purpose: Create text staging tables, verify CSV row counts, and combine
--          both worksheets into online_retail_raw without altering raw values.
-- ============================================================================

CREATE TABLE staging_2009_2010 (
    invoice TEXT,
    stock_code TEXT,
    description TEXT,
    quantity_raw TEXT,
    invoice_date_raw TEXT,
    price_raw TEXT,
    customer_id_raw TEXT,
    country TEXT
);

CREATE TABLE staging_2010_2011 (
    LIKE staging_2009_2010 INCLUDING ALL
);

-- Verify imported CSV row counts (Expected: 525,461 and 541,910)
SELECT '2009-2010' AS source_sheet,
       COUNT(*) AS total_rows
FROM staging_2009_2010

UNION ALL

SELECT '2010-2011',
       COUNT(*)
FROM staging_2010_2011;

-- Combine both worksheets into a single raw table
CREATE TABLE online_retail_raw (
    raw_row_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_sheet TEXT NOT NULL,
    invoice TEXT,
    stock_code TEXT,
    description TEXT,
    quantity_raw TEXT,
    invoice_date_raw TEXT,
    price_raw TEXT,
    customer_id_raw TEXT,
    country TEXT
);

INSERT INTO online_retail_raw (
    source_sheet, invoice, stock_code,
    description, quantity_raw,
    invoice_date_raw, price_raw,
    customer_id_raw, country
)
SELECT
    '2009-2010', invoice, stock_code,
    description, quantity_raw,
    invoice_date_raw, price_raw,
    customer_id_raw, country
FROM staging_2009_2010;

INSERT INTO online_retail_raw (
    source_sheet, invoice, stock_code,
    description, quantity_raw,
    invoice_date_raw, price_raw,
    customer_id_raw, country
)
SELECT
    '2010-2011', invoice, stock_code,
    description, quantity_raw,
    invoice_date_raw, price_raw,
    customer_id_raw, country
FROM staging_2010_2011;

-- Verify combined total (Expected: 1,067,371)
SELECT COUNT(*) AS total_raw_rows
FROM online_retail_raw;