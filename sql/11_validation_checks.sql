/*
GA4 Marketing Analytics Portfolio Project
Dataset: Google Analytics 4 obfuscated sample ecommerce
Analysis window: 2020-11-01 to 2021-01-31
SQL dialect: GoogleSQL (BigQuery)
*/

/*
Purpose:
Keep targeted validation / anomaly checks separate from the main modelling queries.
These queries were used to validate funnel event ordering, New vs Returning purchase
sessions, and repeat-purchaser counts.
*/

WHEN ga_session_number = 1 THEN 'New'

    WHEN ga_session_number > 1 THEN 'Returning'

  END AS session_group,

  COUNT(\*)

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

WHERE purchase_flag = 1

GROUP By 1;


\-- New 1780 , Returning 3068


\----------------------


\-- Which acquisition channels generate the most revenue, and which generate the most revenue per session?


WITH channel_groups AS (


  SELECT

    channel_group,

    COUNT(\*) AS total_sessions,

    SUM(purchase_flag) AS purchase_sessions,

    SUM(session_revenue_usd) AS total_revenue_usd,

    ROUND(SUM(session_revenue_usd) / COUNT(\*), 2) AS revenue_usd_per_session

  FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

  GROUP BY 1


)


SELECT

  channel_group,

  total_sessions,

  purchase_sessions,

  total_revenue_usd,

  revenue_usd_per_session,

  ROUND(total_revenue_usd \* 100.0 / SUM(total_revenue_usd) OVER (), 2) AS revenue_share_pct,

  ROUND(purchase_sessions \* 100.0 / total_sessions, 2) AS purchase_session_rate,

  ROUND(total_revenue_usd / purchase_sessions, 2) AS avg_revenue_per_purchasing_sessions

FROM channel_groups

ORDER BY total_revenue_usd DESC;


\-- Which specific source / medium combinations drive the strongest ecommerce performance?


SELECT

  session_source,

  session_medium,

  COUNT(\*) AS total_sessions,

  SUM(purchase_flag) AS purchase_sessions,

  ROUND(SUM(purchase_flag) \* 100/ NULLIF(COUNT(\*), 0), 2) AS purchase_session_rate,

  SUM(session_revenue_usd) AS total_revenue_usd,

  ROUND(SUM(session_revenue_usd) / NULLIF(COUNT(\*), 0), 2) AS revenue_usd_per_session,

  ROUND(SUM(session_revenue_usd) / NULLIF(SUM(purchase_flag), 0) , 2) AS average_revenue_usd_per_purchasing_session


FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

WHERE session_source NOT IN ('\<Other>','(data deleted)')

  AND channel_group NOT IN ('Self-referral', 'Unattributed', 'Data Unavailable') -- exclude Unattributed, Self-referral, Data Unavailable

GROUP BY 1, 2

HAVING COUNT(\*) >= 100 -- at least 100 sessions

ORDER BY total_revenue_usd DESC;


\---------------------------------------------------------


\-- What campaign values exist, and how much session volume does each represent?


SELECT

  session_campaign,

  total_sessions,

  ROUND(total_sessions \* 100 / SUM(total_sessions) OVER (), 2) AS session_pct

FROM (


-- Validate purchaser-frequency counts.
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

),
final AS (

  SELECT
    *,
    CASE
      WHEN purchase_count = 1 THEN '1 Purchase'
      WHEN purchase_count = 2 THEN '2 Purchases'
      WHEN purchase_count >= 3 THEN '3+ Purchases'
    END AS frequency_group
  FROM base_aggregation

)

SELECT
  COUNT(*) AS total_purchasers,
  SUM(CASE WHEN frequency_group = '1 Purchase' THEN 1 ELSE 0 END) AS one_purchase,
  SUM(CASE WHEN frequency_group = '2 Purchases' THEN 1 ELSE 0 END) AS two_purchase,
  SUM(CASE WHEN frequency_group = '3+ Purchases' THEN 1 ELSE 0 END) AS three_plus_purchase
FROM final;
