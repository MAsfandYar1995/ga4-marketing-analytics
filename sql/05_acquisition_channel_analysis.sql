/*
GA4 Marketing Analytics Portfolio Project
Dataset: Google Analytics 4 obfuscated sample ecommerce
Analysis window: 2020-11-01 to 2021-01-31
SQL dialect: GoogleSQL (BigQuery)
*/

/*
Purpose:
- Analyse source / medium session volume.
- Identify self-referrals.
- Derive broad marketing channel groups.
- Inspect uncategorised traffic.
*/

\-- session_source, session_medium, number of sessions, percentage of all sessions


WITH session_medium_base AS (


  SELECT

    session_source,

    session_medium,

    COUNT(\*) AS number_of_sessions

  FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_acquisition\`

  GROUP BY 1, 2


)


SELECT

  session_source,

  session_medium,

  number_of_sessions,

  ROUND(number_of_sessions \* 100 / SUM(number_of_sessions) OVER (), 2) AS session_share_pct

FROM session_medium_base

ORDER BY number_of_sessions DESC;


\-- How much traffic is being classified as referrals from the site's own domains?


WITH sessions_base AS (


  SELECT

    session_source,

    COUNT(\*) AS number_of_sessions

  FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_acquisition\`

  GROUP BY 1


),


source_groups AS (


  SELECT

    COUNT(\*) AS total_sessions,

  FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_acquisition\`

  WHERE session_source LIKE '%googlemerchandise%' AND session_medium = 'referral'


),


overall_sessions AS (


  SELECT

    SUM(number_of_sessions) AS total_sessions

  FROM sessions_base

)


SELECT

  ROUND(sg.total_sessions \* 100 / os.total_sessions, 2) AS self_referral_sessions_share_pct

FROM source_groups sg

CROSS JOIN overall_sessions os;


\-- Session share by derived channel group


WITH channel_groups_sessions AS (


  SELECT

    CASE

      WHEN session_source IS NULL AND session_medium IS NULL THEN 'Unattributed'

      WHEN session_source LIKE '%googlemerchandise%' AND session_medium = 'referral' THEN 'Self-referral'

      WHEN session_source = '(direct)' AND session_medium = '(none)' THEN 'Direct'

      WHEN session_medium = 'organic' THEN 'Organic Search'

      WHEN session_medium = 'cpc' THEN 'Paid Search'

      WHEN session_medium = 'email' THEN 'Email'

      WHEN session_medium = 'affiliate' THEN 'Affiliate'

      WHEN session_medium = 'referral' THEN 'Referral'

      WHEN session_medium IN ('(data deleted)', '\<Other>') THEN 'Data Unavailable'

      ELSE 'Other'

    END AS channel_group,

    COUNT(\*) AS sessions

  FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_acquisition\`

  GROUP BY 1


)


SELECT

  channel_group,

  sessions,

  ROUND(sessions \* 100.0 / SUM(sessions) OVER (), 2) AS session_share_pct

FROM channel_groups_sessions

ORDER BY session_share_pct DESC;


\-- What source/medium combinations make up the Other channel?


\-- Show:


\-- session_source, session_medium, sessions, percentage within the Other category


\-- Sort largest to smallest.


WITH channel_groups_sessions AS (


  SELECT

    \*,

    CASE

      WHEN session_source IS NULL AND session_medium IS NULL THEN 'Unattributed'

      WHEN session_source LIKE '%googlemerchandise%' AND session_medium = 'referral' THEN 'Self-referral'

      WHEN session_source = '(direct)' AND session_medium = '(none)' THEN 'Direct'

      WHEN session_medium = 'organic' THEN 'Organic Search'

      WHEN session_medium = 'cpc' THEN 'Paid Search'

      WHEN session_medium = 'email' THEN 'Email'

      WHEN session_medium = 'affiliate' THEN 'Affiliate'

      WHEN session_medium = 'referral' THEN 'Referral'

      ELSE 'Other'

    END AS channel_group

  FROM \`ga4-marketing-analysis-509418.ga4_analysis.session_acquisition\`


),


other_groups_sessions AS (


  SELECT

    session_source,

    session_medium,

    COUNT(\*) AS sessions

  FROM channel_groups_sessions

  WHERE channel_group = 'Other'

  GROUP BY 1, 2


)


SELECT

  session_source,

  session_medium,

  sessions,

  ROUND(sessions \* 100.0 / SUM(sessions) OVER (), 2) AS pct_within_other_category

FROM other_groups_sessions;


\-- session_ecommerce_performance


SELECT

  CONCAT(user_pseudo_id, '-', (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) AS unique_session_id,

  MAX(CASE WHEN event_name = 'view_item' THEN 1 ELSE 0 END) AS view_item_flag,

  MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS add_to_cart_flag,

  MAX(CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS begin_checkout_flag,

  MAX(CASE WHEN event_name = 'add_shipping_info' THEN 1 ELSE 0 END) AS add_shipping_info_flag,

  MAX(CASE WHEN event_name = 'add_payment_info' THEN 1 ELSE 0 END) AS add_payment_info_flag,

  MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS purchase_flag,

  COALESCE(SUM(ecommerce.purchase_revenue_in_usd), 0) AS session_revenue_usd

FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

GROUP BY 1;


\--- join acquisition + ecommerce performance


SELECT

  sa.unique_session_id,

  sa.user_pseudo_id,

  sa.ga_session_id,

  sa.ga_session_number,

  sa.earliest_event_timestamp,

  sa.first_traffic_event_timestamp,

  sa.session_source,

  sa.session_medium,

  sa.session_campaign,

  CASE

      WHEN sa.session_source IS NULL AND sa.session_medium IS NULL THEN 'Unattributed'
