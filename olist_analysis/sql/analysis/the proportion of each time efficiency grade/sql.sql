-- 时效等级占比
SELECT
    timely_level,
    COUNT(*) AS order_cnt,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM olist_clean.olist_logistics_timely_wide
GROUP BY timely_level
ORDER BY order_cnt DESC;