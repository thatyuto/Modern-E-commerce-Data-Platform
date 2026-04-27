
BEGIN;
-- 全链路宽表
CREATE TABLE IF NOT EXISTS olist_mart.fact_order_wide_table AS 

-- 1. 压平支付表：解决一单多付导致的金额Fan-out问题
WITH payment_flat AS (
	SELECT order_id,
		   SUM(payment_value) AS total_payment_amount
	FROM olist_clean.olist_order_payments_clean
    GROUP BY order_id
),
-- 2. 压平geolocation表，防止zipcode膨胀
geo_flat AS (
    SELECT 
        geolocation_zip_code_prefix,
        AVG(geolocation_lat) AS customer_lat,
        AVG(geolocation_lng) AS customer_lng
    FROM olist_clean.olist_geolocation_clean
    GROUP BY 1
)

-- 3. 全链路关联
SELECT 
	-- 核心id
	oi.order_id,
	oi.order_item_id,
	oi.product_id,
	oi.seller_id,
	o.customer_id,
	c.customer_unique_id,
	-- 财务度量
    oi.price,
    oi.freight_value,
    pay.total_payment_amount,

    -- 时间与状态
    o.order_purchase_timestamp,
    o.order_status,
    o.order_delivered_customer_date,

    -- 买家地理信息 (含经纬度)
    c.customer_city,
    c.customer_state,
    g.customer_lat,
    g.customer_lng,

    -- 卖家地理信息
    s.seller_city,
    s.seller_state,

    -- 商品品类
    p.product_category_name

FROM olist_clean.olist_order_items_clean oi
LEFT JOIN olist_clean.olist_orders_clean o ON oi.order_id = o.order_id
LEFT JOIN olist_clean.olist_customers_clean c ON o.customer_id = c.customer_id
LEFT JOIN olist_clean.olist_products_clean p ON oi.product_id = p.product_id
LEFT JOIN olist_clean.olist_sellers_clean s ON oi.seller_id = s.seller_id
LEFT JOIN payment_flat pay ON oi.order_id = pay.order_id
LEFT JOIN geo_flat g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix;

COMMIT;


