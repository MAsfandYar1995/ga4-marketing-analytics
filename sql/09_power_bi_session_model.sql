/*
GA4 Marketing Analytics Portfolio Project
Dataset: Google Analytics 4 obfuscated sample ecommerce
Analysis window: 2020-11-01 to 2021-01-31
SQL dialect: GoogleSQL (BigQuery)
*/

/*
Purpose:
Add Power BI-friendly timestamp/date fields and a New / Returning session_type.

IMPORTANT:
The supplied project SQL ends with `WHERE session_type IS NULL`. That filter is kept
below exactly as supplied. Because the dashboard uses New and Returning sessions,
verify whether your final production query used `IS NOT NULL` or no filter before
publishing/rerunning this model.
*/


