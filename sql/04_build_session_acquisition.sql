/*
Model: Session Acquisition
Purpose:
Build one row per GA4 session containing the session identifier,
user information and derived session-level traffic attribution.

Attribution logic:
- A session is identified using user_pseudo_id + ga_session_id.
- The earliest event in each session is retained as the session start.
- Traffic attribution is taken from the first event in the session
  where both source and medium are available.
- Campaign is taken from the same traffic event and may be NULL.
- Sessions without valid source/medium information are retained
  through a LEFT JOIN and remain unattributed.

Output table:
ga4-marketing-analysis-509418.ga4_analysis.session_acquisition

Analysis period:
2020-11-01 to 2021-01-31
*/


CREATE OR REPLACE TABLE
    `ga4-marketing-analysis-509418.ga4_analysis.session_acquisition`
AS


-- ============================================================
-- 1. EXTRACT SESSION AND TRAFFIC FIELDS FROM RAW EVENTS
-- ============================================================

WITH events_base AS (

    SELECT
        user_pseudo_id,

        (
            SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'ga_session_id'
        ) AS ga_session_id,

        (
            SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'ga_session_number'
        ) AS ga_session_number,

        event_timestamp,

        (
            SELECT value.string_value
            FROM UNNEST(event_params)
            WHERE key = 'source'
        ) AS event_source,

        (
            SELECT value.string_value
            FROM UNNEST(event_params)
            WHERE key = 'medium'
        ) AS event_medium,

        (
            SELECT value.string_value
            FROM UNNEST(event_params)
            WHERE key = 'campaign'
        ) AS event_campaign

    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),


-- ============================================================
-- 2. CREATE UNIQUE SESSION IDENTIFIER
-- ============================================================

sessionized AS (

    SELECT
        user_pseudo_id,
        ga_session_id,
        ga_session_number,
        event_timestamp,
        event_source,
        event_medium,
        event_campaign,

        CONCAT(
            user_pseudo_id,
            '-',
            CAST(ga_session_id AS STRING)
        ) AS unique_session_id

    FROM events_base

    WHERE user_pseudo_id IS NOT NULL
      AND ga_session_id IS NOT NULL
),


-- ============================================================
-- 3. IDENTIFY FIRST VALID TRAFFIC EVENT WITHIN EACH SESSION
-- ============================================================

traffic_events_ranked AS (

    SELECT
        unique_session_id,
        event_timestamp,
        event_source,
        event_medium,
        event_campaign,

        ROW_NUMBER() OVER (
            PARTITION BY unique_session_id
            ORDER BY event_timestamp
        ) AS traffic_event_rank

    FROM sessionized

    WHERE event_source IS NOT NULL
      AND event_medium IS NOT NULL
),


first_traffic_event AS (

    SELECT
        unique_session_id,
        event_timestamp AS first_traffic_event_timestamp,
        event_source AS session_source,
        event_medium AS session_medium,
        event_campaign AS session_campaign

    FROM traffic_events_ranked

    WHERE traffic_event_rank = 1
),


-- ============================================================
-- 4. BUILD ONE ROW PER SESSION
-- ============================================================

all_sessions AS (

    SELECT
        unique_session_id,
        user_pseudo_id,
        ga_session_id,
        ga_session_number,
        MIN(event_timestamp) AS earliest_event_timestamp

    FROM sessionized

    GROUP BY
        unique_session_id,
        user_pseudo_id,
        ga_session_id,
        ga_session_number
)


-- ============================================================
-- 5. ATTACH SESSION-LEVEL TRAFFIC ATTRIBUTION
-- ============================================================

SELECT
    s.unique_session_id,
    s.user_pseudo_id,
    s.ga_session_id,
    s.ga_session_number,
    s.earliest_event_timestamp,

    t.first_traffic_event_timestamp,
    t.session_source,
    t.session_medium,
    t.session_campaign

FROM all_sessions AS s

LEFT JOIN first_traffic_event AS t
    ON s.unique_session_id = t.unique_session_id;
