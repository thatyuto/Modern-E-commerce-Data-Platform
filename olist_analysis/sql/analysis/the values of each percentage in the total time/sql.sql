-- 分位数结果
SELECT
    MAX(p25_total) AS p25_total_hour,
    MAX(p50_total) AS p50_total_hour,
    MAX(p75_total) AS p75_total_hour,
    MAX(p90_total) AS p90_total_hour
FROM olist_clean.olist_logistics_timely_wide;
  
