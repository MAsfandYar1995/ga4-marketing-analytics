/*
GA4 Marketing Analytics Portfolio Project
Retention validation checks.

These checks are included because the original retention-build queries were lost.
The reconstructed queries should be accepted only after their outputs reproduce the
previously validated project totals.
*/

-- 1. Check how many users have more than one session marked ga_session_number = 1.
-- Previous project validation found 89 such users, which is why the build queries
-- use ROW_NUMBER() to select one cohort-entry session per user.
WITH first_session_counts AS (
  SELECT
    user_pseudo_id,
    COUNT(*) AS first_session_rows
  FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final`
  WHERE ga_session_number = 1
    AND user_pseudo_id IS NOT NULL
  GROUP BY user_pseudo_id
)
SELECT
  COUNTIF(first_session_rows > 1) AS users_with_duplicate_first_sessions
FROM first_session_counts;


-- 2. Validate weekly cohort totals.
SELECT
  SUM(cohort_size) AS cohort_users,
  SUM(d7_eligible_users) AS d7_eligible_users,
  SUM(d7_retained_users) AS d7_retained_users,
  SUM(d30_eligible_users) AS d30_eligible_users,
  SUM(d30_retained_users) AS d30_retained_users
FROM `ga4-marketing-analysis-509418.ga4_analysis.cohort_weekly_retention`;

-- Expected:
-- cohort_users = 261148
-- d7_eligible_users = 241888
-- d7_retained_users = 1656
-- d30_eligible_users = 172874
-- d30_retained_users = 234


-- 3. Validate channel retention totals.
SELECT
  SUM(cohort_size) AS cohort_users,
  SUM(d7_eligible_users) AS d7_eligible_users,
  SUM(d7_retained_users) AS d7_retained_users,
  SUM(d30_eligible_users) AS d30_eligible_users,
  SUM(d30_retained_users) AS d30_retained_users
FROM `ga4-marketing-analysis-509418.ga4_analysis.channel_retention`;

-- Expected: same values as the weekly cohort table.


-- 4. Direct reconciliation between the two output tables.
WITH weekly AS (
  SELECT
    SUM(cohort_size) AS cohort_users,
    SUM(d7_eligible_users) AS d7_eligible_users,
    SUM(d7_retained_users) AS d7_retained_users,
    SUM(d30_eligible_users) AS d30_eligible_users,
    SUM(d30_retained_users) AS d30_retained_users
  FROM `ga4-marketing-analysis-509418.ga4_analysis.cohort_weekly_retention`
),
channel AS (
  SELECT
    SUM(cohort_size) AS cohort_users,
    SUM(d7_eligible_users) AS d7_eligible_users,
    SUM(d7_retained_users) AS d7_retained_users,
    SUM(d30_eligible_users) AS d30_eligible_users,
    SUM(d30_retained_users) AS d30_retained_users
  FROM `ga4-marketing-analysis-509418.ga4_analysis.channel_retention`
)
SELECT
  weekly.cohort_users = channel.cohort_users AS cohort_users_match,
  weekly.d7_eligible_users = channel.d7_eligible_users AS d7_eligible_match,
  weekly.d7_retained_users = channel.d7_retained_users AS d7_retained_match,
  weekly.d30_eligible_users = channel.d30_eligible_users AS d30_eligible_match,
  weekly.d30_retained_users = channel.d30_retained_users AS d30_retained_match
FROM weekly
CROSS JOIN channel;
