/*
Analysis: GA4 Data Profiling
Purpose:
Profile the raw GA4 ecommerce dataset before session-level modelling.

Checks include:
- Event distribution
- Dataset date range
- Event and user volumes
- Session ID completeness
- User ID completeness
- Distinct user and session counts
- Sessions with the highest event volume
- Sessions per user
- User session-frequency distribution

Dataset:
bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*

Analysis period:
2020-11-01 to 2021-01-31
*/


-- ============================================================
-- 1. EVENT DISTRIBUTION
-- ============================================================

SELECT
    event_name,
    COUNT(*) AS event_count
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY event_name
ORDER BY event_count DESC;



-- ============================================================
-- 2. OVERALL DATASET PROFILE
-- ============================================================

SELECT
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS earliest_event_date,
    MAX(PARSE_DATE('%Y%m%d', event_date)) AS latest_event_date,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_pseudo_id) AS distinct_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131';



-- ============================================================
-- 3. GA_SESSION_ID COMPLETENESS
-- ============================================================

WITH events_base AS (

    SELECT
        (
            SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'ga_session_id'
        ) AS ga_session_id

    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)

SELECT
    COUNT(*) AS total_events,
    COUNTIF(ga_session_id IS NOT NULL) AS events_with_session_id,
    COUNTIF(ga_session_id IS NULL) AS events_without_session_id,
    ROUND(
        SAFE_DIVIDE(
            COUNTIF(ga_session_id IS NOT NULL),
            COUNT(*)
        ) * 100,
        2
    ) AS session_id_completeness_pct
FROM events_base;



-- ============================================================
-- 4. USER_PSEUDO_ID COMPLETENESS
-- ============================================================

SELECT
    COUNT(*) AS total_events,
    COUNTIF(user_pseudo_id IS NOT NULL) AS events_with_user_id,
    COUNTIF(user_pseudo_id IS NULL) AS events_without_user_id,
    ROUND(
        SAFE_DIVIDE(
            COUNTIF(user_pseudo_id IS NOT NULL),
            COUNT(*)
        ) * 100,
        2
    ) AS user_id_completeness_pct
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131';



-- ============================================================
-- 5. USER, SESSION AND EVENT VOLUMES
-- ============================================================

WITH events_base AS (

    SELECT
        user_pseudo_id,

        (
            SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'ga_session_id'
        ) AS ga_session_id

    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

sessionized AS (

    SELECT
        user_pseudo_id,
        ga_session_id,

        CONCAT(
            user_pseudo_id,
            '-',
            CAST(ga_session_id AS STRING)
        ) AS unique_session_id

    FROM events_base
)

SELECT
    COUNT(DISTINCT user_pseudo_id) AS total_distinct_users,
    COUNT(DISTINCT unique_session_id) AS total_distinct_sessions,
    COUNT(*) AS total_events
FROM sessionized;



-- ============================================================
-- 6. SESSIONS WITH THE MOST EVENTS
-- ============================================================

WITH events_base AS (

    SELECT
        user_pseudo_id,

        (
            SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'ga_session_id'
        ) AS ga_session_id

    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

sessionized AS (

    SELECT
        user_pseudo_id,
        ga_session_id,

        CONCAT(
            user_pseudo_id,
            '-',
            CAST(ga_session_id AS STRING)
        ) AS unique_session_id

    FROM events_base

    WHERE user_pseudo_id IS NOT NULL
      AND ga_session_id IS NOT NULL
)

SELECT
    user_pseudo_id,
    unique_session_id,
    COUNT(*) AS event_count
FROM sessionized
GROUP BY
    user_pseudo_id,
    unique_session_id
ORDER BY event_count DESC
LIMIT 20;



-- ============================================================
-- 7. SESSIONS PER USER SUMMARY
-- ============================================================

WITH events_base AS (

    SELECT
        user_pseudo_id,

        (
            SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'ga_session_id'
        ) AS ga_session_id

    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

user_sessions AS (

    SELECT
        user_pseudo_id,

        COUNT(
            DISTINCT CONCAT(
                user_pseudo_id,
                '-',
                CAST(ga_session_id AS STRING)
            )
        ) AS session_count

    FROM events_base

    WHERE user_pseudo_id IS NOT NULL
      AND ga_session_id IS NOT NULL

    GROUP BY user_pseudo_id
)

SELECT
    COUNT(*) AS total_distinct_users,
    SUM(session_count) AS total_distinct_sessions,
    ROUND(AVG(session_count), 2) AS average_sessions_per_user,
    MIN(session_count) AS minimum_sessions_per_user,
    MAX(session_count) AS maximum_sessions_per_user
FROM user_sessions;



-- ============================================================
-- 8. USER SESSION-FREQUENCY DISTRIBUTION
-- ============================================================

WITH events_base AS (

    SELECT
        user_pseudo_id,

        (
            SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'ga_session_id'
        ) AS ga_session_id

    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

user_sessions AS (

    SELECT
        user_pseudo_id,

        COUNT(
            DISTINCT CONCAT(
                user_pseudo_id,
                '-',
                CAST(ga_session_id AS STRING)
            )
        ) AS session_count

    FROM events_base

    WHERE user_pseudo_id IS NOT NULL
      AND ga_session_id IS NOT NULL

    GROUP BY user_pseudo_id
),

session_frequency AS (

    SELECT
        session_count AS sessions_per_user,
        COUNT(*) AS number_of_users

    FROM user_sessions

    GROUP BY session_count
)

SELECT
    sessions_per_user,
    number_of_users,

    ROUND(
        SAFE_DIVIDE(
            number_of_users,
            SUM(number_of_users) OVER ()
        ) * 100,
        2
    ) AS percentage_of_users

FROM session_frequency

ORDER BY sessions_per_user;
