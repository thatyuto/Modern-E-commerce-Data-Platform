WITH daily_metrics AS (
	-- 计算当前日期订单数量以及前一日订单数量
	SELECT DATE(order_purchase_timestamp) AS order_date,
		   COUNT(DISTINCT order_id) AS order_quantity,
		   LAG(COUNT(DISTINCT order_id)) OVER(ORDER BY DATE(order_purchase_timestamp)) AS last_day_quantity
	FROM olist_clean.olist_orders_clean o
    GROUP BY 1
), growth_calc AS (
    -- 计算增长率
    SELECT 
        *,
        ((order_quantity - last_day_quantity)::NUMERIC / NULLIF(last_day_quantity, 0)) * 100 AS growth_pct
    FROM daily_metrics
    
    -- 计算30天内的平均值和标准差
), moving_statistics AS (
	SELECT *,
		   AVG(growth_pct) OVER(ORDER BY order_date ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING) AS avg_30d,
		   STDDEV(growth_pct) OVER(ORDER BY order_date ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING) AS std_30d
	FROM growth_calc
)

-- 异常判定层
SELECT 
    order_date,
    order_quantity,
    growth_pct,
    CASE 
        -- 判定逻辑：超过 3 倍标准差 且 变动订单数具有业务意义（>10单），防止前面几单因为数值太小，产生异常
        WHEN ABS(growth_pct) > (avg_30d + 3 * COALESCE(std_30d, 0)) 
             AND ABS(order_quantity - last_day_quantity) > 10 THEN 'CRITICAL'
        WHEN ABS(growth_pct) > (avg_30d + 2 * COALESCE(std_30d, 0)) THEN 'WARNING'
        ELSE 'NORMAL'
    END AS status
FROM moving_statistics
ORDER BY order_date DESC;