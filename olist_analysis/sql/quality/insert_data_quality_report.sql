-- insert data into data_quality_report table

-- customers table
INSERT INTO olist_raw.data_quality_report(table_name,column_name,total_rows,null_count,null_rate)
VALUES('customers',
	   'customer_id',
	   (SELECT COUNT(*) FROM olist_raw.customers),
	   (SELECT SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.customers),
	   (SELECT SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.customers) *100.00 / (SELECT COUNT(*) FROM olist_raw.customers)
),
	  ('customers',
 	   'customer_unique_id',
 	   (SELECT COUNT(*) FROM olist_raw.customers),
	   (SELECT SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.customers),
	   (SELECT SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.customers) *100.00 / (SELECT COUNT(*) FROM olist_raw.customers)
),
	  ('customers',
 	   'customer_zip_code_prefix',
 	   (SELECT COUNT(*) FROM olist_raw.customers),
	   (SELECT SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) FROM olist_raw.customers),
	   (SELECT SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) FROM olist_raw.customers) *100.00 / (SELECT COUNT(*) FROM olist_raw.customers)
),
	  ('customers',
 	   'customer_city',
 	   (SELECT COUNT(*) FROM olist_raw.customers),
	   (SELECT SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) FROM olist_raw.customers),
	   (SELECT SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) FROM olist_raw.customers) *100.00 / (SELECT COUNT(*) FROM olist_raw.customers)
),
	  ('customers',
 	   'customer_state',
 	   (SELECT COUNT(*) FROM olist_raw.customers),
	   (SELECT SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) FROM olist_raw.customers),
	   (SELECT SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) FROM olist_raw.customers) *100.00 / (SELECT COUNT(*) FROM olist_raw.customers)
);

-- geolocation table
INSERT INTO olist_raw.data_quality_report(table_name,column_name,total_rows,null_count,null_rate)
VALUES('geolocation',
	   'geolocation_zip_code_prefix',
	   (SELECT COUNT(*) FROM olist_raw.geolocation),
	   (SELECT SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 ELSE 0 END) FROM olist_raw.geolocation),
	   (SELECT SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 ELSE 0 END) FROM olist_raw.geolocation) *100.00 / (SELECT COUNT(*) FROM olist_raw.geolocation)
),
	  ('geolocation',
	   'geolocation_lat',
	   (SELECT COUNT(*) FROM olist_raw.geolocation),
	   (SELECT SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END) FROM olist_raw.geolocation),
	   (SELECT SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END) FROM olist_raw.geolocation) *100.00 / (SELECT COUNT(*) FROM olist_raw.geolocation)
),
      ('geolocation',
	   'geolocation_lng',
	   (SELECT COUNT(*) FROM olist_raw.geolocation),
	   (SELECT SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END) FROM olist_raw.geolocation),
	   (SELECT SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END) FROM olist_raw.geolocation) *100.00 / (SELECT COUNT(*) FROM olist_raw.geolocation)
),
	  ('geolocation',
	   'geolocation_city',
	   (SELECT COUNT(*) FROM olist_raw.geolocation),
	   (SELECT SUM(CASE WHEN geolocation_city IS NULL THEN 1 ELSE 0 END) FROM olist_raw.geolocation),
	   (SELECT SUM(CASE WHEN geolocation_city IS NULL THEN 1 ELSE 0 END) FROM olist_raw.geolocation) *100.00 / (SELECT COUNT(*) FROM olist_raw.geolocation)
),
      ('geolocation',
	   'geolocation_state',
	   (SELECT COUNT(*) FROM olist_raw.geolocation),
	   (SELECT SUM(CASE WHEN geolocation_state IS NULL THEN 1 ELSE 0 END) FROM olist_raw.geolocation),
	   (SELECT SUM(CASE WHEN geolocation_state IS NULL THEN 1 ELSE 0 END) FROM olist_raw.geolocation) *100.00 / (SELECT COUNT(*) FROM olist_raw.geolocation)
);

-- order_items table
INSERT INTO olist_raw.data_quality_report(table_name,column_name,total_rows,null_count,null_rate)
VALUES('order_items',
	   'order_id',
	   (SELECT COUNT(*) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items) *100.00 / (SELECT COUNT(*) FROM olist_raw.order_items)
),
	  ('order_items',
	   'order_item_id',
	   (SELECT COUNT(*) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items) *100.00 / (SELECT COUNT(*) FROM olist_raw.order_items)
),
	  ('order_items',
	   'product_id',
	   (SELECT COUNT(*) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items) *100.00 / (SELECT COUNT(*) FROM olist_raw.order_items)
),
	  ('order_items',
	   'seller_id',
	   (SELECT COUNT(*) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items) *100.00 / (SELECT COUNT(*) FROM olist_raw.order_items)
),
	  ('order_items',
	   'shipping_limit_date',
	   (SELECT COUNT(*) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items) *100.00 / (SELECT COUNT(*) FROM olist_raw.order_items)
),
	  ('order_items',
	   'price',
	   (SELECT COUNT(*) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items) *100.00 / (SELECT COUNT(*) FROM olist_raw.order_items)
),
	  ('order_items',
	   'freight_value',
	   (SELECT COUNT(*) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items),
	   (SELECT SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) FROM olist_raw.order_items) *100.00 / (SELECT COUNT(*) FROM olist_raw.order_items)
);

-- orders table
INSERT INTO olist_raw.data_quality_report(table_name,column_name,total_rows,null_count,null_rate)
VALUES('orders',
	   'order_id',
	   (SELECT COUNT(*) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders) *100.00 / (SELECT COUNT(*) FROM olist_raw.orders)
),
	  ('orders',
	   'customer_id',
	   (SELECT COUNT(*) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders) *100.00 / (SELECT COUNT(*) FROM olist_raw.orders)
),
	  ('orders',
	   'order_status',
	   (SELECT COUNT(*) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders) *100.00 / (SELECT COUNT(*) FROM olist_raw.orders)
),
	  ('orders',
	   'order_purchase_timestamp',
	   (SELECT COUNT(*) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders) *100.00 / (SELECT COUNT(*) FROM olist_raw.orders)
),
	  ('orders',
	   'order_approved_at',
	   (SELECT COUNT(*) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders) *100.00 / (SELECT COUNT(*) FROM olist_raw.orders)
),
	  ('orders',
	   'order_delivered_carrier_date',
	   (SELECT COUNT(*) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders) *100.00 / (SELECT COUNT(*) FROM olist_raw.orders)
),
	  ('orders',
	   'order_delivered_customer_date',
	   (SELECT COUNT(*) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders) *100.00 / (SELECT COUNT(*) FROM olist_raw.orders)
),
	  ('orders',
	   'order_estimated_delivery_date',
	   (SELECT COUNT(*) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders),
	   (SELECT SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) FROM olist_raw.orders) *100.00 / (SELECT COUNT(*) FROM olist_raw.orders)
);  


-- payments table
INSERT INTO olist_raw.data_quality_report(table_name,column_name,total_rows,null_count,null_rate)
VALUES('payments',
       'order_id',
       (SELECT COUNT(*) FROM olist_raw.payments),
       (SELECT SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.payments),
       (SELECT SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.payments) *100.00 / (SELECT COUNT(*) FROM olist_raw.payments)
),
      ('payments',
       'payment_sequential',
       (SELECT COUNT(*) FROM olist_raw.payments),
       (SELECT SUM(CASE WHEN payment_sequential IS NULL THEN 1 ELSE 0 END) FROM olist_raw.payments),
       (SELECT SUM(CASE WHEN payment_sequential IS NULL THEN 1 ELSE 0 END) FROM olist_raw.payments) *100.00 / (SELECT COUNT(*) FROM olist_raw.payments)
),
      ('payments',
       'payment_type',
       (SELECT COUNT(*) FROM olist_raw.payments),
       (SELECT SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) FROM olist_raw.payments),
       (SELECT SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) FROM olist_raw.payments) *100.00 / (SELECT COUNT(*) FROM olist_raw.payments)
),
      ('payments',
       'payment_installments',
       (SELECT COUNT(*) FROM olist_raw.payments),
       (SELECT SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END) FROM olist_raw.payments),
       (SELECT SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END) FROM olist_raw.payments) *100.00 / (SELECT COUNT(*) FROM olist_raw.payments)
),
      ('payments',
       'payment_value',
       (SELECT COUNT(*) FROM olist_raw.payments),
       (SELECT SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) FROM olist_raw.payments),
       (SELECT SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) FROM olist_raw.payments) *100.00 / (SELECT COUNT(*) FROM olist_raw.payments)
);

-- product_category_name_translation table
INSERT INTO olist_raw.data_quality_report(table_name,column_name,total_rows,null_count,null_rate)
VALUES('product_category_name_translation',
       'product_category_name',
       (SELECT COUNT(*) FROM olist_raw.product_category_name_translation),
       (SELECT SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) FROM olist_raw.product_category_name_translation),
       (SELECT SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) FROM olist_raw.product_category_name_translation) *100.00 / (SELECT COUNT(*) FROM olist_raw.product_category_name_translation)
),
      ('product_category_name_translation',
       'product_category_name_english',
       (SELECT COUNT(*) FROM olist_raw.product_category_name_translation),
       (SELECT SUM(CASE WHEN product_category_name_english IS NULL THEN 1 ELSE 0 END) FROM olist_raw.product_category_name_translation),
       (SELECT SUM(CASE WHEN product_category_name_english IS NULL THEN 1 ELSE 0 END) FROM olist_raw.product_category_name_translation) *100.00 / (SELECT COUNT(*) FROM olist_raw.product_category_name_translation)
);

-- products table
INSERT INTO olist_raw.data_quality_report(table_name,column_name,total_rows,null_count,null_rate)
VALUES('products',
       'product_id',
       (SELECT COUNT(*) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products) *100.00 / (SELECT COUNT(*) FROM olist_raw.products)
),
      ('products',
       'product_category_name',
       (SELECT COUNT(*) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products) *100.00 / (SELECT COUNT(*) FROM olist_raw.products)
),
      ('products',
       'product_name_length',
       (SELECT COUNT(*) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_name_length IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_name_length IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products) *100.00 / (SELECT COUNT(*) FROM olist_raw.products)
),
      ('products',
       'product_description_length',
       (SELECT COUNT(*) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_description_length IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_description_length IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products) *100.00 / (SELECT COUNT(*) FROM olist_raw.products)
),
      ('products',
       'product_photos_qty',
       (SELECT COUNT(*) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products) *100.00 / (SELECT COUNT(*) FROM olist_raw.products)
),
      ('products',
       'product_weight_g',
       (SELECT COUNT(*) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products) *100.00 / (SELECT COUNT(*) FROM olist_raw.products)
),
      ('products',
       'product_length_cm',
       (SELECT COUNT(*) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products) *100.00 / (SELECT COUNT(*) FROM olist_raw.products)
),
      ('products',
       'product_height_cm',
       (SELECT COUNT(*) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products) *100.00 / (SELECT COUNT(*) FROM olist_raw.products)
),
      ('products',
       'product_width_cm',
       (SELECT COUNT(*) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products),
       (SELECT SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) FROM olist_raw.products) *100.00 / (SELECT COUNT(*) FROM olist_raw.products)
);

-- reviews table
INSERT INTO olist_raw.data_quality_report(table_name,column_name,total_rows,null_count,null_rate)
VALUES('reviews',
       'review_id',
       (SELECT COUNT(*) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews) *100.00 / (SELECT COUNT(*) FROM olist_raw.reviews)
),
      ('reviews',
       'order_id',
       (SELECT COUNT(*) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews) *100.00 / (SELECT COUNT(*) FROM olist_raw.reviews)
),
      ('reviews',
       'review_score',
       (SELECT COUNT(*) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews) *100.00 / (SELECT COUNT(*) FROM olist_raw.reviews)
),
      ('reviews',
       'review_comment_title',
       (SELECT COUNT(*) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews) *100.00 / (SELECT COUNT(*) FROM olist_raw.reviews)
),
      ('reviews',
       'review_comment_message',
       (SELECT COUNT(*) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews) *100.00 / (SELECT COUNT(*) FROM olist_raw.reviews)
),
      ('reviews',
       'review_creation_date',
       (SELECT COUNT(*) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews) *100.00 / (SELECT COUNT(*) FROM olist_raw.reviews)
),
      ('reviews',
       'review_answer_timestamp',
       (SELECT COUNT(*) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews),
       (SELECT SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) FROM olist_raw.reviews) *100.00 / (SELECT COUNT(*) FROM olist_raw.reviews)
);


-- sellers table
INSERT INTO olist_raw.data_quality_report(table_name,column_name,total_rows,null_count,null_rate)
VALUES('sellers',
       'seller_id',
       (SELECT COUNT(*) FROM olist_raw.sellers),
       (SELECT SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.sellers),
       (SELECT SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) FROM olist_raw.sellers) *100.00 / (SELECT COUNT(*) FROM olist_raw.sellers)
),
      ('sellers',
       'seller_zip_code_prefix',
       (SELECT COUNT(*) FROM olist_raw.sellers),
       (SELECT SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END) FROM olist_raw.sellers),
       (SELECT SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END) FROM olist_raw.sellers) *100.00 / (SELECT COUNT(*) FROM olist_raw.sellers)
),
      ('sellers',
       'seller_city',
       (SELECT COUNT(*) FROM olist_raw.sellers),
       (SELECT SUM(CASE WHEN seller_city IS NULL THEN 1 ELSE 0 END) FROM olist_raw.sellers),
       (SELECT SUM(CASE WHEN seller_city IS NULL THEN 1 ELSE 0 END) FROM olist_raw.sellers) *100.00 / (SELECT COUNT(*) FROM olist_raw.sellers)
),
      ('sellers',
       'seller_state',
       (SELECT COUNT(*) FROM olist_raw.sellers),
       (SELECT SUM(CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) FROM olist_raw.sellers),
       (SELECT SUM(CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) FROM olist_raw.sellers) *100.00 / (SELECT COUNT(*) FROM olist_raw.sellers)
);