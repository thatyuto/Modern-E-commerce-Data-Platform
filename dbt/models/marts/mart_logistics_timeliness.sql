/*
  Source: olist_analysis/sql/analysis/timely_wide table.sql
  Purpose: Order-level logistics duration wide table with timeliness grading.
*/

{{ config(materialized='table') }}

with order_time as (
    select
        o.order_id,
        o.customer_id,
        o.order_status,
        o.purchased_at as order_time,
        o.approved_at as pay_time,
        o.delivered_to_carrier_at as ship_time,
        o.delivered_to_customer_at as sign_time,
        o.estimated_delivery_at as expect_sign_time,
        timestamp_diff(o.approved_at, o.purchased_at, second) / 3600.0 as hour_order_to_pay,
        timestamp_diff(o.delivered_to_carrier_at, o.approved_at, second) / 3600.0 as hour_pay_to_ship,
        timestamp_diff(o.delivered_to_customer_at, o.delivered_to_carrier_at, second) / 3600.0 as hour_ship_to_sign,
        timestamp_diff(o.delivered_to_customer_at, o.purchased_at, second) / 3600.0 as hour_total_logistics,
        case when o.approved_at < o.purchased_at then 1 else 0 end as is_abnormal_time_pay,
        case when o.delivered_to_carrier_at < o.approved_at then 1 else 0 end as is_abnormal_time_ship,
        case when o.delivered_to_customer_at < o.delivered_to_carrier_at then 1 else 0 end as is_abnormal_time_sign,
        case when o.delivered_to_customer_at > o.estimated_delivery_at then 1 else 0 end as is_late
    from {{ ref('stg_orders') }} o
    where o.order_status = 'delivered'
),

filtered_orders as (
    select *
    from order_time
    where hour_total_logistics > 0
      and hour_total_logistics < 720
),

quantile_data as (
    select
        approx_quantiles(hour_total_logistics, 4)[offset(1)] as p25_total,
        approx_quantiles(hour_total_logistics, 4)[offset(2)] as p50_total,
        approx_quantiles(hour_total_logistics, 4)[offset(3)] as p75_total,
        approx_quantiles(hour_total_logistics, 10)[offset(9)] as p90_total
    from filtered_orders
)

select
    ot.*,
    qd.p25_total,
    qd.p50_total,
    qd.p75_total,
    qd.p90_total,
    case
        when ot.hour_total_logistics <= qd.p25_total then '极快'
        when ot.hour_total_logistics <= qd.p50_total then '较快'
        when ot.hour_total_logistics <= qd.p75_total then '一般'
        else '较慢'
    end as timely_level
from filtered_orders ot
cross join quantile_data qd
