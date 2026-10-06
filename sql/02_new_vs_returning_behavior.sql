
WITH events_base AS (

    SELECT
        CONCAT(
            user_pseudo_id,
            '-',
            CAST(
                (
                    SELECT value.int_value
                    FROM UNNEST(event_params)
                    WHERE key = 'ga_session_id'
                ) AS STRING
            )
        ) AS unique_session_id,

        (
            SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'ga_session_number'
        ) AS ga_session_number,

        CASE WHEN event_name = 'view_item' THEN 1 ELSE 0 END
            AS view_item_flag,

        CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END
            AS add_to_cart_flag,

        CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END
            AS begin_checkout_flag,

        CASE WHEN event_name = 'add_shipping_info' THEN 1 ELSE 0 END
            AS add_shipping_info_flag,

        CASE WHEN event_name = 'add_payment_info' THEN 1 ELSE 0 END
            AS add_payment_info_flag,

        CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END
            AS purchase_flag

    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),


sessions_base AS (

    SELECT
        unique_session_id,
        ga_session_number,

        MAX(view_item_flag) AS has_view_item,
        MAX(add_to_cart_flag) AS has_add_to_cart,
        MAX(begin_checkout_flag) AS has_begin_checkout,
        MAX(add_shipping_info_flag) AS has_shipping_info,
        MAX(add_payment_info_flag) AS has_payment_info,
        MAX(purchase_flag) AS has_purchase

    FROM events_base

    WHERE unique_session_id IS NOT NULL

    GROUP BY
        unique_session_id,
        ga_session_number
),


session_aggregates AS (

    SELECT
        CASE
            WHEN ga_session_number = 1 THEN 'New'
            WHEN ga_session_number > 1 THEN 'Returning'
        END AS session_type,

        COUNT(*) AS total_sessions,

        SUM(has_view_item) AS view_item_sessions,
        SUM(has_add_to_cart) AS add_to_cart_sessions,
        SUM(has_begin_checkout) AS checkout_sessions,
        SUM(has_shipping_info) AS shipping_info_sessions,
        SUM(has_payment_info) AS payment_info_sessions,
        SUM(has_purchase) AS purchase_sessions

    FROM sessions_base

    WHERE ga_session_number IS NOT NULL

    GROUP BY 1
)


SELECT
    session_type,

    total_sessions,
    view_item_sessions,
    add_to_cart_sessions,
    checkout_sessions,
    shipping_info_sessions,
    payment_info_sessions,
    purchase_sessions,

    -- Funnel stages as a percentage of all sessions
    ROUND(
        SAFE_DIVIDE(view_item_sessions, total_sessions) * 100,
        2
    ) AS view_item_rate,

    ROUND(
        SAFE_DIVIDE(add_to_cart_sessions, total_sessions) * 100,
        2
    ) AS add_to_cart_rate,

    ROUND(
        SAFE_DIVIDE(checkout_sessions, total_sessions) * 100,
        2
    ) AS checkout_rate,

    ROUND(
        SAFE_DIVIDE(shipping_info_sessions, total_sessions) * 100,
        2
    ) AS shipping_info_rate,

    ROUND(
        SAFE_DIVIDE(payment_info_sessions, total_sessions) * 100,
        2
    ) AS payment_info_rate,

    ROUND(
        SAFE_DIVIDE(purchase_sessions, total_sessions) * 100,
        2
    ) AS purchase_rate,

    -- Stage-to-stage progression
    ROUND(
        SAFE_DIVIDE(add_to_cart_sessions, view_item_sessions) * 100,
        2
    ) AS view_to_cart_pct,

    ROUND(
        SAFE_DIVIDE(checkout_sessions, add_to_cart_sessions) * 100,
        2
    ) AS cart_to_checkout_pct,

    ROUND(
        SAFE_DIVIDE(shipping_info_sessions, checkout_sessions) * 100,
        2
    ) AS checkout_to_shipping_pct,

    ROUND(
        SAFE_DIVIDE(payment_info_sessions, shipping_info_sessions) * 100,
        2
    ) AS shipping_to_payment_pct,

    ROUND(
        SAFE_DIVIDE(purchase_sessions, payment_info_sessions) * 100,
        2
    ) AS payment_to_purchase_pct

FROM session_aggregates

ORDER BY session_type;
