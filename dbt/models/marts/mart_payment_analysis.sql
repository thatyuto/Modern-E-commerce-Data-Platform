
/*
  Source: olist_analysis/sql/analysis/query_aggregate_payment_type_count.sql
  Purpose: Payment method distribution, installment preferences, and AOV by payment type.
  Business question: "How do customers pay? Which payment methods drive the highest order value?"
*/

{{ config(materialized='table') }}

with payment_detail as (
    select
        p.order_id,
        p.payment_type,
        p.payment_installments,
        p.payment_value
    from {{ ref('dim_payments') }} p
    inner join {{ ref('fact_orders') }} o on p.order_id = o.order_id
    where o.order_status != 'canceled'
),

-- 支付方式维度：每种支付方式的订单数、总金额、客单价
payment_type_metrics as (
    select
        payment_type,
        count(distinct order_id) as order_count,
        sum(payment_value) as total_revenue,
        round(avg(payment_value), 2) as avg_order_value,
        round(count(distinct order_id) * 100.0 / sum(count(distinct order_id)) over(), 1) as order_pct
    from payment_detail
    group by payment_type
),

-- 分期维度：分期数的分布
installment_metrics as (
    select
        payment_installments,
        count(distinct order_id) as order_count,
        round(avg(payment_value), 2) as avg_order_value
    from payment_detail
    group by payment_installments
)

select
    'payment_type' as metric_type,
    payment_type as label,
    order_count,
    total_revenue,
    avg_order_value,
    order_pct
from payment_type_metrics

union all

select
    'installment_count' as metric_type,
    cast(payment_installments as string) as label,
    order_count,
    null as total_revenue,
    avg_order_value,
    null as order_pct
from installment_metrics
order by metric_type, order_count desc