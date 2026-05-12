select
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state,
        avg(geolocation_lat) as avg_lat, -- 取平均值确保唯一性
        avg(geolocation_lng) as avg_lng
from {{ ref('stg_geolocation') }}
group by 1, 2, 3 