/*
Analysis: Retention Validation

Purpose:
Validate the weekly cohort and channel retention models and confirm
that both produce consistent overall D7 and D30 retention totals.

Validation checks include:
- Overall totals from weekly cohort retention
- Overall totals from channel retention
- Comparison of both models
- Overall D7 and D30 retention rates
- Retention counts by channel
- Retention counts by weekly cohort

Expected project-level totals:
- Cohort users: 261,148
- D7 eligible users: 241,888
- D7 retained users: 1,656
- D30 eligible users: 172,874
- D30 retained users: 234
*/


-- ============================================================
-- 1. VALIDATE WEEKLY COHORT RETENTION TOTALS
-- ============================================================

SELECT
    SUM(cohort_size)
        AS cohort_users,

    SUM(d7_eligible_users)
        AS d7_eligible_users,

    SUM(d7_retained_users)
        AS d7_retained_users,

    ROUND(
        SAFE_DIVIDE(
            SUM(d7_retained_users),
            SUM(d7_eligible_users)
        ) * 100,
        2
    ) AS overall_d7_retention_rate,

    SUM(d30_eligible_users)
        AS d30_eligible_users,

    SUM(d30_retained_users)
        AS d30_retained_users,

    ROUND(
        SAFE_DIVIDE(
            SUM(d30_retained_users),
            SUM(d30_eligible_users)
        ) * 100,
        2
    ) AS overall_d30_retention_rate

FROM
    `ga4-marketing-analysis-509418.ga4_analysis.cohort_weekly_retention`;



-- ============================================================
-- 2. VALIDATE CHANNEL RETENTION TOTALS
-- ============================================================

SELECT
    SUM(cohort_size)
        AS cohort_users,

    SUM(d7_eligible_users)
        AS d7_eligible_users,

    SUM(d7_retained_users)
        AS d7_retained_users,

    ROUND(
        SAFE_DIVIDE(
            SUM(d7_retained_users),
            SUM(d7_eligible_users)
        ) * 100,
        2
    ) AS overall_d7_retention_rate,

    SUM(d30_eligible_users)
        AS d30_eligible_users,

    SUM(d30_retained_users)
        AS d30_retained_users,

    ROUND(
        SAFE_DIVIDE(
            SUM(d30_retained_users),
            SUM(d30_eligible_users)
        ) * 100,
        2
    ) AS overall_d30_retention_rate

FROM
    `ga4-marketing-analysis-509418.ga4_analysis.channel_retention`;



-- ============================================================
-- 3. COMPARE WEEKLY AND CHANNEL RETENTION MODELS
-- ============================================================
-- Both models are built from the same user-level retention logic,
-- so their overall totals should match.

WITH weekly_totals AS (

    SELECT
        SUM(cohort_size) AS cohort_users,
        SUM(d7_eligible_users) AS d7_eligible_users,
        SUM(d7_retained_users) AS d7_retained_users,
        SUM(d30_eligible_users) AS d30_eligible_users,
        SUM(d30_retained_users) AS d30_retained_users

    FROM
        `ga4-marketing-analysis-509418.ga4_analysis.cohort_weekly_retention`
),

channel_totals AS (

    SELECT
        SUM(cohort_size) AS cohort_users,
        SUM(d7_eligible_users) AS d7_eligible_users,
        SUM(d7_retained_users) AS d7_retained_users,
        SUM(d30_eligible_users) AS d30_eligible_users,
        SUM(d30_retained_users) AS d30_retained_users

    FROM
        `ga4-marketing-analysis-509418.ga4_analysis.channel_retention`
)

SELECT
    w.cohort_users
        AS weekly_cohort_users,

    c.cohort_users
        AS channel_cohort_users,

    w.cohort_users = c.cohort_users
        AS cohort_users_match,

    w.d7_eligible_users
        AS weekly_d7_eligible,

    c.d7_eligible_users
        AS channel_d7_eligible,

    w.d7_eligible_users = c.d7_eligible_users
        AS d7_eligible_match,

    w.d7_retained_users
        AS weekly_d7_retained,

    c.d7_retained_users
        AS channel_d7_retained,

    w.d7_retained_users = c.d7_retained_users
        AS d7_retained_match,

    w.d30_eligible_users
        AS weekly_d30_eligible,

    c.d30_eligible_users
        AS channel_d30_eligible,

    w.d30_eligible_users = c.d30_eligible_users
        AS d30_eligible_match,

    w.d30_retained_users
        AS weekly_d30_retained,

    c.d30_retained_users
        AS channel_d30_retained,

    w.d30_retained_users = c.d30_retained_users
        AS d30_retained_match

FROM weekly_totals AS w

CROSS JOIN channel_totals AS c;



-- ============================================================
-- 4. VALIDATE CHANNEL RETENTION RESULTS
-- ============================================================
-- Review eligible and retained-user counts alongside rates.
-- Small eligible populations should be interpreted cautiously.

SELECT
    channel_group,
    cohort_size,

    d7_eligible_users,
    d7_retained_users,
    d7_retention_rate,

    d30_eligible_users,
    d30_retained_users,
    d30_retention_rate

FROM
    `ga4-marketing-analysis-509418.ga4_analysis.channel_retention`

ORDER BY
    d7_retention_rate DESC;



-- ============================================================
-- 5. VALIDATE WEEKLY COHORT RETENTION RESULTS
-- ============================================================

SELECT
    cohort_week,
    cohort_size,

    d7_eligible_users,
    d7_retained_users,
    d7_retention_rate,

    d30_eligible_users,
    d30_retained_users,
    d30_retention_rate

FROM
    `ga4-marketing-analysis-509418.ga4_analysis.cohort_weekly_retention`

ORDER BY cohort_week;



-- ============================================================
-- 6. CHECK FOR IMPOSSIBLE RETENTION COUNTS
-- ============================================================
-- Retained users should never exceed eligible users.

SELECT
    'Weekly Cohort' AS model,
    COUNT(*) AS invalid_rows

FROM
    `ga4-marketing-analysis-509418.ga4_analysis.cohort_weekly_retention`

WHERE d7_retained_users > d7_eligible_users
   OR d30_retained_users > d30_eligible_users

UNION ALL

SELECT
    'Channel Retention',
    COUNT(*)

FROM
    `ga4-marketing-analysis-509418.ga4_analysis.channel_retention`

WHERE d7_retained_users > d7_eligible_users
   OR d30_retained_users > d30_eligible_users;



-- ============================================================
-- 7. CHECK LATE COHORT ELIGIBILITY
-- ============================================================
-- Later cohorts should naturally have fewer eligible users,
-- particularly for D30, because the observation window ends
-- on 2021-01-31.

SELECT
    cohort_week,
    cohort_size,
    d7_eligible_users,
    d30_eligible_users,

    ROUND(
        SAFE_DIVIDE(
            d7_eligible_users,
            cohort_size
        ) * 100,
        2
    ) AS d7_eligibility_pct,

    ROUND(
        SAFE_DIVIDE(
            d30_eligible_users,
            cohort_size
        ) * 100,
        2
    ) AS d30_eligibility_pct

FROM
    `ga4-marketing-analysis-509418.ga4_analysis.cohort_weekly_retention`

ORDER BY cohort_week;
