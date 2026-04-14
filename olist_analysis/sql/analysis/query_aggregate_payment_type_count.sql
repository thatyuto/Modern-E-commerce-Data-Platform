-- Count the number of payments for each payment type

SELECT payment_type, COUNT(payment_type) AS order_count
FROM olist_raw.payments
GROUP BY payment_type;