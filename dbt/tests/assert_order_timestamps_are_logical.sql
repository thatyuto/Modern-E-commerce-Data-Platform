select order_id,
       customer_id
from {{ref('stg_orders')}}
where 
-- 如果送达比下单还早，说明数据有问题
    approved_at <  purchased_at
    or delivered_to_carrier_at < approved_at
    or  delivered_to_customer_at < delivered_to_carrier_at
    