-- create the index of customers

CREATE INDEX idx_orders_order_id ON olist_raw.orders (order_id);
CREATE INDEX idx_orders_items_order_id ON olist_raw.order_items (order_id);
CREATE INDEX idx_payments_order_id ON olist_raw.payments (order_id);
CREATE INDEX idx_reviews_order_id ON olist_raw.reviews (order_id);

CREATE INDEX idx_customers_customer_id ON olist_raw.customers (customer_id);