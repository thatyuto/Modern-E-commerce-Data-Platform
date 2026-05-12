-- extract data from here

WITH source as (
    select * from {{ source('olist_raw','olist_orders_dataset') }}
),
renamed as (
    select 
        order_id,
        customer_id,
        order_status,
        
        -- confirm timestamp type
        cast(order_purchase_timestamp as timestamp) as purchased_at,
        cast(order_approved_at as timestamp) as approved_at,
        cast(order_delivered_carrier_date as timestamp) as delivered_to_carrier_at,
        cast(order_delivered_customer_date as 
        timestamp) as delivered_to_customer_at,
        cast(order_estimated_delivery_date as timestamp) as estimated_delivery_at
    from source 
),
-- 新增一个过滤层
filtered as (
    select * from renamed
    where 
        -- 只有满足逻辑顺序的订单才进入下游
        (approved_at >= purchased_at or approved_at is null)
        and (delivered_to_carrier_at >= approved_at or delivered_to_carrier_at is null)
        and (delivered_to_customer_at >= delivered_to_carrier_at or delivered_to_customer_at is null)
)

select * from filtered





