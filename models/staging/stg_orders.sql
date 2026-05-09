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
        cast(order_delivered_customer_date as timestamp) as delivered_to_customer_at,
        cast(order_estimated_delivery_date as timestamp) as estimated_delivery_at
    from source 
)

select * from renamed

