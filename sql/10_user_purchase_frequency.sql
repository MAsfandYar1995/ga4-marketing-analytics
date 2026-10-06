/*
GA4 Marketing Analytics Portfolio Project
Dataset: Google Analytics 4 obfuscated sample ecommerce
Analysis window: 2020-11-01 to 2021-01-31
SQL dialect: GoogleSQL (BigQuery)
*/

/*
Purpose:
Create a user-level purchaser table with purchase-session frequency, revenue,
first / last purchase dates and a 1 / 2 / 3+ purchase frequency grouping.

Suggested output table:
ga4_analysis.user_purchase_frequency
*/

WITH base_aggregation AS (

  SELECT
    user_pseudo_id,
    COUNT(unique_session_id) AS purchase_count,
    SUM(session_revenue_usd) AS total_revenue,
    DATE(MIN(session_timestamp)) AS first_purchase_date,
    DATE(MAX(session_timestamp)) AS last_purchase_date
  FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final`
  WHERE purchase_flag = 1
  GROUP BY 1

)

SELECT
  *,
  CASE
    WHEN purchase_count = 1 THEN '1 Purchase'
    WHEN purchase_count = 2 THEN '2 Purchases'
    WHEN purchase_count >= 3 THEN '3+ Purchases'
  END AS frequency_group
FROM base_aggregation;
