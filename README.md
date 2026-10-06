# GA4 Marketing Analytics SQL

This folder contains the cleaned and organised SQL supplied for the GA4 marketing analytics portfolio project.

## Recommended run / reading order

1. `01_data_profiling.sql` - event, user and session profiling.
2. `02_new_vs_returning_behavior.sql` - New vs Returning session and funnel analysis.
3. `03_traffic_attribution_profiling.sql` - source / medium / campaign exploration and attribution checks.
4. `04_build_session_acquisition.sql` - session-level acquisition model.
5. `05_acquisition_channel_analysis.sql` - source / medium and channel grouping analysis.
6. `06_build_session_ecommerce_performance.sql` - session-level funnel flags and revenue.
7. `07_build_session_marketing_performance.sql` - acquisition + ecommerce session model.
8. `08_channel_campaign_performance.sql` - channel, source / medium and campaign performance.
9. `09_power_bi_session_model.sql` - Power BI-friendly date fields and session type.
10. `10_user_purchase_frequency.sql` - purchaser frequency table used for repeat-purchase analysis.
11. `11_validation_checks.sql` - supporting validation queries.

## Important notes

- The original source included one duplicate SQL paste; it was deduplicated.
- Scratch / one-off exploratory queries that did not contribute meaningfully to the final analysis were omitted.
- The project used exact-day D7/D30 cohort retention in Power BI, but the SQL that created the weekly and channel retention tables was not present in the supplied SQL files, so no retention SQL has been invented here.
- `09_power_bi_session_model.sql` preserves the supplied final `WHERE session_type IS NULL` condition and flags it for verification because it appears inconsistent with the finished dashboard's New vs Returning analysis.
- These files contain query logic, not `CREATE OR REPLACE TABLE` wrappers, unless such wrappers were present in the supplied SQL.
