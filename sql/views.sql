BEGIN TRANSACTION;
CREATE VIEW IF NOT EXISTS purchaseprices AS SELECT product, SUM(price * amount) / SUM(amount) AS price FROM restock GROUP BY product;
CREATE VIEW IF NOT EXISTS invoice AS 
	SELECT user, timestamp, id AS productid, name AS productname,
		CASE
			WHEN user < 0 THEN
				(SELECT price
					FROM purchaseprices
					WHERE purchaseprices.product = id)
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
		FROM sells INNER JOIN products ON sells.product = products.id
		ORDER BY timestamp;
COMMIT;
