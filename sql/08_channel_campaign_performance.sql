/*
Analysis: Channel and Campaign Performance

Purpose:
Evaluate the commercial quality of acquisition traffic using the
session-level marketing performance model.

Analyses include:
- Ecommerce funnel performance by marketing channel
- Revenue and conversion performance by marketing channel
- Source / medium ecommerce performance
- Campaign traffic distribution
- Named campaign performance

Source table:
ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance
*/


-- ============================================================
-- 1. ECOMMERCE FUNNEL PERFORMANCE BY CHANNEL
-- ============================================================

SELECT
    channel_group,

    COUNT(*) AS total_sessions,

    SUM(view_item_flag) AS product_view_sessions,
    SUM(add_to_cart_flag) AS add_to_cart_sessions,
    SUM(begin_checkout_flag) AS checkout_sessions,
    SUM(add_shipping_info_flag) AS shipping_info_sessions,
    SUM(add_payment_info_flag) AS payment_info_sessions,
    SUM(purchase_flag) AS purchase_sessions,

    ROUND(
        SAFE_DIVIDE(
            SUM(view_item_flag),
            COUNT(*)
        ) * 100,
        2
    ) AS product_view_rate,

    ROUND(
        SAFE_DIVIDE(
            SUM(add_to_cart_flag),
            COUNT(*)
        ) * 100,
        2
    ) AS add_to_cart_rate,

    ROUND(
        SAFE_DIVIDE(
            SUM(begin_checkout_flag),
            COUNT(*)
        ) * 100,
        2
    ) AS checkout_rate,

    ROUND(
        SAFE_DIVIDE(
            SUM(add_shipping_info_flag),
            COUNT(*)
        ) * 100,
        2
    ) AS shipping_info_rate,

    ROUND(
        SAFE_DIVIDE(
            SUM(add_payment_info_flag),
            COUNT(*)
        ) * 100,
        2
    ) AS payment_info_rate,

    ROUND(
        SAFE_DIVIDE(
            SUM(purchase_flag),
            COUNT(*)
        ) * 100,
        2
    ) AS purchase_session_rate

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`

GROUP BY channel_group

ORDER BY purchase_session_rate DESC;



-- ============================================================
-- 2. REVENUE AND CONVERSION PERFORMANCE BY CHANNEL
-- ============================================================

WITH channel_performance AS (

    SELECT
        channel_group,

        COUNT(*) AS total_sessions,

        SUM(purchase_flag) AS purchase_sessions,

        SUM(session_revenue_usd) AS total_revenue_usd

    FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`

    GROUP BY channel_group
)

SELECT
    channel_group,
    total_sessions,
    purchase_sessions,

    ROUND(total_revenue_usd, 2)
        AS total_revenue_usd,

    ROUND(
        SAFE_DIVIDE(
            purchase_sessions,
            total_sessions
        ) * 100,
        2
    ) AS purchase_session_rate,

    ROUND(
        SAFE_DIVIDE(
            total_revenue_usd,
            total_sessions
        ),
        2
    ) AS revenue_per_session_usd,

    ROUND(
        SAFE_DIVIDE(
            total_revenue_usd,
            purchase_sessions
        ),
        2
    ) AS avg_revenue_per_purchasing_session_usd,

    ROUND(
        SAFE_DIVIDE(
            total_revenue_usd,
            SUM(total_revenue_usd) OVER ()
        ) * 100,
        2
    ) AS revenue_share_pct

FROM channel_performance

ORDER BY total_revenue_usd DESC;



-- ============================================================
-- 3. SOURCE / MEDIUM ECOMMERCE PERFORMANCE
-- ============================================================
-- Exclude traffic categories that are unavailable or represent
-- internal/self-referral attribution.
--
-- Require at least 100 sessions to reduce over-interpretation
-- of very small source / medium combinations.

SELECT
    session_source,
    session_medium,

    COUNT(*) AS total_sessions,

    SUM(purchase_flag) AS purchase_sessions,

    ROUND(
        SAFE_DIVIDE(
            SUM(purchase_flag),
            COUNT(*)
        ) * 100,
        2
    ) AS purchase_session_rate,

    ROUND(
        SUM(session_revenue_usd),
        2
    ) AS total_revenue_usd,

    ROUND(
        SAFE_DIVIDE(
            SUM(session_revenue_usd),
            COUNT(*)
        ),
        2
    ) AS revenue_per_session_usd,

    ROUND(
        SAFE_DIVIDE(
            SUM(session_revenue_usd),
            SUM(purchase_flag)
        ),
        2
    ) AS avg_revenue_per_purchasing_session_usd

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`

WHERE channel_group NOT IN (
        'Self-referral',
        'Unattributed',
        'Data Unavailable'
    )

  AND session_source IS NOT NULL
  AND session_medium IS NOT NULL

  AND session_source NOT IN (
        '<Other>',
        '(data deleted)'
    )

GROUP BY
    session_source,
    session_medium

HAVING COUNT(*) >= 100

ORDER BY total_revenue_usd DESC;



-- ============================================================
-- 4. CAMPAIGN SESSION DISTRIBUTION
-- ============================================================

WITH campaign_sessions AS (

    SELECT
        session_campaign,
        COUNT(*) AS total_sessions

    FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`

    GROUP BY session_campaign
)

SELECT
    session_campaign,
    total_sessions,

    ROUND(
        SAFE_DIVIDE(
            total_sessions,
            SUM(total_sessions) OVER ()
        ) * 100,
        2
    ) AS session_share_pct

FROM campaign_sessions

ORDER BY total_sessions DESC;



-- ============================================================
-- 5. NAMED CAMPAIGN PERFORMANCE
-- ============================================================
-- Exclude values that function as generic traffic labels rather
-- than genuine named marketing campaigns.

SELECT
    session_campaign,
    session_source,
    session_medium,

    COUNT(*) AS total_sessions,

    SUM(purchase_flag) AS purchase_sessions,

    ROUND(
        SAFE_DIVIDE(
            SUM(purchase_flag),
            COUNT(*)
        ) * 100,
        2
    ) AS purchase_session_rate,

    ROUND(
        SUM(session_revenue_usd),
        2
    ) AS total_revenue_usd,

    ROUND(
        SAFE_DIVIDE(
            SUM(session_revenue_usd),
            COUNT(*)
        ),
        2
    ) AS revenue_per_session_usd,

    ROUND(
        SAFE_DIVIDE(
            SUM(session_revenue_usd),
            SUM(purchase_flag)
        ),
        2
    ) AS avg_revenue_per_purchasing_session_usd

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`

WHERE session_campaign IS NOT NULL

  AND session_campaign NOT IN (
        '(organic)',
        '(referral)',
        '(direct)',
        '<Other>',
        '(data deleted)'
    )

GROUP BY
    session_campaign,
    session_source,
    session_medium

ORDER BY total_revenue_usd DESC;
