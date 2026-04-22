-- 整体时效分布
SELECT
    ROUND(hour_total_logistics, 1) AS logistics_hour,
    COUNT(*) AS order_cnt
FROM olist_clean.olist_logistics_timely_wide
GROUP BY 1
ORDER BY 1;