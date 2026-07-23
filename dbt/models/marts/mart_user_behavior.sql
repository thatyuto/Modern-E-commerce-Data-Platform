/*
  Source: olist_analysis/sql/analysis/user_behavior_table.sql
  Purpose: Customer behavior profile with repurchase interval and lifecycle tags.
*/

{{ config(materialized='table') }}

with dataset_max_date as (
    select max(purchased_at) as max_date
    from {{ ref('stg_orders') }}
),

order_payments as (
    select
        order_id,
        sum(payment_value) as order_payment
    from {{ ref('stg_payments') }}
    group by order_id
),

user_base as (
    select
        c.customer_unique_id,
        min(o.purchased_at) as first_order_at,
        max(o.purchased_at) as last_order_at,
        count(distinct o.order_id) as total_orders,
        coalesce(sum(op.order_payment), 0) as total_spend,
        timestamp_diff(
            (select max_date from dataset_max_date),
            max(o.purchased_at),
            hour
        ) / 24.0 as days_since_last_order
    from {{ ref('stg_orders') }} o
    join {{ ref('stg_customers') }} c on o.customer_id = c.customer_id
    left join order_payments op on o.order_id = op.order_id
    group by c.customer_unique_id
),

order_lag as (
    select
        c.customer_unique_id,
        o.purchased_at,
        lag(o.purchased_at) over (
            partition by c.customer_unique_id
            order by o.purchased_at
        ) as prev_order_at
    from {{ ref('stg_orders') }} o
    join {{ ref('stg_customers') }} c on o.customer_id = c.customer_id
),

user_interval as (
    select
        customer_unique_id,
        round(avg(timestamp_diff(purchased_at, prev_order_at, day)), 1) as avg_order_interval_days
    from order_lag
    where prev_order_at is not null
    group by customer_unique_id
)

select
    ub.customer_unique_id,
    ub.first_order_at,
    ub.last_order_at,
    ub.total_orders,
    round(ub.total_spend, 2) as total_spend,
    round(safe_divide(ub.total_spend, ub.total_orders), 2) as avg_order_value,
    ui.avg_order_interval_days,
    case
        when ub.days_since_last_order <= 30 and ub.total_orders = 1 then '新客'
        when ub.days_since_last_order <= 30 and ub.total_orders >= 2 then '复购'
        when ub.days_since_last_order between 31 and 90 then '沉睡'
        when ub.days_since_last_order > 90 then '流失'
        else '其他'
    end as user_tag
from user_base ub
left join user_interval ui on ub.customer_unique_id = ui.customer_unique_id
