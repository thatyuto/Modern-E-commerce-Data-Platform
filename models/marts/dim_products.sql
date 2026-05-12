with products as (
    select * from {{ref('stg_products')}}
),
translations as (
    select * from {{ref('stg_translation')}}
),
final as (
    select p.product_id,
           coalesce(t.string_field_1,'unknow') as category_name,
           (p.product_length_cm * p.product_height_cm * p.product_width_cm) as product_volume_cm3,
           p.product_photos_qty,
           case
                when p.product_weight_g < 400 then 'light weight'
                when p.product_weight_g between 400 and 1250 then 'middle weight'
                else 'heavy weight'
            end as weight_class 
    from products p 
    left join translations t
    on p.product_category_name = t.string_field_0
)

select * from final