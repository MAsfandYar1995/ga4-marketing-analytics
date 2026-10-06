/*
GA4 Marketing Analytics Portfolio Project
Dataset: Google Analytics 4 obfuscated sample ecommerce
Analysis window: 2020-11-01 to 2021-01-31
SQL dialect: GoogleSQL (BigQuery)
*/

/*
Purpose:
Join session acquisition fields to ecommerce performance and derive channel_group.

Expected output table used later in the project:
ga4_analysis.session_marketing_performance
*/

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_acquisition\` sa

LEFT JOIN \`ga4-marketing-analysis-509418.ga4_analysis.session_ecommerce_performance\` se

  ON sa.unique_session_id = se.unique_session_id;


\-- Which acquisition channels bring sessions that progress furthest through the ecommerce funnel and purchase?


SELECT

  channel_group,

  COUNT(\*) AS total_sessions,

  SUM(view_item_flag) AS product_view_sessions,

  SUM(add_to_cart_flag) AS add_to_cart_sessions,

  SUM(begin_checkout_flag) AS checkout_sessions,

  SUM(add_shipping_info_flag) AS shipping_info_sessions,

  SUM(add_payment_info_flag) AS payment_info_sessions,

  SUM(purchase_flag) AS purchase_sessions,

  ROUND(SUM(view_item_flag) \* 100.0 / COUNT(\*), 2) AS product_view_rate,

  ROUND(SUM(add_to_cart_flag) \* 100.0 / COUNT(\*), 2) AS add_to_cart_rate,

  ROUND(SUM(begin_checkout_flag) \* 100.0 / COUNT(\*), 2) AS checkout_rate,

  ROUND(SUM(add_shipping_info_flag) \* 100.0 / COUNT(\*), 2) AS shipping_info_rate,

  ROUND(SUM(add_payment_info_flag) \* 100.0 / COUNT(\*), 2) AS payment_info_rate,

  ROUND(SUM(purchase_flag) \* 100.0 / COUNT(\*), 2) AS purchase_session_rate

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

GROUP BY 1

ORDER BY purchase_session_rate DESC;


\-- Does the probability of having derived source/medium increase as a session progresses further through the funnel?


SELECT

  'All Sessions' AS funnel_state,

  COUNT(\*) AS sessions,

  ROUND(SUM(CASE WHEN session_source IS NOT NULL OR session_medium IS NOT NULL THEN 1 ELSE 0 END) \* 100.0 / COUNT(\*), 2) AS attributed_pct,

  ROUND(SUM(CASE WHEN session_source IS NULL AND session_medium IS NULL THEN 1 ELSE 0 END) \* 100.0 / COUNT(\*), 2) AS unattributed_pct

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`


UNION ALL


SELECT

  'Viewed Product' AS funnel_state,

  COUNT(\*) AS sessions,

  ROUND(SUM(CASE WHEN session_source IS NOT NULL OR session_medium IS NOT NULL THEN 1 ELSE 0 END) \* 100.0 / COUNT(\*), 2) AS attributed_pct,

  ROUND(SUM(CASE WHEN session_source IS NULL AND session_medium IS NULL THEN 1 ELSE 0 END) \* 100.0 / COUNT(\*), 2) AS unattributed_pct
