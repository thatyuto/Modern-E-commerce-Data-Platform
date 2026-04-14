-- Find all orders with a payment amount exceeding 500 and instalments greater than 5

SELECT *
FROM olist_raw.payments
WHERE payment_value > 500
AND payment_installments > 5;