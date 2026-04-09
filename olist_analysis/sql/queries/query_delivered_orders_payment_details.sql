-- query payment details for orders with "delivered" status

SELECT o.order_id, o.order_status, p.payment_value
FROM olist_raw.orders o
JOIN olist_raw.payments p
ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
LIMIT 10;