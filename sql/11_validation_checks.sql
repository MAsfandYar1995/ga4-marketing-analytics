/*
Analysis: Validation Checks

Purpose:
Validate the integrity of the session-level analytical models before
using them for reporting and downstream analysis.

Checks include:
- Duplicate session IDs
- Missing identifiers
- Row counts across session models
- New / Returning classification completeness
- Ecommerce flag validity
- Funnel consistency diagnostics
- Purchase-session behaviour
- Revenue consistency
- Purchase-frequency validation

These checks are intended to identify unexpected patterns rather
than automatically classify them as data errors.
*/


-- ============================================================
-- 1. CHECK FOR DUPLICATE SESSION IDs
-- ============================================================
-- Expected result: zero rows.

SELECT
    unique_session_id,
    COUNT(*) AS row_count

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final`

GROUP BY unique_session_id

HAVING COUNT(*) > 1

ORDER BY row_count DESC;



-- ============================================================
-- 2. CHECK FOR MISSING SESSION OR USER IDENTIFIERS
-- ============================================================

SELECT
    COUNT(*) AS total_sessions,

    COUNTIF(unique_session_id IS NULL)
        AS sessions_missing_unique_session_id,

    COUNTIF(user_pseudo_id IS NULL)
        AS sessions_missing_user_id,

    COUNTIF(ga_session_id IS NULL)
        AS sessions_missing_ga_session_id,

    COUNTIF(ga_session_number IS NULL)
        AS sessions_missing_ga_session_number

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`;



-- ============================================================
-- 3. COMPARE ROW COUNTS ACROSS SESSION MODELS
-- ============================================================
-- session_acquisition and session_ecommerce_performance should
-- contain one row per valid GA4 session.
--
-- session_marketing_performance_final may contain fewer rows
-- because File 09 retains only sessions that can be classified
-- as New or Returning.

SELECT
    'session_acquisition' AS table_name,
    COUNT(*) AS rows,
    COUNT(DISTINCT unique_session_id) AS distinct_sessions

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_acquisition`

UNION ALL

SELECT
    'session_ecommerce_performance',
    COUNT(*),
    COUNT(DISTINCT unique_session_id)

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_ecommerce_performance`

UNION ALL

SELECT
    'session_marketing_performance',
    COUNT(*),
    COUNT(DISTINCT unique_session_id)

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`

UNION ALL

SELECT
    'session_marketing_performance_final',
    COUNT(*),
    COUNT(DISTINCT unique_session_id)

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final`;



-- ============================================================
-- 4. VALIDATE NEW / RETURNING SESSION CLASSIFICATION
-- ============================================================

SELECT
    session_type,
    COUNT(*) AS sessions,

    ROUND(
        SAFE_DIVIDE(
            COUNT(*),
            SUM(COUNT(*)) OVER ()
        ) * 100,
        2
    ) AS session_share_pct

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final`

GROUP BY session_type

ORDER BY sessions DESC;



-- ============================================================
-- 5. CHECK FOR UNCLASSIFIED SESSIONS IN THE CORE MODEL
-- ============================================================
-- These sessions would be removed from the final Power BI model.

SELECT
    COUNT(*) AS unclassified_sessions

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`

WHERE ga_session_number IS NULL
   OR ga_session_number < 1;



-- ============================================================
-- 6. VALIDATE ECOMMERCE FLAGS
-- ============================================================
-- Expected values for each flag are only 0 or 1.

SELECT
    MIN(view_item_flag) AS min_view_item_flag,
    MAX(view_item_flag) AS max_view_item_flag,

    MIN(add_to_cart_flag) AS min_add_to_cart_flag,
    MAX(add_to_cart_flag) AS max_add_to_cart_flag,

    MIN(begin_checkout_flag) AS min_begin_checkout_flag,
    MAX(begin_checkout_flag) AS max_begin_checkout_flag,

    MIN(add_shipping_info_flag) AS min_shipping_flag,
    MAX(add_shipping_info_flag) AS max_shipping_flag,

    MIN(add_payment_info_flag) AS min_payment_flag,
    MAX(add_payment_info_flag) AS max_payment_flag,

    MIN(purchase_flag) AS min_purchase_flag,
    MAX(purchase_flag) AS max_purchase_flag

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`;



-- ============================================================
-- 7. PURCHASE SESSIONS MISSING EARLIER FUNNEL EVENTS
-- ============================================================
-- GA4 sessions do not necessarily follow a perfectly linear
-- funnel. These checks identify unusual event sequences for
-- investigation rather than treating them automatically as errors.

SELECT
    COUNTIF(
        purchase_flag = 1
        AND view_item_flag = 0
    ) AS purchases_without_view_item,

    COUNTIF(
        purchase_flag = 1
        AND add_to_cart_flag = 0
    ) AS purchases_without_add_to_cart,

    COUNTIF(
        purchase_flag = 1
        AND begin_checkout_flag = 0
    ) AS purchases_without_begin_checkout,

    COUNTIF(
        purchase_flag = 1
        AND add_shipping_info_flag = 0
    ) AS purchases_without_shipping_info,

    COUNTIF(
        purchase_flag = 1
        AND add_payment_info_flag = 0
    ) AS purchases_without_payment_info,

    COUNTIF(
        purchase_flag = 1
        AND (
            add_shipping_info_flag = 0
            OR add_payment_info_flag = 0
        )
    ) AS purchases_missing_shipping_or_payment

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`;



-- ============================================================
-- 8. PURCHASE SESSIONS WITHOUT ADD-TO-CART BY SESSION TYPE
-- ============================================================
-- Used to investigate whether unusual funnel sequences are more
-- common among New or Returning sessions.

SELECT
    CASE
        WHEN ga_session_number = 1
            THEN 'New'

        WHEN ga_session_number > 1
            THEN 'Returning'

        ELSE 'Unknown'
    END AS session_type,

    COUNT(*) AS purchase_sessions_without_add_to_cart

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`

WHERE purchase_flag = 1
  AND add_to_cart_flag = 0

GROUP BY session_type

ORDER BY purchase_sessions_without_add_to_cart DESC;



-- ============================================================
-- 9. PURCHASE SESSION DISTRIBUTION BY SESSION TYPE
-- ============================================================

SELECT
    CASE
        WHEN ga_session_number = 1
            THEN 'New'

        WHEN ga_session_number > 1
            THEN 'Returning'

        ELSE 'Unknown'
    END AS session_type,

    COUNT(*) AS purchase_sessions,

    ROUND(
        SAFE_DIVIDE(
            COUNT(*),
            SUM(COUNT(*)) OVER ()
        ) * 100,
        2
    ) AS purchase_session_share_pct

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`

WHERE purchase_flag = 1

GROUP BY session_type

ORDER BY purchase_sessions DESC;



-- ============================================================
-- 10. REVENUE CONSISTENCY CHECK
-- ============================================================
-- Investigate whether revenue and purchase flags are aligned.

SELECT
    COUNT(*) AS total_sessions,

    COUNTIF(
        purchase_flag = 1
        AND session_revenue_usd <= 0
    ) AS purchase_sessions_without_positive_revenue,

    COUNTIF(
        purchase_flag = 0
        AND session_revenue_usd > 0
    ) AS non_purchase_sessions_with_revenue,

    ROUND(
        SUM(session_revenue_usd),
        2
    ) AS total_revenue_usd

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final`;



-- ============================================================
-- 11. CHANNEL ATTRIBUTION COMPLETENESS
-- ============================================================

SELECT
    COUNT(*) AS total_sessions,

    COUNTIF(
        session_source IS NOT NULL
        AND session_medium IS NOT NULL
    ) AS attributed_sessions,

    COUNTIF(
        session_source IS NULL
        OR session_medium IS NULL
    ) AS sessions_with_incomplete_attribution,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(
                session_source IS NOT NULL
                AND session_medium IS NOT NULL
            ),
            COUNT(*)
        ) * 100,
        2
    ) AS attributed_session_pct

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`;



-- ============================================================
-- 12. PURCHASE-FREQUENCY DISTRIBUTION
-- ============================================================

SELECT
    frequency_group,
    COUNT(*) AS purchasers,

    ROUND(
        SAFE_DIVIDE(
            COUNT(*),
            SUM(COUNT(*)) OVER ()
        ) * 100,
        2
    ) AS purchaser_share_pct

FROM `ga4-marketing-analysis-509418.ga4_analysis.user_purchase_frequency`

GROUP BY frequency_group

ORDER BY
    CASE frequency_group
        WHEN '1 Purchase' THEN 1
        WHEN '2 Purchases' THEN 2
        WHEN '3+ Purchases' THEN 3
    END;



-- ============================================================
-- 13. VALIDATE REPEAT PURCHASER RATE
-- ============================================================

SELECT
    COUNT(*) AS total_purchasers,

    COUNTIF(purchase_count >= 2)
        AS repeat_purchasers,

    COUNTIF(purchase_count = 1)
        AS one_time_purchasers,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(purchase_count >= 2),
            COUNT(*)
        ) * 100,
        2
    ) AS repeat_purchaser_rate,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(purchase_count = 1),
            COUNT(*)
        ) * 100,
        2
    ) AS one_time_purchaser_rate

FROM `ga4-marketing-analysis-509418.ga4_analysis.user_purchase_frequency`;
