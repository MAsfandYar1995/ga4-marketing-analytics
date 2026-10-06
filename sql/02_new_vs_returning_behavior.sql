/*
GA4 Marketing Analytics Portfolio Project
Dataset: Google Analytics 4 obfuscated sample ecommerce
Analysis window: 2020-11-01 to 2021-01-31
SQL dialect: GoogleSQL (BigQuery)
*/

/*
Purpose:
- Classify sessions as New or Returning using ga_session_number.
- Compare session mix and ecommerce funnel behaviour.
- Calculate stage-to-stage funnel progression.
*/

WHEN event_name = 'add_to_cart' THEN 1

      ELSE 0

    END AS add_to_cart_flag,

    CASE

      WHEN event_name = 'begin_checkout' THEN 1

      ELSE 0

    END AS begin_checkout_flag,

    CASE

      WHEN event_name = 'add_shipping_info' THEN 1

      ELSE 0

    END AS add_shipping_info_flag,

    CASE

      WHEN event_name = 'add_payment_info' THEN 1

      ELSE 0

    END AS add_payment_info_flag,

    CASE

      WHEN event_name = 'purchase' THEN 1

      ELSE 0

    END AS purchase_flag,

  FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

  WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'


),


sessions_base AS (


  SELECT

    unique_session_id,

    ga_session_number,

    MAX(view_item_flag) AS has_view_item,

    MAX(add_to_cart_flag) AS has_add_to_cart,

    MAX(begin_checkout_flag) AS has_begin_checkout,

    MAX(add_shipping_info_flag) AS has_added_shipping_info,

    MAX(add_payment_info_flag) AS has_added_payment_info,

    MAX(purchase_flag) AS has_purchased

  FROM events_base

  GROUP BY 1, 2


),


sessions_aggregated AS (


  SELECT

    CASE

      WHEN ga_session_number = 1 THEN 'New'

      WHEN ga_session_number > 1 THEN 'Returning'

    END AS session_type,

    COUNT(\*) AS total_sessions,

    SUM(has_view_item) AS view_item_sessions,

    SUM(has_add_to_cart) AS add_to_cart_sessions,

    SUM(has_begin_checkout) AS checkout_sessions,

    SUM(has_added_shipping_info) AS shipping_info_sessions,

    SUM(has_added_payment_info) AS payment_info_sessions,

    SUM(has_purchased) AS purchase_sessions

  FROM sessions_base

  GROUP BY 1


)


SELECT


  session_type,

  total_sessions,

  ROUND(view_item_sessions \* 100.0 / total_sessions, 2) AS view_item_rate,

  ROUND(add_to_cart_sessions \* 100.0 / total_sessions, 2) AS add_to_cart_rate,

  ROUND(checkout_sessions \* 100.0 / total_sessions, 2) AS checkout_rate,

  ROUND(shipping_info_sessions \* 100.0 / total_sessions, 2) AS shipping_info_rate,

  ROUND(payment_info_sessions \* 100.0 / total_sessions, 2) AS payment_rate,

  ROUND(purchase_sessions \* 100.0 / total_sessions, 2) AS purchase_rate


FROM sessions_aggregated;


\-- Where do New and Returning sessions drop out of the ecommerce funnel?


WITH events_base AS (


  SELECT

    CONCAT(user_pseudo_id, '-', (SELECT value.int_value FROM UNNEST (event_params) WHERE key = 'ga_session_id')) AS unique_session_id,

    (SELECT value.int_value FROM UNNEST (event_params) WHERE key = 'ga_session_number') AS ga_session_number,

    CASE

      WHEN event_name = 'view_item' THEN 1

      ELSE 0

    END AS view_item_flag,

    CASE

      WHEN event_name = 'add_to_cart' THEN 1

      ELSE 0

    END AS add_to_cart_flag,

    CASE

      WHEN event_name = 'begin_checkout' THEN 1

      ELSE 0

    END AS checkout_flag,

    CASE

      WHEN event_name = 'add_shipping_info' THEN 1

      ELSE 0

    END AS add_shipping_info_flag,

    CASE

      WHEN event_name = 'add_payment_info' THEN 1

      ELSE 0

    END AS add_payment_info_flag,

    CASE

      WHEN event_name = 'purchase' THEN 1

      ELSE 0

    END AS purchase_flag,

  FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

    WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'


),


sessions_base AS (


  SELECT

    unique_session_id,

    ga_session_number,

    MAX(view_item_flag) AS has_viewed_item,

    MAX(add_to_cart_flag) AS has_added_to_cart,

    MAX(checkout_flag) AS has_checkout,

    MAX(add_shipping_info_flag) AS has_added_shipping_info,

    MAX(add_payment_info_flag) AS has_added_payment_info,

    MAX(purchase_flag) AS has_purchased

  FROM events_base

  GROUP BY 1, 2


),


session_level_aggregations AS (


  SELECT


    CASE

      WHEN ga_session_number = 1 THEN 'New'

      WHEN ga_session_number > 1 THEN 'Existing'

    END AS session_type,

    COUNT(\*) AS total_sessions,

    SUM(has_viewed_item) AS view_item_sessions,

    SUM(has_added_to_cart) AS add_to_cart_sessions,

    SUM(has_checkout) AS checkout_sessions,

    SUM(has_added_shipping_info) AS shipping_info_sessions,

    SUM(has_added_payment_info) AS payment_info_sessions,

    SUM(has_purchased) AS purchase_sessions


  FROM sessions_base

  GROUP BY 1


)


SELECT

  session_type,

  ROUND(add_to_cart_sessions \* 100.0 / view_item_sessions, 2) AS view_to_cart_pct,

  ROUND(checkout_sessions \* 100.0 / add_to_cart_sessions, 2) AS cart_to_checkout_pct,

  ROUND(shipping_info_sessions \* 100.0 / checkout_sessions, 2) AS checkout_to_shipping_pct,

  ROUND(payment_info_sessions \* 100.0 / shipping_info_sessions, 2) AS shipping_to_payment_pct,

  ROUND(purchase_sessions \* 100.0 / payment_info_sessions, 2) AS payment_to_purchase_pct

FROM session_level_aggregations;
