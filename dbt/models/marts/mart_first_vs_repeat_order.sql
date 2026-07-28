/*
  Source: olist_analysis/sql/analysis/Comparison of the amount of the first order and the repurchase order.sql
  Purpose: Compare first-order vs repeat-order customer spending behavior.
  Business question: "Do repeat customers spend more per order than new customers?"
*/

{{ config(materialized='table') }}

with customer_first_order as (
    -- 找出每个客户的第一笔交易时间
    select
        c.customer_unique_id,
        min(o.purchased_at) as first_order_time
    from {{ ref('fact_orders') }} o
    inner join {{ ref('stg_customers') }} c on o.customer_id = c.customer_id
    where o.order_status = 'delivered'
    group by c.customer_unique_id
),

order_labeled as (
    -- 给每笔订单打标：首次 or 复购
    select
        o.order_id,
        c.customer_unique_id,
        o.purchased_at,
        o.total_payment_value,
        case
            when o.purchased_at = fo.first_order_time then 'first_order'
            else 'repeat_order'
        end as order_type
    from {{ ref('fact_orders') }} o
    inner join {{ ref('stg_customers') }} c on o.customer_id = c.customer_id
    inner join customer_first_order fo on c.customer_unique_id = fo.customer_unique_id
    where o.order_status = 'delivered'
),

-- 首单 vs 复购 金额对比
order_type_summary as (
    select
        order_type,
        count(distinct order_id) as order_count,
        sum(total_payment_value) as total_revenue,
        round(avg(total_payment_value), 2) as avg_order_value
    from order_labeled
    group by order_type
),

-- 复购率：有多少客户至少下单两次
repurchase_metrics as (
    select
        count(distinct customer_unique_id) as total_customers,
        count(distinct case when order_count >= 2 then customer_unique_id end) as repeat_customers
    from (
        select
            customer_unique_id,
            count(distinct order_id) as order_count
        from order_labeled
        group by customer_unique_id
    )
)

select
    'order_summary' as metric_type,
    order_type as label,
    order_count,
    total_revenue,
    avg_order_value,
    null as repurchase_rate
from order_type_summary

union all

select
    'repurchase_rate' as metric_type,
    'overall' as label,
    total_customers as order_count,
    null as total_revenue,
    null as avg_order_value,
    round(repeat_customers * 100.0 / total_customers, 2) as repurchase_rate
from repurchase_metrics

order by metric_type, label