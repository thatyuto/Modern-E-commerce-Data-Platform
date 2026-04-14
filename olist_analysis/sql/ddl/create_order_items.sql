CREATE TABLE olist_raw.order_items (
	order_id TEXT,
	order_item_id INT,
	product_id TEXT,
	seller_id TEXT,
	shipping_limit_date TIMESTAMP,
	price numeric(10,2),
	freight_value numeric(10,2),  

	PRIMARY KEY (order_id, order_item_id),  
	CONSTRAINT chk_freight CHECK (freight_value >= 0),
	CONSTRAINT chk_price CHECK (price >= 0)
);