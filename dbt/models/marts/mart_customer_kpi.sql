/*
  Source: olist_analysis/sql/analysis/calculate the repurchase rate of customers.sql
  Purpose: Platform-level customer KPI snapshot for dashboards.
*/

{{ config(materialized='table') }}

with user_order_counts as (
    select
        c.customer_unique_id,
        count(distinct o.order_id) as order_frequency
    from {{ ref('stg_customers') }} c
    left join {{ ref('stg_orders') }} o on c.customer_id = o.customer_id
    group by c.customer_unique_id
),

aggregated as (
    select
        count(*) as total_customers,
        countif(order_frequency > 1) as repurchasing_customers,
        countif(order_frequency = 1) as one_time_customers,
        countif(order_frequency >= 3) as loyal_customers
    from user_order_counts
)

select
    current_date() as snapshot_date,
    total_customers,
    repurchasing_customers,
    one_time_customers,
    loyal_customers,
    round(safe_divide(repurchasing_customers, total_customers) * 100, 2) as repurchase_rate_pct,
    round(safe_divide(loyal_customers, total_customers) * 100, 2) as loyal_customer_rate_pct
from aggregated
