WITH daily AS (
    SELECT
        DATE(order_purchase_timestamp) AS order_date,
        COUNT(DISTINCT o.order_id) AS order_quantity,
        SUM(payment_value) AS gmv
    FROM olist_clean.olist_orders_clean o 
    JOIN olist_clean.olist_order_payments_clean p 
        ON o.order_id = p.order_id
    GROUP BY DATE(order_purchase_timestamp)
)
SELECT
    order_date,
    order_quantity,
    gmv,
    -- 7日移动平均订单量
    AVG(order_quantity) OVER (
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS ma7_order_quantity,
    -- 7日移动平均GMV
    AVG(gmv) OVER (
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS ma7_gmv
FROM daily
ORDER BY order_date;