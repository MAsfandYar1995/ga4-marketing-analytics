/*
Model: Session Marketing Performance

Purpose:
Combine session-level acquisition attribution with ecommerce
behaviour to create the core analytical table used for marketing
performance analysis.

The model combines:
- User and session identifiers
- Source / medium / campaign attribution
- Derived marketing channel
- Ecommerce funnel flags
- Session revenue

Input tables:
ga4-marketing-analysis-509418.ga4_analysis.session_acquisition
ga4-marketing-analysis-509418.ga4_analysis.session_ecommerce_performance

Output table:
ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance
*/


CREATE OR REPLACE TABLE
    `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`
AS


-- ============================================================
-- 1. COMBINE ACQUISITION AND ECOMMERCE SESSION DATA
-- ============================================================

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


    -- ========================================================
    -- DERIVE MARKETING CHANNEL
    -- ========================================================

    CASE
        WHEN sa.session_source IS NULL
             AND sa.session_medium IS NULL
            THEN 'Unattributed'

        WHEN sa.session_source LIKE '%googlemerchandise%'
             AND sa.session_medium = 'referral'
            THEN 'Self-referral'

        WHEN sa.session_source = '(direct)'
             AND sa.session_medium = '(none)'
            THEN 'Direct'

        WHEN sa.session_medium = 'organic'
            THEN 'Organic Search'

        WHEN sa.session_medium = 'cpc'
            THEN 'Paid Search'

        WHEN sa.session_medium = 'email'
            THEN 'Email'

        WHEN sa.session_medium = 'affiliate'
            THEN 'Affiliate'

        WHEN sa.session_medium = 'referral'
            THEN 'Referral'

        WHEN sa.session_medium IN ('(data deleted)', '<Other>')
            THEN 'Data Unavailable'

        ELSE 'Other'
    END AS channel_group,


    -- ========================================================
    -- ECOMMERCE FUNNEL FLAGS
    -- ========================================================

    COALESCE(se.view_item_flag, 0)
        AS view_item_flag,

    COALESCE(se.add_to_cart_flag, 0)
        AS add_to_cart_flag,

    COALESCE(se.begin_checkout_flag, 0)
        AS begin_checkout_flag,

    COALESCE(se.add_shipping_info_flag, 0)
        AS add_shipping_info_flag,

    COALESCE(se.add_payment_info_flag, 0)
        AS add_payment_info_flag,

    COALESCE(se.purchase_flag, 0)
        AS purchase_flag,


    -- ========================================================
    -- SESSION REVENUE
    -- ========================================================

    COALESCE(se.session_revenue_usd, 0)
        AS session_revenue_usd


FROM `ga4-marketing-analysis-509418.ga4_analysis.session_acquisition` AS sa

LEFT JOIN
    `ga4-marketing-analysis-509418.ga4_analysis.session_ecommerce_performance` AS se

    ON sa.unique_session_id = se.unique_session_id;
