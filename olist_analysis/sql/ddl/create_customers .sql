CREATE TABLE olist_raw.customers (
	customer_id TEXT PRIMARY KEY,
	customer_unique_id TEXT NOT NULL,
	customer_zip_code_prefix INT NOT NULL,
	customer_city TEXT NOT NULL,
	customer_state TEXT NOT NULL
);