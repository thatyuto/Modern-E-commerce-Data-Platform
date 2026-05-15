{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='merge'
    )

}}

with orders as (
    select * from {{ref('stg_orders')}}
),

-- 修正点：在这里必须进行 sum 和 group by，确保一个 order_id 只有一行
order_payments as (
    select order_id,
           sum(payment_value) as total_payment_value
    from {{ref('dim_payments')}}
    group by 1
),

order_items_summary as (
    select order_id,
           sum(price) as total_item_price,
           sum(freight_value) as total_freight_value,
           count(product_id) as total_item_count
    from {{ref('stg_order_items')}}
    group by 1
),

final as (
    select 
        o.order_id,
        o.customer_id,
        o.order_status,
        o.purchased_at,
        o.approved_at,
        o.delivered_to_customer_at,

       

        coalesce(p.total_payment_value, 0) as total_payment_value,
        coalesce(i.total_item_price, 0) as total_item_price,
        coalesce(i.total_freight_value, 0) as total_freight_value,
        coalesce(i.total_item_count, 0) as total_items_count,
        date_diff(o.delivered_to_customer_at, o.purchased_at, day) as delivery_time_days
    from orders o  
    left join order_payments p on o.order_id = p.order_id
    left join order_items_summary i on o.order_id = i.order_id

    -- 杀手锏：最后的唯一性屏障 : 如果存在重复order_id的数据，只取一条。
    -- 但这不是一个最优解，产生多条数重复order_id的原因是join产生的fan-out问题
    -- 因此强制的只取一条数据意味着，会丢失大量有用数据，因此最优解是解决fan-out问题
    qualify row_number() over(partition by o.order_id order by o.purchased_at desc) = 1
)

select * from final

{% if is_incremental() %}
    -- 增量过滤：只增加最近七天的数据，如果没有这一条，model会扫全表，消耗的资源爆炸，此时incremental形同虚设
    where purchased_at >= (select timestamp_sub(max(updated_at),interval 7 day) from {{this}})
{% endif%}