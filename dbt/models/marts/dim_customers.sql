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
    case 
        when r_level = '高' and f_level = '高' and m_level = '高' then '重要价值客户'
        when r_level = '高' and f_level = '高' and m_level = '低' then '重要保持客户'
        when r_level = '高' and f_level = '低' and m_level = '高' then '重要发展客户'
        when r_level = '低' and f_level = '高' and m_level = '高' then '重要挽留客户'
        else '一般客户'
    end as customer_segment
from final_segments