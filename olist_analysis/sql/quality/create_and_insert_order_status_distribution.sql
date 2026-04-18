-- create table order_status_distribution

CREATE TABLE IF NOT EXISTS olist_raw.order_status_distribution (
	order_status TEXT,
	count BIGINT,
	percentage DECIMAL(10,2)
);

-- insert data into order_status_distribution table

INSERT INTO olist_raw.order_status_distribution(order_status, count, percentage)
	SELECT order_status,
		   COUNT(*),
		   ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2)
	FROM olist_raw.orders
	GROUP BY order_status;
