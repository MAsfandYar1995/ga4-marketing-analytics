/*
Analysis: Acquisition Channel Analysis
Purpose:
Analyse session acquisition performance after traffic attribution
has been derived at session level.

Analyses include:
- Session volume by source / medium
- Self-referral traffic
- Session volume by derived marketing channel
- Investigation of source / medium combinations classified as Other

Source table:
ga4-marketing-analysis-509418.ga4_analysis.session_acquisition
*/


-- ============================================================
-- 1. SESSION VOLUME BY SOURCE / MEDIUM
-- ============================================================

WITH source_medium_sessions AS (

    SELECT
        session_source,
        session_medium,
        COUNT(*) AS sessions

    FROM `ga4-marketing-analysis-509418.ga4_analysis.session_acquisition`

    GROUP BY
        session_source,
        session_medium
)

SELECT
    session_source,
    session_medium,
    sessions,

    ROUND(
        SAFE_DIVIDE(
            sessions,
            SUM(sessions) OVER ()
        ) * 100,
        2
    ) AS session_share_pct

FROM source_medium_sessions

ORDER BY sessions DESC;



-- ============================================================
-- 2. SELF-REFERRAL TRAFFIC
-- ============================================================
-- Referrals from the Google Merchandise Store's own domains
-- are separated because they may represent attribution issues
-- rather than genuine external referral traffic.

SELECT
    COUNT(*) AS self_referral_sessions,

    ROUND(
        SAFE_DIVIDE(
            COUNT(*),
            (
                SELECT COUNT(*)
                FROM `ga4-marketing-analysis-509418.ga4_analysis.session_acquisition`
            )
        ) * 100,
        2
    ) AS self_referral_session_share_pct

FROM `ga4-marketing-analysis-509418.ga4_analysis.session_acquisition`

WHERE session_source LIKE '%googlemerchandise%'
  AND session_medium = 'referral';



-- ============================================================
-- 3. SESSION VOLUME BY DERIVED CHANNEL GROUP
-- ============================================================

WITH channel_classification AS (

    SELECT
        unique_session_id,
        session_source,
        session_medium,

        CASE
            WHEN session_source IS NULL
                 AND session_medium IS NULL
                THEN 'Unattributed'

            WHEN session_source LIKE '%googlemerchandise%'
                 AND session_medium = 'referral'
                THEN 'Self-referral'

            WHEN session_source = '(direct)'
                 AND session_medium = '(none)'
                THEN 'Direct'

            WHEN session_medium = 'organic'
                THEN 'Organic Search'

            WHEN session_medium = 'cpc'
                THEN 'Paid Search'

            WHEN session_medium = 'email'
                THEN 'Email'

            WHEN session_medium = 'affiliate'
                THEN 'Affiliate'

            WHEN session_medium = 'referral'
                THEN 'Referral'

            WHEN session_medium IN ('(data deleted)', '<Other>')
                THEN 'Data Unavailable'

            ELSE 'Other'
        END AS channel_group

    FROM `ga4-marketing-analysis-509418.ga4_analysis.session_acquisition`
),

channel_sessions AS (

    SELECT
        channel_group,
        COUNT(*) AS sessions

    FROM channel_classification

    GROUP BY channel_group
)

SELECT
    channel_group,
    sessions,

    ROUND(
        SAFE_DIVIDE(
            sessions,
            SUM(sessions) OVER ()
        ) * 100,
        2
    ) AS session_share_pct

FROM channel_sessions

ORDER BY sessions DESC;



-- ============================================================
-- 4. INVESTIGATE THE "OTHER" CHANNEL
-- ============================================================
-- Review source / medium combinations that do not fit one of
-- the defined marketing-channel rules.

WITH channel_classification AS (

    SELECT
        session_source,
        session_medium,

        CASE
            WHEN session_source IS NULL
                 AND session_medium IS NULL
                THEN 'Unattributed'

            WHEN session_source LIKE '%googlemerchandise%'
                 AND session_medium = 'referral'
                THEN 'Self-referral'

            WHEN session_source = '(direct)'
                 AND session_medium = '(none)'
                THEN 'Direct'

            WHEN session_medium = 'organic'
                THEN 'Organic Search'

            WHEN session_medium = 'cpc'
                THEN 'Paid Search'

            WHEN session_medium = 'email'
                THEN 'Email'

            WHEN session_medium = 'affiliate'
                THEN 'Affiliate'

            WHEN session_medium = 'referral'
                THEN 'Referral'

            WHEN session_medium IN ('(data deleted)', '<Other>')
                THEN 'Data Unavailable'

            ELSE 'Other'
        END AS channel_group

    FROM `ga4-marketing-analysis-509418.ga4_analysis.session_acquisition`
),

other_source_medium AS (

    SELECT
        session_source,
        session_medium,
        COUNT(*) AS sessions

    FROM channel_classification

    WHERE channel_group = 'Other'

    GROUP BY
        session_source,
        session_medium
)

SELECT
    session_source,
    session_medium,
    sessions,

    ROUND(
        SAFE_DIVIDE(
            sessions,
            SUM(sessions) OVER ()
        ) * 100,
        2
    ) AS pct_within_other_channel

FROM other_source_medium

ORDER BY sessions DESC;
