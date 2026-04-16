-- Analyse the price range 
-- We can find out the price located at 33%/66% of item.price data, which can help us separate  data into budget/regular/premium ranges.

SELECT MIN(price) AS min,
	   MAX(price) AS max,
	   AVG(price) AS avg,
	   PERCENTILE_CONT(0.33) WITHIN GROUP(ORDER BY price) AS p33,
	   PERCENTILE_CONT(0.66) WITHIN GROUP(ORDER BY price) AS p66
FROM olist_raw.order_items;
