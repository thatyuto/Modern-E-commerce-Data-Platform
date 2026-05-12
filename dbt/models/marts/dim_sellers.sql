with sellers as (
    select * from {{ref('stg_sellers')}}
),
geo as (
    select * from {{ ref('dim_geo') }}
),
final as (
    select seller_id,
           s.seller_zip_code_prefix,
           s.seller_city,
           s.seller_state,
           g.avg_lat,
           g.avg_lng
    from sellers s
    left join geo g
    on s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
)
select * from final
