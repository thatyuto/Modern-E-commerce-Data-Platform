WITH dataset_max_date AS (
    SELECT MAX(order_purchase_timestamp) AS max_date
    FROM olist_clean.olist_orders_clean
),
user_base AS (
    SELECT
        c.customer_unique_id AS 用户ID,
        MIN(o.order_purchase_timestamp) AS 首次下单,
        MAX(o.order_purchase_timestamp) AS 最近下单,
        COUNT(DISTINCT o.order_id) AS 总订单数,
        COALESCE(SUM(op.payment_value), 0) AS 总消费,
        EXTRACT(HOUR FROM (SELECT max_date FROM dataset_max_date) - MAX(o.order_purchase_timestamp))/24 AS 末次未购天数
    FROM olist_clean.olist_orders_clean o
    JOIN olist_clean.olist_customers_clean c 
        ON o.customer_id = c.customer_id
    LEFT JOIN olist_clean.olist_order_payments_clean op 
        ON o.order_id = op.order_id
    GROUP BY c.customer_unique_id
),
order_lag AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp,
        LAG(o.order_purchase_timestamp) OVER(
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS prev_order_time
    FROM olist_clean.olist_orders_clean o
    JOIN olist_clean.olist_customers_clean c 
        ON o.customer_id = c.customer_id
),
user_interval AS (
    SELECT
        customer_unique_id AS 用户ID,
        ROUND(AVG(EXTRACT(DAY FROM order_purchase_timestamp - prev_order_time)),1) AS 平均下单间隔_天
    FROM order_lag
    WHERE prev_order_time IS NOT NULL
    GROUP BY customer_unique_id
)
INSERT INTO user_behavior(
    用户ID,
    首次下单,
    最近下单,
    总订单数,
    总消费,
    平均客单,
    平均下单间隔_天,
    用户标签
)
SELECT 
    ub.用户ID,
    ub.首次下单,
    ub.最近下单,
    ub.总订单数,
    ROUND(ub.总消费,2) AS 总消费,
    ROUND(ub.总消费 / NULLIF(ub.总订单数,0),2) AS 平均客单,
    ui.平均下单间隔_天,
    CASE
        WHEN ub.末次未购天数 <= 30 AND ub.总订单数 = 1 THEN '新客'
        WHEN ub.末次未购天数 <= 30 AND ub.总订单数 >= 2 THEN '复购'
        WHEN ub.末次未购天数 BETWEEN 31 AND 90 THEN '沉睡'
        WHEN ub.末次未购天数 > 90 THEN '流失'
        ELSE '其他'
    END AS 用户标签
FROM user_base ub
LEFT JOIN user_interval ui ON ub.用户ID = ui.用户ID
ORDER BY ub.总订单数 DESC;

COMMIT;

