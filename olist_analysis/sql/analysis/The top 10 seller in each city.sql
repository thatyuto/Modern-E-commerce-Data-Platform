WITH city_sales AS (
    -- 第一步：先算每个商家在各自城市的销售额
    SELECT
        s.seller_city,
        s.seller_id,
        SUM(oi.price) AS total_sales  -- 销售额（正确指标）
    FROM olist_clean.olist_sellers_clean s
    LEFT JOIN olist_clean.olist_order_items_clean oi
        ON s.seller_id = oi.seller_id
    GROUP BY s.seller_city, s.seller_id
),
ranked_sellers AS (
    -- 第二步：按城市分区，销售额降序排名
    SELECT
        seller_city,
        seller_id,
        total_sales,
        ROW_NUMBER() OVER(
            PARTITION BY seller_city  -- 按城市分组排名（关键！）
            ORDER BY total_sales DESC
        ) AS city_rank
    FROM city_sales
)
-- 第三步：每个城市取 TOP10
SELECT *
FROM ranked_sellers
WHERE city_rank <= 10
ORDER BY seller_city, city_rank;