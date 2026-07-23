/*
  Source: olist_analysis/sql/mart/mart_daily_business_trend.sql
          olist_analysis/sql/analysis/order and gmv weekly growth percent.sql
  Purpose: Daily GMV & order volume with day/week growth rates and anomaly flags.
*/

{{ config(materialized='table') }}

with daily_base as (
    select
        date(purchased_at) as order_date,
        count(distinct order_id) as order_quantity,
        sum(total_payment_value) as gmv
    from {{ ref('fact_orders') }}
    where order_status != 'canceled'
    group by 1
),

daily_lag as (
    select
        *,
        lag(order_quantity) over (order by order_date) as yesterday_qty,
        lag(gmv) over (order by order_date) as yesterday_gmv,
        lag(order_quantity, 7) over (order by order_date) as lastweek_qty,
        lag(gmv, 7) over (order by order_date) as lastweek_gmv
    from daily_base
),

growth_metrics as (
    select
        *,
        round(safe_divide(order_quantity - yesterday_qty, yesterday_qty) * 100, 2) as qty_growth_pct,
        round(safe_divide(gmv - yesterday_gmv, yesterday_gmv) * 100, 2) as gmv_growth_pct,
        round(safe_divide(order_quantity - lastweek_qty, lastweek_qty) * 100, 2) as qty_weekly_growth_pct,
        round(safe_divide(gmv - lastweek_gmv, lastweek_gmv) * 100, 2) as gmv_weekly_growth_pct
    from daily_lag
),

moving_stats as (
    select
        *,
        avg(qty_growth_pct) over (
            order by order_date rows between 30 preceding and 1 preceding
        ) as avg_growth_30d,
        stddev(qty_growth_pct) over (
            order by order_date rows between 30 preceding and 1 preceding
        ) as std_growth_30d
    from growth_metrics
)

select
    order_date,
    order_quantity,
    gmv,
    qty_growth_pct,
    gmv_growth_pct,
    qty_weekly_growth_pct,
    gmv_weekly_growth_pct,
    case
        when abs(qty_growth_pct) > (avg_growth_30d + 3 * coalesce(std_growth_30d, 0))
            and abs(order_quantity - yesterday_qty) > 10 then 'CRITICAL'
        when abs(qty_growth_pct) > (avg_growth_30d + 2 * coalesce(std_growth_30d, 0)) then 'WARNING'
        else 'NORMAL'
    end as anomaly_status
from moving_stats
