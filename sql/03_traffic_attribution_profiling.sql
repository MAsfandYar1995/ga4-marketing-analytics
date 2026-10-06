/*
GA4 Marketing Analytics Portfolio Project
Dataset: Google Analytics 4 obfuscated sample ecommerce
Analysis window: 2020-11-01 to 2021-01-31
SQL dialect: GoogleSQL (BigQuery)
*/

/*
Purpose:
- Profile source, medium and campaign fields.
- Assess traffic-parameter completeness.
- Test first non-null session attribution logic.
*/

FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131';

\-- organic, (none), \<Other>, referral, (data deleted), cpc


SELECT

  DISTINCT traffic_source.source AS source

FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131';

\-- google, (direct), \<Other>, (data deleted), shop.googlemerchandisestore.com


SELECT

  DISTINCT traffic_source.name AS name

FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131';

\-- (organic), (direct), \<other>, (referral), (data deleted)


SELECT

  DISTINCT (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source') AS source

FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131';


\-- 242 sources


SELECT

  DISTINCT ep.value.string_value

FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`,

UNNEST(event_params) AS ep

WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

AND key = 'campaign';


\-- 12 campaigns


SELECT

  DISTINCT ep.value.string_value

FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`,

UNNEST(event_params) AS ep

WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

AND key = 'medium';


\-- referral, \<Other>, organic, (none), cpc, (data deleted), affiliate, email, (none)


\-- For each event_name, return: total number of events, number of events where source is non-null, number where medium is non-null

\-- number where campaign is non-null, percentage of events with a non-null source


WITH events_base AS (


  SELECT

    event_name,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source') AS event_source,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign') AS event_campaign,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium') AS event_medium

  FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

  WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'


)


SELECT

  event_name,

  COUNT(\*) AS total_events,

  SUM(CASE WHEN event_source IS NOT NULL THEN 1 ELSE 0 END) AS non_null_source_events,

  SUM(CASE WHEN event_medium IS NOT NULL THEN 1 ELSE 0 END) AS non_null_medium_events,

  SUM(CASE WHEN event_campaign IS NOT NULL THEN 1 ELSE 0 END) AS non_null_campaign_events,

  ROUND(SUM(CASE WHEN event_source IS NOT NULL THEN 1 ELSE 0 END) \* 100.0 / COUNT(\*), 2) AS non_null_source_events_pct

FROM events_base

GROUP BY 1;


\-- What is the first non-null source/medium/campaign observed within each session?


\-- For every unique session, return:

\-- unique_session_id, the earliest timestamp in the session

\-- the first non-null source, the first non-null medium, the first non-null campaign


WITH events_base AS (


  SELECT

    CONCAT(user_pseudo_id, '-', (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) AS unique_session_id,

    event_timestamp,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium') AS event_medium,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source') AS event_source,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign') AS event_campaign

  FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

  WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'


),

event_first_values AS (


  SELECT

    unique_session_id,

    event_timestamp,

    FIRST_VALUE(event_medium IGNORE NULLS)

      OVER (

        PARTITION BY unique_session_id ORDER BY event_timestamp

        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

    ) AS first_value_non_null_medium,

    FIRST_VALUE(event_source IGNORE NULLS)

      OVER (

        PARTITION BY unique_session_id ORDER BY event_timestamp

        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

    ) AS first_value_non_null_source,

    FIRST_VALUE(event_campaign IGNORE NULLS)

      OVER (

        PARTITION BY unique_session_id ORDER BY event_timestamp

        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

    ) AS first_value_non_null_campaign


  FROM events_base

)


SELECT

  unique_session_id,

  MIN(event_timestamp) AS earliest_timestamp,

  MIN(first_value_non_null_medium) AS first_non_null_medium,

  MIN(first_value_non_null_source) AS first_non_null_source,

  MIN(first_value_non_null_campaign) AS first_non_null_campaign

FROM event_first_values

GROUP BY 1;


\-- How many sessions have a derived source, medium and campaign, and how many are still null after this derivation?


\-- Return one row containing: total sessions, sessions with non-null source, sessions with null source, sessions with non-null medium

\-- sessions with null medium, sessions with non-null campaign, sessions with null campaign


WITH events_base AS (


  SELECT

    CONCAT(user_pseudo_id, '-', (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) AS unique_session_id,

    event_timestamp,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium') AS event_medium,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source') AS event_source,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign') AS event_campaign

  FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

  WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'


),

event_first_values AS (


  SELECT

    unique_session_id,

    event_timestamp,

    FIRST_VALUE(event_medium IGNORE NULLS)

      OVER (

        PARTITION BY unique_session_id ORDER BY event_timestamp

        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

    ) AS first_value_non_null_medium,

    FIRST_VALUE(event_source IGNORE NULLS)

      OVER (

        PARTITION BY unique_session_id ORDER BY event_timestamp

        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

    ) AS first_value_non_null_source,

    FIRST_VALUE(event_campaign IGNORE NULLS)

      OVER (

        PARTITION BY unique_session_id ORDER BY event_timestamp

        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

    ) AS first_value_non_null_campaign


  FROM events_base

),


session_aggregation AS (


  SELECT

    unique_session_id,

    MIN(event_timestamp) AS earliest_timestamp,

    MIN(first_value_non_null_medium) AS first_non_null_medium,

    MIN(first_value_non_null_source) AS first_non_null_source,

    MIN(first_value_non_null_campaign) AS first_non_null_campaign

  FROM event_first_values

  GROUP BY 1


)


SELECT

  COUNT(\*) AS total_sessions,

  COUNT(CASE WHEN first_non_null_medium IS NOT NULL THEN unique_session_id END) AS sessions_with_non_null_medium,

  COUNT(CASE WHEN first_non_null_medium IS NULL THEN unique_session_id END) AS sessions_with_null_medium,


  COUNT(CASE WHEN first_non_null_source IS NOT NULL THEN unique_session_id END) AS sessions_with_non_null_source,

  COUNT(CASE WHEN first_non_null_source IS NULL THEN unique_session_id END) AS sessions_with_null_source,


  COUNT(CASE WHEN first_non_null_campaign IS NOT NULL THEN unique_session_id END) AS sessions_with_non_null_campaign,

  COUNT(CASE WHEN first_non_null_campaign IS NULL THEN unique_session_id END) AS sessions_with_null_campaign

FROM session_aggregation;


\-- When traffic information appears on an event, do source, medium and campaign usually appear together?

\-- For the event-level data, count:


\-- events where source is non-null, events where medium is non-null, events where campaign is non-null, events where all three are non-null

\-- events where source is non-null but medium is null, events where source is non-null but campaign is null

\-- events where medium is non-null but source is null


\-- Return just one row.


WITH events_base AS (


  SELECT

    CONCAT(user_pseudo_id, '-', (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) AS unique_session_id,

    event_timestamp,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium') AS event_medium,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source') AS event_source,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign') AS event_campaign

  FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

  WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'


)


SELECT

  COUNT(CASE WHEN event_medium IS NOT NULL THEN unique_session_id END) AS non_null_medium_events,

  COUNT(CASE WHEN event_source IS NOT NULL THEN unique_session_id END) AS non_null_source_events,

  COUNT(CASE WHEN event_campaign IS NOT NULL THEN unique_session_id END) AS non_null_campaign_events,

  COUNT(CASE WHEN event_campaign IS NOT NULL AND event_source IS NOT NULL AND

    event_medium IS NOT NULL THEN unique_session_id END) AS non_null_medium_source_campaign_events,


  COUNT(CASE WHEN event_source IS NOT NULL AND event_medium IS NULL THEN unique_session_id END) AS non_null_source_null_medium_events,

  COUNT(CASE WHEN event_source IS NOT NULL AND event_campaign IS NULL THEN unique_session_id END) AS non_null_source_null_campaign_events,

  COUNT(CASE WHEN event_medium IS NOT NULL AND event_source IS NULL THEN unique_session_id END) AS non_null_medium_null_source_events,

  COUNT(CASE WHEN event_medium IS NOT NULL AND event_campaign IS NULL THEN unique_session_id END) AS non_null_medium_null_campaign_events,

  COUNT(CASE WHEN event_campaign IS NOT NULL AND event_source IS NULL THEN unique_session_id END) AS non_null_campaign_null_source_events,

  COUNT(CASE WHEN event_campaign IS NOT NULL AND event_medium IS NULL THEN unique_session_id END) AS non_null_campaign_null_medium_events


FROM events_base;


\-- Build one row per session containing:


\-- unique_session_id, earliest session timestamp, source from the first event in the session where at least one traffic field is present

\-- medium from that same event, campaign from that same event


WITH events_base AS (


  SELECT

    CONCAT(user_pseudo_id, '-', (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) AS unique_session_id,

    user_pseudo_id,

    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,

    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS ga_session_number,

    event_timestamp,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source') AS event_source,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium') AS event_medium,

    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign') AS event_campaign

  FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

  WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'


),

events_ranked AS (


  SELECT

    unique_session_id,

    event_timestamp,

    event_source,

    event_medium,

    event_campaign,

    ROW_NUMBER() OVER (PARTITION BY unique_session_id ORDER BY event_timestamp) AS event_rn

  FROM events_base

  WHERE event_source IS NOT NULL AND event_medium IS NOT NULL


),


final_traffic_sessions AS (


  SELECT

    unique_session_id,
