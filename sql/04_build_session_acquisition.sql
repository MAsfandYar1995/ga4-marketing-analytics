/*
GA4 Marketing Analytics Portfolio Project
Dataset: Google Analytics 4 obfuscated sample ecommerce
Analysis window: 2020-11-01 to 2021-01-31
SQL dialect: GoogleSQL (BigQuery)
*/

/*
Purpose:
Build one row per session containing the session identifier, user identifier,
ga_session_number and the earliest usable source / medium / campaign values.

Expected output table used later in the project:
ga4_analysis.session_acquisition
*/

event_medium,

    event_campaign

  FROM events_ranked

  WHERE event_rn = 1


),


all_sessions AS (


  SELECT

    unique_session_id,

    user_pseudo_id,

    ga_session_id,

    ga_session_number,

    MIN(event_timestamp) AS earliest_event_timestamp

  FROM events_base

  GROUP BY 1, 2, 3, 4


)


  SELECT

    s.unique_session_id,

    s.user_pseudo_id,

    s.ga_session_id,

    s.ga_session_number,

    s.earliest_event_timestamp,

    ts.first_traffic_event_timestamp,

    ts.event_source AS session_source,

    ts.event_medium AS session_medium,

    ts.event_campaign AS session_campaign

  FROM all_sessions s

  LEFT JOIN final_traffic_sessions ts

    ON s.unique_session_id = ts.unique_session_id;


\-- Include: unique_session_id, user_pseudo_id, ga_session_number, first traffic-event timestamp, session_source, session_medium, session_campaign


\-- Which acquisition sources are bringing the highest-quality traffic?

SELECT

  \*

FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101\`
