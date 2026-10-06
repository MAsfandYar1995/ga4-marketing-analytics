/*
GA4 Marketing Analytics Portfolio Project
Dataset: Google Analytics 4 obfuscated sample ecommerce
Analysis window: 2020-11-01 to 2021-01-31
SQL dialect: GoogleSQL (BigQuery)
*/

/*
Purpose:
- Profile events, users and sessions.
- Check key identifier completeness.
- Review session frequency and basic user activity.
*/

SELECT

    event_name,

    COUNT(\*) AS event_count

FROM

    \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\` -- \* is a wildcard that includes all tables beginning with events\_

WHERE

    \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131' -- BigQuery pseudocolumn used to limit the wildcard query to these daily tables

GROUP BY

    event_name

ORDER BY

    event_count DESC;


\-- Profile the overall GA4 dataset and return one row showing:

\-- earliest event date, latest event date

\-- total number of events

\-- total number of distinct users


SELECT

  MIN(PARSE_DATE('%Y%m%d', event_date)) AS earliest_event_date,

  MAX(PARSE_DATE('%Y%m%d', event_date)) AS latest_event_date,

  COUNT(\*) AS total_events,

  COUNT(DISTINCT user_pseudo_id) AS distinct_users

FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131';


\-- Write a separate profiling query that returns:


\-- total events, events with a non-null ga_session_id, events with a null ga_session_id


SELECT

  COUNT(\*) AS total_events,

  SUM(

    CASE

      WHEN (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') IS NOT NULL

        THEN 1

      ELSE 0

    END) AS non_null_ga_session_id_events,

  SUM(

    CASE

      WHEN (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') IS NULL

        THEN 1

      ELSE 0

    END) AS null_ga_session_id_events

FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131';


\-- How many events have a null user_pseudo_id, and how many have a non-null user_pseudo_id?


\-- Return: total events, non-null user_pseudo_id events, null user_pseudo_id events


SELECT

  COUNT(\*) AS total_events,

  SUM(

    CASE

      WHEN user_pseudo_id IS NOT NULL

        THEN 1

      ELSE 0

    END) AS non_null_user_pseudo_id_events,

  SUM(

    CASE

      WHEN user_pseudo_id IS NULL

        THEN 1

      ELSE 0

    END) AS null_user_pseudo_id_events

FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131';


\-- Write a query that returns one row with: total distinct users, total distinct sessions, total events


WITH base AS (


  SELECT

    user_pseudo_id,

    CONCAT(user_pseudo_id, '-', CAST((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING))

      AS ga_user_session_id

  FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

  WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'


)


SELECT

  COUNT(DISTINCT user_pseudo_id) AS total_distinct_users,

  COUNT(DISTINCT ga_user_session_id) AS total_distinct_sessions,

  COUNT(\*) AS total_events

FROM base;


\-- Write a query that returns one row per session with these columns:


\-- user_pseudo_id, your unique session ID, number of events in that session

\-- Then sort it so the sessions with the most events appear first, and show only the top 20.


SELECT

  user_pseudo_id,

  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') As session_id,

  COUNT(\*) AS number_of_events


FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

GROUP BY 1, 2

ORDER BY number_of_events DESC

LIMIT 20;


\-- How many sessions does the average user generate?


\-- Write a query that returns:


\-- total distinct users

\-- total distinct sessions

\-- average sessions per user

\-- minimum sessions per user

\-- maximum sessions per user


WITH users_base AS (


  SELECT

    user_pseudo_id,

    COUNT(DISTINCT (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) AS distinct_sessions

  FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

  WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

  GROUP BY 1


)


SELECT

  COUNT(\*) AS total_distinct_users,

  SUM(distinct_sessions) AS total_distinct_sessions,

  ROUND(AVG(distinct_sessions), 2) AS average_sessions_per_user,

  MIN(distinct_sessions) AS minimum_sessions_per_user,

  MAX(distinct_sessions) AS maximum_sessions_per_user

FROM users_base;


\-- How frequently do users return?


WITH user_sessions_base AS (


  SELECT

    user_pseudo_id,

    COUNT(DISTINCT (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) AS session_count

  FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

  WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

  GROUP BY 1


),

session_frequency AS (


  SELECT

    session_count AS sessions_per_user,

    COUNT(\*) AS number_of_users

  FROM user_sessions_base

  GROUP BY 1


)


SELECT

  sessions_per_user,

  number_of_users,

  ROUND(number_of_users \* 100.0 / SUM(number_of_users) OVER (), 2) AS percentage_of_users

FROM session_frequency

ORDER BY sessions_per_user;


\-- Do users with multiple sessions behave differently commercially from one-session users?


\-- For example, do repeat-session users have:


\-- higher purchase rates?

\-- higher revenue per user?

\-- more purchases?

\-- higher engagement?


\-- How much of website activity comes from first-session users versus returning users?


WITH base AS (


  SELECT

    CONCAT(user_pseudo_id, '-', (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) AS unique_session_id,

    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS ga_session_number,

  FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events\_\*\`

    WHERE \_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'


),

user_type_sessions_breakdown AS (


  SELECT

    CASE

      WHEN ga_session_number = 1 THEN 'New'

      WHEN ga_session_number > 1 THEN 'Returning'

    END AS session_type,

    COUNT(DISTINCT unique_session_id) AS sessions

  FROM base

  GROUP BY 1


)


SELECT

  session_type,

  sessions,
