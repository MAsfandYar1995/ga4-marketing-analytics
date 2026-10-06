/*
Model: Power BI Session Model

Purpose:
Prepare the final session-level analytical table used in Power BI.

This model extends session_marketing_performance with:
- Readable session timestamp
- Session date
- Session month
- New vs Returning session classification

Input table:
ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance

Output table:
ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final
*/


CREATE OR REPLACE TABLE
    `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final`
AS


-- ============================================================
-- 1. ADD POWER BI FRIENDLY DATE AND USER-TYPE FIELDS
-- ============================================================

WITH final_sessions AS (

    SELECT
        unique_session_id,
        user_pseudo_id,
        ga_session_id,
        ga_session_number,

        earliest_event_timestamp,
        first_traffic_event_timestamp,

        session_source,
        session_medium,
        session_campaign,
        channel_group,

        view_item_flag,
        add_to_cart_flag,
        begin_checkout_flag,
        add_shipping_info_flag,
        add_payment_info_flag,
        purchase_flag,

        session_revenue_usd,


        -- Convert GA4 microsecond timestamp into standard timestamp
        TIMESTAMP_MICROS(earliest_event_timestamp)
            AS session_timestamp,


        -- Calendar date used for Power BI date relationships
        DATE(
            TIMESTAMP_MICROS(earliest_event_timestamp)
        ) AS session_date,


        -- Month-level field for trend analysis
        DATE_TRUNC(
            DATE(TIMESTAMP_MICROS(earliest_event_timestamp)),
            MONTH
        ) AS session_month,


        -- Classify the session as New or Returning
        CASE
            WHEN ga_session_number = 1
                THEN 'New'

            WHEN ga_session_number > 1
                THEN 'Returning'
        END AS session_type

    FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance`
)


-- ============================================================
-- 2. RETAIN CLASSIFIABLE SESSIONS
-- ============================================================

SELECT
    *

FROM final_sessions

WHERE session_type IS NOT NULL;
