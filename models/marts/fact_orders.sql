with orders as (
    select * from {{ref('stg_orders')}}
),
-- solve fan out problem
order_payments as (
    select order_id,
           total_payment_value
    from {{ref('dim_payments')}}
),
-- preprocess the amount of product
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
        
        -- 核心度量值 (Measures)
        -- coalesce(a,b), 如果a为NULL，则设置为b
        coalesce(p.total_payment_value, 0) as total_payment_value,
        coalesce(i.total_item_price, 0) as total_item_price,
        coalesce(i.total_freight_value, 0) as total_freight_value,
        coalesce(i.total_item_count, 0) as total_items_count,

        -- 衍生派生字段：计算订单交付时效（天）
        date_diff(o.delivered_to_customer_at, o.purchased_at, day) as delivery_time_days
    from orders o  
    left join order_payments p on o.order_id = p.order_id
    left join order_items_summary i on o.order_id = i.order_id
)

select * from final