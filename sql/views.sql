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
CREATE VIEW IF NOT EXISTS singleDaysSinceFirstSale AS
	WITH RECURSIVE
	singledays(x) AS (
	 SELECT (SELECT strftime('%s',datetime( (select s.timestamp from sales s order by s.timestamp asc limit 1), 'unixepoch','start of year'))*1)
	 UNION ALL
	 SELECT x+86400 FROM singledays
	  LIMIT 10000
	)
	SELECT x as start, (x+86399) as end FROM singledays where x < strftime('%s','now')*1.0;
CREATE VIEW IF NOT EXISTS statistic_productsperday AS
	select
	date(sdsp.start, 'unixepoch') day,
	( SELECT count(*) from salesView s1 where s1.timestamp >= sdsp.start and s1.timestamp <= sdsp.end and p.id = s1.productId) as numOfProducts,
	( select sum(s2.price) from salesView s2 where s2.timestamp >= sdsp.start and s2.timestamp <= sdsp.end and p.id = s2.productId) as total,
	p.name product,
	p.id productId
	from singleDaysSinceFirstSale sdsp, products p
	where numOfProducts > 0;
CREATE VIEW IF NOT EXISTS statistic_productspermonth AS
	SELECT
		strftime('%m',day) month,
		strftime('%Y',day) year,
		sum(numOfProducts) numOfProducts,
		sum(total) total ,
		product,
		productId
	FROM
		statistic_productsperday
	GROUP BY
		product,month,year;
CREATE VIEW IF NOT EXISTS statistic_productsperyear AS
	SELECT
	year,
	sum(numOfProducts) numOfProducts,
	sum(total) total ,
	product,
	productId
FROM statistic_productspermonth
GROUP BY product,year;
CREATE VIEW IF NOT EXISTS statistic_salesperday AS
	SELECT
		day,
		sum(numOfProducts) numOfProducts,
		sum(total) total
	FROM
		statistic_productsperday
	GROUP BY day;
CREATE VIEW IF NOT EXISTS statistic_salespermonth AS
	SELECT
		strftime('%m',day) month,
		strftime('%Y',day) year,
		sum(numOfProducts) numOfProducts,
		sum(total) total
	FROM
		statistic_salesperday
	GROUP BY
		month,year;
CREATE VIEW IF NOT EXISTS statistic_salesperyear AS
	SELECT
			year,
			sum(numOfProducts) numOfProducts,
			sum(total) total
		FROM
			statistic_salespermonth
		GROUP BY
			year;
COMMIT;
