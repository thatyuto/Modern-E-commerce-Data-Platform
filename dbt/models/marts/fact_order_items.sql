with order_items as (
    select * from {{ref('stg_order_items')}}
),
orders as (
    select
        order_id,
        customer_id,
        order_status,
        purchased_at
    from {{ref('fact_orders')}}
),
products as (
    select 
        product_id,
        category_name,
        weight_class
    from {{ref('dim_products')}}
),
sellers as (
    select 
        seller_id,
        seller_city,
        seller_state
    from {{ ref('dim_sellers') }}
),
final as (
    select 
        {{dbt_utils.generate_surrogate_key(['oi.order_id','oi.order_item_id']) }} as order_item_key,
        oi.order_id,
        oi.order_item_id,
        o.customer_id,
        oi.product_id,
        oi.seller_id,
        
        -- Denormalized Context
        o.purchased_at,
        p.category_name,
        p.weight_class,
        s.seller_state,

        -- Base Metrics
        oi.price,
        oi.freight_value,
        (oi.price + oi.freight_value) as total_item_value,

        -- freight_value ratio
        case when (oi.price + oi.freight_value) > 0
             then oi.freight_value / (oi.price + oi.freight_value)
             else 0
        end as freight_ratio

    from order_items oi
    left join orders o on oi.order_id = o.order_id
    left join products p on oi.product_id = p.product_id
    left join sellers s on oi.seller_id = s.seller_id
)

select * from final