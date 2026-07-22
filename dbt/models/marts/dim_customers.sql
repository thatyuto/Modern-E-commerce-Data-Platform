-- Based on SCD Type1 strategy
{{
    config(
        materialized='incremental',
        unique_key='customer_unique_id',
        incremental_strategy='merge'
    )
}}

with customer_stats as (
    select
        customer_unique_id,
        max(purchased_at) as last_purchase_at,  -- the last purchase date
        count(distinct order_id) as frequency,  -- use the number of order_id as frequency
        sum(total_payment_value) as monetary
    from {{ref('fact_orders')}} o
    left join {{ref('stg_customers')}} c
    on o.customer_id = c.customer_id
    group by 1
),
-- 网页dbt可以运行,但由于airflow版本问题，因此做出修改，改成下面版本
-- active_customers as (
--     select distinct c.customer_unique_id,
--     from {{ ref('fact_orders') }} o
--     left join {{ ref('stg_customers') }} c on o.customer_id = c.customer_id
--     {% if is_incremental() %}
--       -- 如果是增量运行，只看过去 7 天更新过的订单
--       where o.updated_at >= (select timestamp_sub(max(updated_at), interval 7 day) from {{ this }})
--     {% endif %}    
-- ),

active_customers as (
    select distinct c.customer_unique_id,
    from {{ ref('fact_orders') }} o
    left join {{ ref('stg_customers') }} c on o.customer_id = c.customer_id
    {% if is_incremental() %}
      -- 🎯 用 fact_orders 确定存在的 purchased_at，去对比目标表客户维度的已更新水位
      where o.purchased_at >= (select timestamp_sub(max(updated_at), interval 7 day) from {{ this }})
    {% endif %}    
),
rfm_metrics as (
    select *,
    date_diff(
        (select max(last_purchase_at) from customer_stats),   -- find the maximum date
        last_purchase_at,
        day                                                   -- 单位为日
    ) as recency
    from customer_stats
),
rfm_scores as (
    -- calculate the R/F/M score: 
    -- ntile(5) divides the data evenly into 5 parts. 
    -- The smaller the R value, the higher the score; 
    -- the larger the F/M value, the higher the score.
    select *,
           ntile(5) over( order by recency desc) as r_score,
           ntile(5) over( order by frequency asc) as f_score,
           ntile(5) over( order by monetary asc) as m_score
    from rfm_metrics
),
rfm_average_score as (
    select *,
           avg(r_score) over() as r_avg,
           avg(f_score) over() as f_avg,
           avg(m_score) over() as m_avg
    from rfm_scores
),
final_segments as (
    select
        *,
        case when r_score >= r_avg then '高' else '低' end as r_level,
        case when f_score >= f_avg then '高' else '低' end as f_level,
        case when m_score >= m_avg then '高' else '低' end as m_level
    from rfm_average_score
)

select 
    customer_unique_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    r_level,
    f_level,
    m_level,
    
    -- 新增timestamp字段: updated_at，方便后续对于时间过滤
    current_timestamp() as updated_at,
    case 
        when r_level = '高' and f_level = '高' and m_level = '高' then '重要价值客户'
        when r_level = '高' and f_level = '高' and m_level = '低' then '重要保持客户'
        when r_level = '高' and f_level = '低' and m_level = '高' then '重要发展客户'
        when r_level = '低' and f_level = '高' and m_level = '高' then '重要挽留客户'
        else '一般客户'
    end as customer_segment
from final_segments


{% if is_incremental() %}
  -- 步骤 2：过滤！只把这批活跃用户的最新 RFM 结果吐出来，去 merge 覆盖目标表
  where customer_unique_id in (select customer_unique_id from active_customers)
{% endif %}