BEGIN TRANSACTION;
CREATE VIEW IF NOT EXISTS stock AS SELECT id, name, category, amount FROM products WHERE deprecated = 0 OR amount != 0;
CREATE VIEW IF NOT EXISTS purchaseprices AS SELECT product, SUM(price * amount) / SUM(amount) AS price FROM restock GROUP BY product;
CREATE VIEW IF NOT EXISTS invoice AS 
	SELECT user, timestamp, id AS productid, name AS productname,
		CASE
			WHEN user < 0 THEN
				(SELECT SUM(price * amount) / SUM(amount)
					FROM restock
					WHERE restock.product = id AND restock.timestamp <= sales.timestamp
				)
			else
				(SELECT
					CASE
						WHEN user=0 THEN guestprice
						else memberprice
					END
					FROM prices
					WHERE product = id AND valid_from <= timestamp
					ORDER BY valid_from DESC LIMIT 1)
			END AS price
		FROM sales INNER JOIN products ON sales.product = products.id
		ORDER BY timestamp;
CREATE VIEW IF NOT EXISTS current_cashbox_status AS
	SELECT (
		(
			SELECT SUM(
				(
					SELECT guestprice
						FROM prices
						WHERE product = s.product AND valid_from <= s.timestamp
						ORDER BY valid_from DESC LIMIT 1
				)
			) FROM sales s WHERE user = 0
		)
		+
		(
			SELECT SUM(amount) FROM cashbox_diff
		)
	) AS amount;
COMMIT;
