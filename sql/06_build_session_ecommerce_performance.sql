/*
GA4 Marketing Analytics Portfolio Project
Dataset: Google Analytics 4 obfuscated sample ecommerce
Analysis window: 2020-11-01 to 2021-01-31
SQL dialect: GoogleSQL (BigQuery)
*/

/*
Purpose:
Build one row per session with ecommerce funnel flags and session revenue.

Expected output table used later in the project:
ga4_analysis.session_ecommerce_performance
*/

WHEN sa.session_source = '(direct)' AND sa.session_medium = '(none)' THEN 'Direct'

      WHEN sa.session_medium = 'organic' THEN 'Organic Search'

      WHEN sa.session_medium = 'cpc' THEN 'Paid Search'

      WHEN sa.session_medium = 'email' THEN 'Email'

      WHEN sa.session_medium = 'affiliate' THEN 'Affiliate'

      WHEN sa.session_medium = 'referral' THEN 'Referral'

      WHEN sa.session_medium IN ('(data deleted)', '\<Other>') THEN 'Data Unavailable'

      ELSE 'Other'

    END AS channel_group,


  se.view_item_flag,

  se.add_to_cart_flag,

  se.begin_checkout_flag,

  se.add_shipping_info_flag,

  se.add_payment_info_flag,

  se.purchase_flag,
