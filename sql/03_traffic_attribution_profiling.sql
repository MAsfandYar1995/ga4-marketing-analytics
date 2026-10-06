/*
Analysis: Traffic Attribution Profiling
Purpose:
Inspect the traffic acquisition fields available in the raw GA4 dataset
before building the session-level acquisition model.

Checks include:
- User acquisition source / medium / campaign values
- Event-level source / medium / campaign values
- Traffic-field completeness by event type
- Whether source, medium and campaign appear together
- Session-level attribution coverage using the first valid traffic event

Dataset:
bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*

Analysis period:
2020-11-01 to 2021-01-31

Note:
GA4 traffic_source fields describe user acquisition traffic, while
source / medium / campaign extracted from event_params are used here
to investigate session-level attribution.
*/


-- ============================================================
-- 1. USER ACQUISITION MEDIUM VALUES
-- ============================================================

SELECT DISTINCT
    traffic_source.medium AS acquisition_medium
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
ORDER BY acquisition_medium;



-- ============================================================
-- 2. USER ACQUISITION SOURCE VALUES
-- ============================================================

SELECT DISTINCT
    traffic_source.source AS acquisition_source
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
ORDER BY acquisition_source;



-- ============================================================
-- 3. USER ACQUISITION CAMPAIGN VALUES
-- ============================================================

SELECT DISTINCT
    traffic_source.name AS acquisition_campaign
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
ORDER BY acquisition_campaign;



-- ============================================================
-- 4. EVENT-LEVEL SOURCE VALUES
-- ============================================================

SELECT DISTINCT
    (
        SELECT value.string_value
        FROM UNNEST(event_params)
        WHERE key = 'source'
    ) AS event_source
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
ORDER BY event_source;



-- ============================================================
-- 5. EVENT-LEVEL MEDIUM VALUES
-- ============================================================

SELECT DISTINCT
    (
        SELECT value.string_value
        FROM UNNEST(event_params)
        WHERE key = 'medium'
    ) AS event_medium
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
ORDER BY event_medium;



-- ============================================================
-- 6. EVENT-LEVEL CAMPAIGN VALUES
-- ============================================================

SELECT DISTINCT
    (
        SELECT value.string_value
        FROM UNNEST(event_params)
        WHERE key = 'campaign'
    ) AS event_campaign
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
ORDER BY event_campaign;



-- ============================================================
-- 7. TRAFFIC-FIELD COMPLETENESS BY EVENT TYPE
-- ============================================================

WITH events_base AS (

    SELECT
        event_name,

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
)

SELECT
    event_name,
    COUNT(*) AS total_events,

    COUNTIF(event_source IS NOT NULL)
        AS events_with_source,

    COUNTIF(event_medium IS NOT NULL)
        AS events_with_medium,

    COUNTIF(event_campaign IS NOT NULL)
        AS events_with_campaign,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(event_source IS NOT NULL),
            COUNT(*)
        ) * 100,
        2
    ) AS source_completeness_pct,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(event_medium IS NOT NULL),
            COUNT(*)
        ) * 100,
        2
    ) AS medium_completeness_pct,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(event_campaign IS NOT NULL),
            COUNT(*)
        ) * 100,
        2
    ) AS campaign_completeness_pct

FROM events_base

GROUP BY event_name

ORDER BY total_events DESC;



-- ============================================================
-- 8. TRAFFIC-FIELD CO-OCCURRENCE
-- ============================================================

WITH events_base AS (

    SELECT
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
)

SELECT
    COUNT(*) AS total_events,

    COUNTIF(event_source IS NOT NULL)
        AS events_with_source,

    COUNTIF(event_medium IS NOT NULL)
        AS events_with_medium,

    COUNTIF(event_campaign IS NOT NULL)
        AS events_with_campaign,

    COUNTIF(
        event_source IS NOT NULL
        AND event_medium IS NOT NULL
        AND event_campaign IS NOT NULL
    ) AS events_with_all_three,

    COUNTIF(
        event_source IS NOT NULL
        AND event_medium IS NOT NULL
    ) AS events_with_source_and_medium,

    COUNTIF(
        event_source IS NOT NULL
        AND event_medium IS NULL
    ) AS source_without_medium,

    COUNTIF(
        event_medium IS NOT NULL
        AND event_source IS NULL
    ) AS medium_without_source,

    COUNTIF(
        event_source IS NOT NULL
        AND event_campaign IS NULL
    ) AS source_without_campaign

FROM events_base;



-- ============================================================
-- 9. SESSION-LEVEL ATTRIBUTION COVERAGE
-- ============================================================
-- A session is considered attributed when at least one event in
-- the session contains both source and medium.
--
-- The first such event is used as the candidate traffic event.
-- This same logic is used when building the session acquisition
-- table in the next stage of the project.

WITH events_base AS (

    SELECT
        user_pseudo_id,

        (
            SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'ga_session_id'
        ) AS ga_session_id,

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

sessionized AS (

    SELECT
        *,

        CONCAT(
            user_pseudo_id,
            '-',
            CAST(ga_session_id AS STRING)
        ) AS unique_session_id

    FROM events_base

    WHERE user_pseudo_id IS NOT NULL
      AND ga_session_id IS NOT NULL
),

all_sessions AS (

    SELECT DISTINCT
        unique_session_id
    FROM sessionized
),

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
        event_source AS session_source,
        event_medium AS session_medium,
        event_campaign AS session_campaign

    FROM traffic_events_ranked

    WHERE traffic_event_rank = 1
),

session_attribution AS (

    SELECT
        s.unique_session_id,
        t.session_source,
        t.session_medium,
        t.session_campaign

    FROM all_sessions AS s

    LEFT JOIN first_traffic_event AS t
        ON s.unique_session_id = t.unique_session_id
)

SELECT
    COUNT(*) AS total_sessions,

    COUNTIF(
        session_source IS NOT NULL
        AND session_medium IS NOT NULL
    ) AS attributed_sessions,

    COUNTIF(
        session_source IS NULL
        OR session_medium IS NULL
    ) AS unattributed_sessions,

    COUNTIF(session_campaign IS NOT NULL)
        AS sessions_with_campaign,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(
                session_source IS NOT NULL
                AND session_medium IS NOT NULL
            ),
            COUNT(*)
        ) * 100,
        2
    ) AS attributed_sessions_pct,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(
                session_source IS NULL
                OR session_medium IS NULL
            ),
            COUNT(*)
        ) * 100,
        2
    ) AS unattributed_sessions_pct

FROM session_attribution;
