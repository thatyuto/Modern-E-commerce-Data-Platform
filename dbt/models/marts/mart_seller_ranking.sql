/*
  Source: olist_analysis/sql/analysis/The top 10 seller in each city.sql
  Purpose: Rank sellers by GMV within each city, identifying top performers per region.
  Business question: "Who are the top-selling sellers in each city?"
*/

{{ config(materialized='table') }}

with seller_gmv as (
    -- 计算每个卖家在每个城市的总 GMV 和订单数
    select
        s.seller_id,
        s.seller_city,
        s.seller_state,
        count(distinct o.order_id) as order_count,
        sum(o.total_payment_value) as gmv
    from {{ ref('dim_sellers') }} s
    inner join {{ ref('fact_order_items') }} oi on s.seller_id = oi.seller_id
    inner join {{ ref('fact_orders') }} o on oi.order_id = o.order_id
    where o.order_status != 'canceled'
    group by s.seller_id, s.seller_city, s.seller_state
),

-- 在每个城市内按 GMV 排名
seller_ranked as (
    select
        *,
        row_number() over (
            partition by seller_city
            order by gmv desc
        ) as rank_in_city,
        round(gmv * 100.0 / sum(gmv) over (partition by seller_city), 2) as gmv_share_pct
    from seller_gmv
)

select
    seller_city,
    seller_state,
    seller_id,
    order_count,
    round(gmv, 2) as gmv,
    rank_in_city,
    gmv_share_pct
from seller_ranked
where rank_in_city <= 10
order by seller_city, rank_in_city