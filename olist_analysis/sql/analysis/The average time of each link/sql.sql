-- 各环节平均时效
SELECT
    AVG(hour_order_to_pay)  AS avg_order_to_pay,
    AVG(hour_pay_to_ship)   AS avg_pay_to_ship,
    AVG(hour_ship_to_sign)  AS avg_ship_to_sign,
    AVG(hour_total_logistics) AS avg_total
FROM olist_clean.olist_logistics_timely_wide;