CREATE TABLE olist_raw.reviews (
	review_id TEXT PRIMARY KEY,
	order_id TEXT NOT NULL,
	review_score INT NOT NULL,
	review_comment_title TEXT,
	review_comment_message TEXT,
	review_creation_date TIMESTAMP,
	review_answer_timestamp TIMESTAMP
);