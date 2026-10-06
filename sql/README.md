# Reconstructed GA4 Retention SQL

The original SQL used to build the project's retention tables was no longer available. These queries were reconstructed from the documented project logic and the previously validated output totals.

## Files

- `12_weekly_cohort_retention.sql` creates `ga4_analysis.cohort_weekly_retention`.
- `13_channel_retention.sql` creates `ga4_analysis.channel_retention`.
- `14_retention_validation.sql` verifies duplicate first-session handling and reconciles both retention outputs.

## Retention definition

Retention is exact-day retention, not cumulative retention:

- D7 retained: a user has a session exactly 7 days after their cohort-entry date.
- D30 retained: a user has a session exactly 30 days after their cohort-entry date.
- A user is only eligible when the dataset extends far enough beyond their cohort-entry date to observe the target day.

## Cohort entry

The cohort date comes from the earliest session where `ga_session_number = 1`. The project previously identified 89 users with more than one such row, so `ROW_NUMBER()` is used to retain a single first-session record per user.

## Expected validation totals

Both output tables should reconcile to:

| Metric | Expected |
|---|---:|
| Cohort users | 261,148 |
| D7 eligible users | 241,888 |
| D7 retained users | 1,656 |
| D30 eligible users | 172,874 |
| D30 retained users | 234 |

Run `14_retention_validation.sql` after creating both tables. If the totals do not match, do not silently adjust the query. Investigate the difference against the current `session_marketing_performance_final` table.
