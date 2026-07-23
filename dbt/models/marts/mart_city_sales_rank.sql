/*
  Source: olist_analysis/sql/analysis/city-level data dimension analysis.sql
          olist_analysis/sql/analysis/Top 10 cities by sales volume.sql
  Purpose: City-level order volume and GMV ranking for regional analysis.
*/

{{ config(materialized='table') }}

with city_metrics as (
    select
        c.customer_city as city,
        c.customer_state as state,
        count(distinct c.customer_id) as customer_count,
        count(distinct f.order_id) as order_count,
        coalesce(sum(f.total_payment_value), 0) as gmv
    from {{ ref('stg_customers') }} c
    inner join {{ ref('fact_orders') }} f on c.customer_id = f.customer_id
    where f.order_status != 'canceled'
    group by c.customer_city, c.customer_state
)

select
    city,
    state,
    customer_count,
    order_count,
    round(gmv, 2) as gmv,
    row_number() over (order by gmv desc) as gmv_rank,
    row_number() over (order by order_count desc) as order_rank
from city_metrics
where order_count > 0
