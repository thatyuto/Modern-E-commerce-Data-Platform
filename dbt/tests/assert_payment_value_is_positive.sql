-- Test if there is any data that payment_value <= 0 

select order_id,
       payment_value
from {{ ref('stg_payments') }}
where payment_value <= 0