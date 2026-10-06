/*
GA4 Marketing Analytics Portfolio Project
Reconstructed query based on the validated project logic used in Power BI.

Purpose:
Measure exact-day D7 and D30 retention by the acquisition channel attached to the
user's first observed session (ga_session_number = 1).

The cohort-entry and eligibility logic is intentionally identical to the weekly
cohort query so the grand totals reconcile between both tables.

Expected validated totals across all channels:
- cohort_users: 261148
- d7_eligible_users: 241888
- d7_retained_users: 1656
- d30_eligible_users: 172874
- d30_retained_users: 234
*/

CREATE OR REPLACE TABLE `ga4-marketing-analysis-509418.ga4_analysis.channel_retention` AS

WITH dataset_max AS (
  SELECT MAX(session_date) AS max_session_date
  FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final`
),

first_session_candidates AS (
  SELECT
    user_pseudo_id,
    unique_session_id,
    session_timestamp,
    session_date,
    channel_group,
    ROW_NUMBER() OVER (
      PARTITION BY user_pseudo_id
      ORDER BY session_timestamp, unique_session_id
    ) AS rn
  FROM `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final`
  WHERE ga_session_number = 1
    AND user_pseudo_id IS NOT NULL
),

cohort_base AS (
  SELECT
    user_pseudo_id,
    session_date AS day_0,
    COALESCE(channel_group, 'Unattributed') AS channel_group
  FROM first_session_candidates
  WHERE rn = 1
),

user_retention AS (
  SELECT
    cb.user_pseudo_id,
    cb.day_0,
    cb.channel_group,
    dm.max_session_date,
    MAX(CASE
      WHEN s.session_date = DATE_ADD(cb.day_0, INTERVAL 7 DAY) THEN 1
      ELSE 0
    END) AS d7_retained_flag,
    MAX(CASE
      WHEN s.session_date = DATE_ADD(cb.day_0, INTERVAL 30 DAY) THEN 1
      ELSE 0
    END) AS d30_retained_flag
  FROM cohort_base cb
  CROSS JOIN dataset_max dm
  LEFT JOIN `ga4-marketing-analysis-509418.ga4_analysis.session_marketing_performance_final` s
    ON cb.user_pseudo_id = s.user_pseudo_id
  GROUP BY
    cb.user_pseudo_id,
    cb.day_0,
    cb.channel_group,
    dm.max_session_date
)

SELECT
  channel_group,
  COUNT(*) AS cohort_size,
  COUNTIF(DATE_ADD(day_0, INTERVAL 7 DAY) <= max_session_date) AS d7_eligible_users,
  COUNTIF(
    DATE_ADD(day_0, INTERVAL 7 DAY) <= max_session_date
    AND d7_retained_flag = 1
  ) AS d7_retained_users,
  SAFE_DIVIDE(
    COUNTIF(
      DATE_ADD(day_0, INTERVAL 7 DAY) <= max_session_date
      AND d7_retained_flag = 1
    ),
    COUNTIF(DATE_ADD(day_0, INTERVAL 7 DAY) <= max_session_date)
  ) AS d7_retention_rate,
  COUNTIF(DATE_ADD(day_0, INTERVAL 30 DAY) <= max_session_date) AS d30_eligible_users,
  COUNTIF(
    DATE_ADD(day_0, INTERVAL 30 DAY) <= max_session_date
    AND d30_retained_flag = 1
  ) AS d30_retained_users,
  SAFE_DIVIDE(
    COUNTIF(
      DATE_ADD(day_0, INTERVAL 30 DAY) <= max_session_date
      AND d30_retained_flag = 1
    ),
    COUNTIF(DATE_ADD(day_0, INTERVAL 30 DAY) <= max_session_date)
  ) AS d30_retention_rate
FROM user_retention
GROUP BY channel_group
ORDER BY cohort_size DESC;
