# Online Retail II — Sales & Transaction Performance Dashboard

An end-to-end **PostgreSQL** and **Power BI** analytics project examining over 1 million raw e-commerce transaction records (Dec 2009 – Dec 2011). Every DAX measure in the executive dashboard was benchmarked and validated against SQL queries before visualization.

## Dashboard Demo



https://github.com/user-attachments/assets/89cec009-d93c-4931-9990-78e75682a860



<!-- Drag and drop your dashboard .mp4 screen recording (or .png screenshot) on the blank line below -->


## Key Business Insights

- **Q4 Holiday Restocking Surge:** Monthly revenue peaks sharply every November, reaching **£1.43M in Nov 2010** and **£1.45M in Nov 2011**, reflecting heavy pre-holiday inventory purchasing.
- **B2B / Wholesale Purchasing Cadence:** Order volume concentrates mid-week on **Thursdays (£4.01M)** and during standard business hours (**10:00 AM – 3:00 PM**), while Saturday revenue drops to **£9.80K**.
- **Geographic Revenue Concentration:** The **United Kingdom** generates **£16.8M (~85.5%)** of total revenue, followed by **EIRE**, the **Netherlands**, **Germany**, and **France**.
- **Core Revenue Drivers:** Hero products including **REGENCY CAKESTAND 3 TIER (£330.59K)**, **WHITE HANGING HEART T-LIGHT HOLDER (£261.17K)**, and **JUMBO BAG RED RETROSPOT (£182.68K)** anchor top-line performance.

## SQL-to-DAX Metric Validation

All headline KPI cards in Power BI were cross-checked against PostgreSQL aggregate queries to ensure zero transformation drift:

| Metric | PostgreSQL Benchmark | Power BI DAX Card | Status |
| :--- | ---: | ---: | :---: |
| **Total Sales** | £19,637,540.32 | **£19.64M** | Verified |
| **Total Orders** | 39,516 | **39,516** | Verified |
| **Total Quantity** | 11,188,242 | **11.19M** | Verified |
| **Average Order Value (AOV)** | £496.95 / £497.10 | **£497.10** | Verified |

## Technical Workflow & Repository Structure

- `01_staging_and_raw_import.sql` — Raw table definitions and CSV ingestion setup in PostgreSQL.
- `02_data_profiling.sql` — Data quality audits checking cancellations, negative quantities, zero prices, and missing customer/product fields.
- `03_clean_and_model.sql` — Star-schema transformation into analytical tables (`fact_sales`, `dim_date`, `dim_product`).
- `04_analysis_queries.sql` — Benchmark SQL queries using CTEs and window functions (`LAG`) for monthly trends, MoM growth, country rankings, top products, and weekday/hourly patterns.
- `online_retail_ii_dashboard.pbix` — Interactive Power BI Desktop report featuring custom DAX measures (`Total Sales`, `Total Orders`, `Total Quantity`, `Average Order Value`, `Previous Month Sales`, `MoM Sales %`) and dynamic `Country` and `Year` slicers.
