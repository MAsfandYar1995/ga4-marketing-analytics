/*
GA4 Marketing Analytics Portfolio Project
Dataset: Google Analytics 4 obfuscated sample ecommerce
Analysis window: 2020-11-01 to 2021-01-31
SQL dialect: GoogleSQL (BigQuery)
*/

/*
Purpose:
- Compare ecommerce funnel performance by channel.
- Analyse revenue and revenue per session by channel.
- Compare source / medium combinations.
- Review campaign-level performance.
*/

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

WHERE view_item_flag = 1


UNION ALL


SELECT

  'Added to Cart' AS funnel_state,

  COUNT(\*) AS sessions,

  ROUND(SUM(CASE WHEN session_source IS NOT NULL OR session_medium IS NOT NULL THEN 1 ELSE 0 END) \* 100.0 / COUNT(\*), 2) AS attributed_pct,

  ROUND(SUM(CASE WHEN session_source IS NULL AND session_medium IS NULL THEN 1 ELSE 0 END) \* 100.0 / COUNT(\*), 2) AS unattributed_pct

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

WHERE add_to_cart_flag = 1


UNION ALL


SELECT

  'Began Checkout' AS funnel_state,

  COUNT(\*) AS sessions,

  ROUND(SUM(CASE WHEN session_source IS NOT NULL OR session_medium IS NOT NULL THEN 1 ELSE 0 END) \* 100.0 / COUNT(\*), 2) AS attributed_pct,

  ROUND(SUM(CASE WHEN session_source IS NULL AND session_medium IS NULL THEN 1 ELSE 0 END) \* 100.0 / COUNT(\*), 2) AS unattributed_pct

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

WHERE begin_checkout_flag = 1


UNION ALL


SELECT

  'Purchased' AS funnel_state,

  COUNT(\*) AS sessions,

  ROUND(SUM(CASE WHEN session_source IS NOT NULL OR session_medium IS NOT NULL THEN 1 ELSE 0 END) \* 100.0 / COUNT(\*), 2) AS attributed_pct,

  ROUND(SUM(CASE WHEN session_source IS NULL AND session_medium IS NULL THEN 1 ELSE 0 END) \* 100.0 / COUNT(\*), 2) AS unattributed_pct

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

WHERE purchase_flag = 1;


\-----------------------


SELECT

  \*

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

WHERE purchase_flag = 1 AND

  (add_payment_info_flag = 0 OR add_shipping_info_flag = 0);


\-- 4 rows


SELECT

  \*

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

WHERE purchase_flag = 1 AND begin_checkout_flag = 0;


\--  3 rows


SELECT

  \*

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

WHERE purchase_flag = 1 AND add_to_cart_flag = 0;


\-- 2000 rows


SELECT

  \*

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

WHERE purchase_flag = 1 AND view_item_flag = 0;


\-- 150 rows


\-- For the 2,000 purchase sessions without an add-to-cart event, how many are returning sessions?


SELECT

  CASE

    WHEN ga_session_number = 1 THEN 'New'

    WHEN ga_session_number > 1 THEN 'Returning'

  END AS session_group,

  COUNT(\*)

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

WHERE purchase_flag = 1 AND add_to_cart_flag = 0

GROUP By 1;


\-- new: 666, returning: 1334


\-- What percentage of ALL purchase sessions are returning?

GROUP BY 1

)

ORDER BY total_sessions DESC;


\-- How did the genuine named campaigns perform in terms of traffic, purchases and revenue?

SELECT

  session_campaign,

  session_source,

  session_medium,

  COUNT(\*) AS total_sessions,

  SUM(purchase_flag) AS purchase_sessions,

  ROUND(SUM(purchase_flag) \* 100.0 / COUNT(\*), 2) AS purchase_session_rate,

  SUM(session_revenue_usd) AS total_revenue_usd,

  ROUND(SUM(session_revenue_usd) / COUNT(\*), 2) AS revenue_per_session,

  ROUND(SUM(session_revenue_usd) / SUM(purchase_flag), 2)AS avg_revenue_per_purchasing_session


FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

WHERE session_campaign IS NOT NULL

  AND session_campaign NOT IN ('(organic)', '(referral)','(direct)','\<Other>','(data deleted)')

GROUP BY 1, 2, 3;


\--- Final Table For Power BI

SELECT

\*

FROM (


SELECT

  \*,

  TIMESTAMP_MICROS(earliest_event_timestamp) AS session_timestamp,

  DATE(TIMESTAMP_MICROS(earliest_event_timestamp)) AS session_date,

  DATE_TRUNC(DATE(TIMESTAMP_MICROS(earliest_event_timestamp)), MONTH) AS session_month,

  CASE

    WHEN ga_session_number = 1 THEN 'New'

    WHEN ga_session_number > 1 THEN 'Returning'

  END AS session_type

FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance\`

)

WHERE session_type IS NULL;
