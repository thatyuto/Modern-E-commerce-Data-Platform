-- ==============================
--  olist_raw 9张表全套注释
-- ==============================

-- 1. customers
COMMENT ON TABLE  olist_raw.customers IS '客户信息表';
COMMENT ON COLUMN olist_raw.customers.customer_id IS '客户唯一ID';
COMMENT ON COLUMN olist_raw.customers.customer_unique_id IS '客户唯一标识（可用于识别同一用户多订单）';
COMMENT ON COLUMN olist_raw.customers.customer_zip_code_prefix IS '客户邮编前缀';
COMMENT ON COLUMN olist_raw.customers.customer_city IS '客户所在城市';
COMMENT ON COLUMN olist_raw.customers.customer_state IS '客户所在州';

-- 2. sellers
COMMENT ON TABLE  olist_raw.sellers IS '卖家信息表';
COMMENT ON COLUMN olist_raw.sellers.seller_id IS '卖家唯一ID';
COMMENT ON COLUMN olist_raw.sellers.seller_zip_code_prefix IS '卖家邮编前缀';
COMMENT ON COLUMN olist_raw.sellers.seller_city IS '卖家所在城市';
COMMENT ON COLUMN olist_raw.sellers.seller_state IS '卖家所在州';

-- 3. products
COMMENT ON TABLE  olist_raw.products IS '商品信息表';
COMMENT ON COLUMN olist_raw.products.product_id IS '商品唯一ID';
COMMENT ON COLUMN olist_raw.products.product_category_name IS '商品类别名称（葡语）';
COMMENT ON COLUMN olist_raw.products.product_name_length IS '商品名称长度';
COMMENT ON COLUMN olist_raw.products.product_description_length IS '商品描述长度';
COMMENT ON COLUMN olist_raw.products.product_photos_qty IS '商品图片数量';
COMMENT ON COLUMN olist_raw.products.product_weight_g IS '商品重量（克）';
COMMENT ON COLUMN olist_raw.products.product_length_cm IS '商品长度（厘米）';
COMMENT ON COLUMN olist_raw.products.product_height_cm IS '商品高度（厘米）';
COMMENT ON COLUMN olist_raw.products.product_width_cm IS '商品宽度（厘米）';

-- 4. orders
COMMENT ON TABLE  olist_raw.orders IS '订单主表';
COMMENT ON COLUMN olist_raw.orders.order_id IS '订单唯一ID';
COMMENT ON COLUMN olist_raw.orders.customer_id IS '下单客户ID';
COMMENT ON COLUMN olist_raw.orders.order_status IS '订单状态';
COMMENT ON COLUMN olist_raw.orders.order_purchase_timestamp IS '订单购买时间';
COMMENT ON COLUMN olist_raw.orders.order_approved_at IS '订单支付批准时间';
COMMENT ON COLUMN olist_raw.orders.order_delivered_carrier_date IS '物流揽收时间';
COMMENT ON COLUMN olist_raw.orders.order_delivered_customer_date IS '客户签收时间';
COMMENT ON COLUMN olist_raw.orders.order_estimated_delivery_date IS '预计送达时间';

-- 5. order_items
COMMENT ON TABLE  olist_raw.order_items IS '订单商品明细表';
COMMENT ON COLUMN olist_raw.order_items.order_id IS '订单ID';
COMMENT ON COLUMN olist_raw.order_items.order_item_id IS '订单内商品序号（同一订单多个商品会递增）';
COMMENT ON COLUMN olist_raw.order_items.product_id IS '商品ID';
COMMENT ON COLUMN olist_raw.order_items.seller_id IS '卖家ID';
COMMENT ON COLUMN olist_raw.order_items.shipping_limit_date IS '卖家最晚发货时间';
COMMENT ON COLUMN olist_raw.order_items.price IS '商品单价';
COMMENT ON COLUMN olist_raw.order_items.freight_value IS '运费';

-- 6. order_payments
COMMENT ON TABLE  olist_raw.order_payments IS '订单支付信息表';
COMMENT ON COLUMN olist_raw.order_payments.order_id IS '订单ID';
COMMENT ON COLUMN olist_raw.order_payments.payment_sequential IS '支付序号（一笔订单多次支付）';
COMMENT ON COLUMN olist_raw.order_payments.payment_type IS '支付方式';
COMMENT ON COLUMN olist_raw.order_payments.payment_installments IS '分期数';
COMMENT ON COLUMN olist_raw.order_payments.payment_value IS '支付金额';

-- 7. order_reviews
COMMENT ON TABLE  olist_raw.order_reviews IS '订单评价表';
COMMENT ON COLUMN olist_raw.order_reviews.review_id IS '评价ID';
COMMENT ON COLUMN olist_raw.order_reviews.order_id IS '订单ID';
COMMENT ON COLUMN olist_raw.order_reviews.review_score IS '评分1-5';
COMMENT ON COLUMN olist_raw.order_reviews.review_comment_title IS '评价标题';
COMMENT ON COLUMN olist_raw.order_reviews.review_comment_message IS '评价内容';
COMMENT ON COLUMN olist_raw.order_reviews.review_creation_date IS '评价创建时间';
COMMENT ON COLUMN olist_raw.order_reviews.review_answer_timestamp IS '卖家回复时间';

-- 8. geolocation
COMMENT ON TABLE  olist_raw.geolocation IS '邮编经纬度对照表';
COMMENT ON COLUMN olist_raw.geolocation.geolocation_zip_code_prefix IS '邮编前缀';
COMMENT ON COLUMN olist_raw.geolocation.geolocation_lat IS '纬度';
COMMENT ON COLUMN olist_raw.geolocation.geolocation_lng IS '经度';
COMMENT ON COLUMN olist_raw.geolocation.geolocation_city IS '城市';
COMMENT ON COLUMN olist_raw.geolocation.geolocation_state IS '州';

-- 9. product_category_name_translation
COMMENT ON TABLE  olist_raw.product_category_name_translation IS '商品类别葡英翻译表';
COMMENT ON COLUMN olist_raw.product_category_name_translation.product_category_name IS '葡语类别名称';
COMMENT ON COLUMN olist_raw.product_category_name_translation.product_category_name_english IS '英语类别名称';