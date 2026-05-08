-- extract data from here

select 
    order_id,
    customer_id,
    order_status
from {{ source('olist_raw','olist_orders_dataset')}}

