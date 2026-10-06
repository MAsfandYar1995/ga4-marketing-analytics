/*
Model: Session Ecommerce Performance

Purpose:
Build one row per GA4 session containing ecommerce funnel flags
and session-level purchase revenue.

Each funnel flag equals:
- 1 if the event occurred at least once during the session
- 0 if the event did not occur

Funnel stages:
- View Item
- Add to Cart
- Begin Checkout
- Add Shipping Info
- Add Payment Info
- Purchase

Output table:
ga4-marketing-analysis-509418.ga4_analysis.session_ecommerce_performance

Analysis period:
2020-11-01 to 2021-01-31
*/


CREATE OR REPLACE TABLE
    `ga4-marketing-analysis-509418.ga4_analysis.session_ecommerce_performance`
AS


-- ============================================================
-- 1. EXTRACT SESSION ID AND ECOMMERCE EVENT DATA
-- ============================================================

WITH events_base AS (

    SELECT
        user_pseudo_id,

        (
            SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'ga_session_id'
        ) AS ga_session_id,

        event_name,

        ecommerce.purchase_revenue_in_usd AS purchase_revenue_usd

    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),


-- ============================================================
-- 2. CREATE UNIQUE SESSION IDENTIFIER
-- ============================================================

sessionized AS (

    SELECT
        CONCAT(
            user_pseudo_id,
            '-',
            CAST(ga_session_id AS STRING)
        ) AS unique_session_id,

        event_name,
        purchase_revenue_usd

    FROM events_base

    WHERE user_pseudo_id IS NOT NULL
      AND ga_session_id IS NOT NULL
)


-- ============================================================
-- 3. AGGREGATE ECOMMERCE ACTIVITY TO SESSION LEVEL
-- ============================================================

SELECT
    unique_session_id,

    MAX(
        CASE
            WHEN event_name = 'view_item' THEN 1
            ELSE 0
        END
    ) AS view_item_flag,

    MAX(
        CASE
            WHEN event_name = 'add_to_cart' THEN 1
            ELSE 0
        END
    ) AS add_to_cart_flag,

    MAX(
        CASE
            WHEN event_name = 'begin_checkout' THEN 1
            ELSE 0
        END
    ) AS begin_checkout_flag,

    MAX(
        CASE
            WHEN event_name = 'add_shipping_info' THEN 1
            ELSE 0
        END
    ) AS add_shipping_info_flag,

    MAX(
        CASE
            WHEN event_name = 'add_payment_info' THEN 1
            ELSE 0
        END
    ) AS add_payment_info_flag,

    MAX(
        CASE
            WHEN event_name = 'purchase' THEN 1
            ELSE 0
        END
    ) AS purchase_flag,

    COALESCE(
        SUM(purchase_revenue_usd),
        0
    ) AS session_revenue_usd

FROM sessionized

GROUP BY unique_session_id;
