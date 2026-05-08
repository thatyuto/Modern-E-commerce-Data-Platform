-- first, refer staging model: stg_orders

select *
from {{ref('stg_orders')}}
where order_status = 'delivered'