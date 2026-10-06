/*
Model: Channel Retention

Purpose:
Measure exact-day D7 and D30 retention by the acquisition channel
associated with each user's first observed session.

Retention definitions:
- D7 retained: user has a session exactly 7 days after first session
- D30 retained: user has a session exactly 30 days after first session

Eligibility:
Users are included in the D7 or D30 denominator only when enough
future observation time exists in the dataset.

Channel assignment:
Each user is assigned to the channel_group from their first observed
session where ga_session_number = 1.

Input table:
ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final

Output table:
ga4-marketing-analysis-509418.ga4_analysis.channel_retention
*/


CREATE OR REPLACE TABLE
    `ga4-marketing-analysis-509418.ga4_analysis.channel_retention`
AS


-- ============================================================
-- 1. IDENTIFY DATASET OBSERVATION WINDOW
-- ============================================================

WITH analysis_window AS (

    SELECT
        MAX(session_date) AS max_session_date

    FROM
        `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final`
),


-- ============================================================
-- 2. IDENTIFY EACH USER'S FIRST SESSION
-- ============================================================
-- ga_session_number = 1 identifies first sessions.
--
-- ROW_NUMBER ensures only one record is retained if more than
-- one candidate first-session row exists for a user.

first_session_candidates AS (

    SELECT
        user_pseudo_id,
        unique_session_id,
        session_date,
        session_timestamp,
        channel_group,

        ROW_NUMBER() OVER (
            PARTITION BY user_pseudo_id
            ORDER BY
                session_timestamp,
                unique_session_id
        ) AS first_session_rank

    FROM
        `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final`

    WHERE ga_session_number = 1
),


-- ============================================================
-- 3. ASSIGN EACH USER TO THEIR FIRST-SESSION CHANNEL
-- ============================================================

user_cohorts AS (

    SELECT
        user_pseudo_id,
        session_date AS first_session_date,
        channel_group AS first_session_channel

    FROM first_session_candidates

    WHERE first_session_rank = 1
),


-- ============================================================
-- 4. CREATE DISTINCT USER SESSION DATES
-- ============================================================
-- Exact-day retention only requires confirmation that the user
-- returned on a specific calendar date.

user_session_dates AS (

    SELECT DISTINCT
        user_pseudo_id,
        session_date

    FROM
        `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final`
),


-- ============================================================
-- 5. CALCULATE USER-LEVEL RETENTION FLAGS
-- ============================================================

user_retention AS (

    SELECT
        c.user_pseudo_id,
        c.first_session_date,
        c.first_session_channel,

        -- D7 eligibility
        CASE
            WHEN c.first_session_date <=
                 DATE_SUB(
                     w.max_session_date,
                     INTERVAL 7 DAY
                 )
                THEN 1
            ELSE 0
        END AS d7_eligible,


        -- D7 exact-day retention
        CASE
            WHEN c.first_session_date <=
                 DATE_SUB(
                     w.max_session_date,
                     INTERVAL 7 DAY
                 )

             AND EXISTS (

                 SELECT 1

                 FROM user_session_dates AS s

                 WHERE s.user_pseudo_id = c.user_pseudo_id

                   AND s.session_date =
                       DATE_ADD(
                           c.first_session_date,
                           INTERVAL 7 DAY
                       )
             )
                THEN 1

            ELSE 0
        END AS d7_retained,


        -- D30 eligibility
        CASE
            WHEN c.first_session_date <=
                 DATE_SUB(
                     w.max_session_date,
                     INTERVAL 30 DAY
                 )
                THEN 1
            ELSE 0
        END AS d30_eligible,


        -- D30 exact-day retention
        CASE
            WHEN c.first_session_date <=
                 DATE_SUB(
                     w.max_session_date,
                     INTERVAL 30 DAY
                 )

             AND EXISTS (

                 SELECT 1

                 FROM user_session_dates AS s

                 WHERE s.user_pseudo_id = c.user_pseudo_id

                   AND s.session_date =
                       DATE_ADD(
                           c.first_session_date,
                           INTERVAL 30 DAY
                       )
             )
                THEN 1

            ELSE 0
        END AS d30_retained

    FROM user_cohorts AS c

    CROSS JOIN analysis_window AS w
),


-- ============================================================
-- 6. AGGREGATE RETENTION BY FIRST-SESSION CHANNEL
-- ============================================================

channel_aggregation AS (

    SELECT
        first_session_channel AS channel_group,

        COUNT(*) AS cohort_size,

        SUM(d7_eligible)
            AS d7_eligible_users,

        SUM(d7_retained)
            AS d7_retained_users,

        SUM(d30_eligible)
            AS d30_eligible_users,

        SUM(d30_retained)
            AS d30_retained_users

    FROM user_retention

    GROUP BY first_session_channel
)


-- ============================================================
-- 7. CALCULATE CHANNEL RETENTION RATES
-- ============================================================

SELECT
    channel_group,

    cohort_size,

    d7_eligible_users,
    d7_retained_users,

    CASE
        WHEN d7_eligible_users = 0
            THEN NULL

        ELSE ROUND(
            SAFE_DIVIDE(
                d7_retained_users,
                d7_eligible_users
            ) * 100,
            2
        )
    END AS d7_retention_rate,

    d30_eligible_users,
    d30_retained_users,

    CASE
        WHEN d30_eligible_users = 0
            THEN NULL

        ELSE ROUND(
            SAFE_DIVIDE(
                d30_retained_users,
                d30_eligible_users
            ) * 100,
            2
        )
    END AS d30_retention_rate

FROM channel_aggregation

ORDER BY cohort_size DESC;
