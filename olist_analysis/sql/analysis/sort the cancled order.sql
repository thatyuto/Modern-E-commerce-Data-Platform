-- Search for orders that have been cancled and the top 10 of payments amount
-- Method 1: NO RANK VERSION
SELECT o.order_id,
	   o.order_status,
	   p.payment_value
FROM olist_raw.orders o
JOIN olist_raw.payments p
ON o.order_id = p.order_id
WHERE o.order_status = 'canceled'
ORDER BY p.payment_value DESC
LIMIT 10; 

-- Method 2: RANK VERSON USING WINDOW FUNCTION

WITH payment_order AS (
	SELECT o.order_id,
		   o.order_status,
		   p.payment_value,
		   RANK() OVER(ORDER BY p.payment_value DESC) AS rank
	FROM olist_raw.orders o
	JOIN olist_raw.payments p
	ON o.order_id = p.order_id
	WHERE o.order_status = 'canceled'
)

SELECT order_id,
	   order_status,
       payment_value,
       rank
FROM payment_order
ORDER BY payment_value DESC;