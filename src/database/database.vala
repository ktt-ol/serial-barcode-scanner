/* Copyright 2012-2013, Sebastian Reichel <sre@ring0.de>
 * Copyright 2017-2018, Johannes Rudolph <johannes.rudolph@gmx.com>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

public const int day_in_seconds = 24*60*60;

[DBus (name = "io.mainframe.shopsystem.Database")]
public class DataBase : Object {
	private class Statement {
		private Sqlite.Statement stmt;

		public Statement(Sqlite.Database db, string query) {
			int rc = db.prepare_v2(query, -1, out stmt);

			if(rc != Sqlite.OK) {
				error("could not prepare statement: %s", query);
			}
		}

		public void reset() {
			stmt.reset();
		}

		public int step() {
			return stmt.step();
		}

		public int bind_null(int index) {
			return stmt.bind_null(index);
		}

		public int bind_int(int index, int value) {
			return stmt.bind_int(index, value);
		}

		public int bind_text(int index, string value) {
			return stmt.bind_text(index, value);
		}

		public int bind_int64(int index, int64 value) {
			return stmt.bind_int64(index, value);
		}

		public int column_int(int index) {
			return stmt.column_int(index);
		}

		public string column_text(int index) {
			var result = stmt.column_text(index);
			return (result != null) ? result : "";
		}

		public int64 column_int64(int index) {
			return stmt.column_int64(index);
		}
	}

	private Mqtt mqtt;
	private Config cfg;

	private Sqlite.Database db;
	private static Gee.HashMap<string,string> queries = new Gee.HashMap<string,string>();
	private static Gee.HashMap<string,Statement> statements = new Gee.HashMap<string,Statement>();
	//private static HashTable<string,string> queries = new HashTable<string,string>(null, null);
	//private static HashTable<string,Statement> statements = new HashTable<string,Statement>(null, null);

	public DataBase(string file) {
		int rc;

		try {
		this.mqtt = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Mqtt", "/io/mainframe/shopsystem/mqtt");
		this.cfg = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
		} catch (Error e) {
			error("Error: %s\n",e.message);
		}
		rc = Sqlite.Database.open(file, out db);
		if(rc != Sqlite.OK) {
			error("could not open database!");
		}

		/* setup queries */
		queries["product_name"]      = "SELECT name FROM products WHERE id = ?";
		queries["product_category"]  = "SELECT categories.name FROM categories, products WHERE products.category = categories.id AND products.id = ?";
		queries["product_amount"]    = "SELECT amount FROM products WHERE id = ?";
		queries["product_deprecated"]= "SELECT deprecated FROM products WHERE id = ?";
		queries["product_set_deprecated"] = "UPDATE products SET deprecated=? WHERE id = ?";
		queries["products"]          = "SELECT id, name, amount FROM products ORDER BY name";
		queries["purchase"]          = "INSERT INTO sales ('user', 'product', 'timestamp') VALUES (?, ?, ?)";
		queries["last_purchase"]     = "SELECT product FROM sales WHERE user = ? ORDER BY timestamp DESC LIMIT 1";
		queries["undo"]              = "DELETE FROM sales WHERE user = ? ORDER BY timestamp DESC LIMIT 1";
		queries["product_create"]    = "INSERT INTO products ('id', 'name', 'category', 'amount') VALUES (?, ?, ?, ?)";
		queries["price_create"]      = "INSERT INTO prices ('product', 'valid_from', 'memberprice', 'guestprice') VALUES (?, ?, ?, ?)";
		queries["stock"]             = "INSERT INTO restock ('user', 'product', 'amount', 'price', 'timestamp', 'supplier', 'best_before_date') VALUES (?, ?, ?, ?, ?, ?, ?)";
		queries["price"]             = "SELECT memberprice, guestprice FROM prices WHERE product = ? AND valid_from <= ? ORDER BY valid_from DESC LIMIT 1";
		queries["prices"]            = "SELECT valid_from, memberprice, guestprice FROM prices WHERE product = ? ORDER BY valid_from ASC;";
		queries["restocks_asc"]      = "SELECT timestamp, amount, price, supplier, best_before_date FROM restock WHERE product = ? ORDER BY timestamp ASC;";
		queries["restocks_desc"]     = "SELECT timestamp, amount, price, supplier, best_before_date FROM restock WHERE product = ? ORDER BY timestamp DESC;";
		queries["profit_complex"]    = "SELECT SUM(memberprice - (SELECT price FROM purchaseprices WHERE product = purch.product)) FROM sales purch, prices WHERE purch.product = prices.product AND purch.user > 0 AND purch.timestamp > ? AND purch.timestamp < ? AND prices.valid_from = (SELECT valid_from FROM prices WHERE product = purch.product AND valid_from < purch.timestamp ORDER BY valid_from DESC LIMIT 1);";
		queries["sales_complex"]     = "SELECT SUM(memberprice) FROM sales purch, prices WHERE purch.product = prices.product AND purch.user > 0 AND purch.timestamp > ? AND purch.timestamp < ? AND prices.valid_from = (SELECT valid_from FROM prices WHERE product = purch.product AND valid_from < purch.timestamp ORDER BY valid_from DESC LIMIT 1);";
		queries["stock_status"]      = "SELECT stock.id, stock.name, categories.name, amount, memberprice, guestprice FROM stock, prices, categories WHERE stock.id = prices.product AND categories.id = stock.category AND prices.valid_from = (SELECT valid_from FROM prices WHERE product = stock.id ORDER BY valid_from DESC LIMIT 1) ORDER BY categories.name, stock.name";
		queries["stock_amount"]      = "SELECT timestamp, amount FROM restock WHERE product = ? UNION ALL SELECT timestamp, -1 AS amount FROM sales WHERE product = ? ORDER BY timestamp DESC";
		queries["session_set"]       = "UPDATE authentication SET session=? WHERE user = ?";
		queries["session_get"]       = "SELECT user FROM authentication WHERE session = ?";
		queries["username"]          = "SELECT firstname, lastname FROM users WHERE id = ?";
		queries["user_theme_get"]    = "SELECT CASE WHEN sound_theme IS NULL THEN ? ELSE sound_theme END FROM users WHERE id = ?";
		queries["user_theme_set"]    = "UPDATE users SET sound_theme=? WHERE id = ?";
		queries["user_language_get"] = "SELECT CASE WHEN language IS NULL THEN ? ELSE language END FROM users WHERE id = ?";
		queries["user_language_set"] = "UPDATE users SET language=? WHERE id = ?";
		queries["password_get"]      = "SELECT password FROM authentication WHERE user = ?";
		queries["password_set"]      = "UPDATE authentication SET password=? WHERE user = ?";
		queries["userinfo"]          = "SELECT firstname, lastname, email, gender, street, plz, city, pgp, hidden, disabled, sound_theme, joined_at, language FROM users WHERE id = ?";
		queries["userauth"]          = "SELECT superuser, auth_users, auth_products, auth_cashbox FROM authentication WHERE user = ?";
		queries["userauth_set"]      = "UPDATE authentication SET auth_users = ?, auth_products = ?, auth_cashbox = ? WHERE user = ?";
		queries["profit_by_product"] = "SELECT name, SUM(memberprice - (SELECT price FROM purchaseprices WHERE product = purch.product)) AS price FROM sales purch, prices, products WHERE purch.product = products.id AND purch.product = prices.product AND purch.user > 0 AND purch.timestamp > ? AND purch.timestamp < ? AND prices.valid_from = (SELECT valid_from FROM prices WHERE product = purch.product AND valid_from < purch.timestamp ORDER BY valid_from DESC LIMIT 1) GROUP BY name ORDER BY price;";
		queries["invoice"]           = "SELECT timestamp, id AS productid, name AS productname, CASE WHEN user < 0 THEN (SELECT SUM(price * amount) / SUM(amount) FROM restock WHERE restock.product = id AND restock.timestamp <= sales.timestamp) else (SELECT CASE WHEN user=0 THEN guestprice else memberprice END FROM prices WHERE product = id AND valid_from <= timestamp ORDER BY valid_from DESC LIMIT 1) END AS price FROM sales INNER JOIN products ON sales.product = products.id WHERE user = ? AND timestamp >= ? AND timestamp <= ? ORDER BY timestamp";
		queries["sales"]           	 = "SELECT * from salesView Where timestamp >= ? AND timestamp <= ?";
		queries["purchase_first"]    = "SELECT timestamp FROM sales WHERE user = ? ORDER BY timestamp ASC  LIMIT 1";
		queries["purchase_last"]     = "SELECT timestamp FROM sales WHERE user = ? ORDER BY timestamp DESC LIMIT 1";
		queries["count_articles"]    = "SELECT COUNT(*) FROM products";
		queries["count_users"]       = "SELECT COUNT(*) FROM users";
		queries["stock_value"]       = "SELECT SUM(amount * price) FROM products INNER JOIN purchaseprices ON products.id = purchaseprices.product";
		queries["total_sales"]       = "SELECT SUM(price) FROM invoice WHERE user >= 0 AND timestamp >= ?";
		queries["total_profit"]      = "SELECT SUM(price - (SELECT price FROM purchaseprices WHERE product = productid)) FROM invoice WHERE user >= 0 AND timestamp >= ?";
		queries["user_get_ids"]      = "SELECT id FROM users WHERE id > 0";
		queries["user_replace"]      = "INSERT OR REPLACE INTO users ('id', 'email', 'firstname', 'lastname', 'gender', 'street', 'plz', 'city', 'pgp', 'hidden', 'disabled', 'joined_at', 'sound_theme','language') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, (select sound_theme from users where id = ?))";
		queries["user_auth_create"]  = "INSERT OR IGNORE INTO authentication (user) VALUES (?)";
		queries["user_disable"]      = "UPDATE users SET disabled = ? WHERE id = ?";
		queries["last_timestamp"]    = "SELECT timestamp FROM sales ORDER BY timestamp DESC LIMIT 1";
		queries["category_list"]     = "SELECT id, name FROM categories";
		queries["supplier_list"]     = "SELECT id, name, postal_code, city, street, phone, website FROM supplier";
		queries["supplier_get"]      = "SELECT id, name, postal_code, city, street, phone, website FROM supplier WHERE id = ?";
		queries["supplier_add"]      = "INSERT INTO supplier('name', 'postal_code', 'city', 'street', 'phone', 'website') VALUES (?, ?, ?, ?, ?, ?)";
		queries["users_with_sales"]  = "SELECT user FROM sales WHERE timestamp > ? AND timestamp < ? GROUP BY user";
		queries["user_invoice_sum"]  = "SELECT SUM(CASE WHEN user < 0 THEN (SELECT SUM(price * amount) / SUM(amount) FROM restock WHERE restock.product = id AND restock.timestamp <= sales.timestamp) else (SELECT CASE WHEN user=0 THEN guestprice else memberprice END FROM prices WHERE product = id AND valid_from <= timestamp ORDER BY valid_from DESC LIMIT 1) END) FROM sales INNER JOIN products ON sales.product = products.id WHERE user = ? AND timestamp >= ? AND timestamp <= ? ORDER BY timestamp";
		queries["cashbox_status"]    = "SELECT amount FROM current_cashbox_status";
		queries["cashbox_add"]       = "INSERT INTO cashbox_diff ('user', 'amount', 'timestamp') VALUES (?, ?, ?)";
		queries["cashbox_history"]   = "SELECT user, amount, timestamp FROM cashbox_diff ORDER BY timestamp DESC LIMIT 10";
		queries["cashbox_changes"]   = "SELECT user, amount, timestamp FROM cashbox_diff WHERE timestamp >= ? and timestamp < ? ORDER BY timestamp ASC";
		queries["alias_ean_add"]     = "INSERT OR IGNORE INTO ean_aliases (id, real_ean) VALUES (?, ?)";
		queries["alias_ean_get"]     = "SELECT real_ean FROM ean_aliases WHERE id = ?";
		queries["alias_ean_list"]    = "SELECT id, real_ean FROM ean_aliases ORDER BY id ASC";
		queries["userid_rfid"]       = "SELECT user FROM rfid_users WHERE rfid = ?";
		queries["rfid_userid"]       = "SELECT rfid FROM rfid_users WHERE user = ?";
    queries["rfid_insert"]       = "INSERT OR REPLACE INTO rfid_users ('user','rfid') VALUES (?,?)";
    queries["rfid_delete_user"]  = "DELETE FROM rfid_users WHERE user = ? ";
		queries["statistic_products_day"]  								= "SELECT * FROM statistic_productsperday";
		queries["statistic_products_month"]  							= "SELECT * FROM statistic_productspermonth";
		queries["statistic_products_year"]  							= "SELECT * FROM statistic_productsperyear";
		queries["statistic_sales_day"]  									= "SELECT * FROM statistic_salesperday";
		queries["statistic_sales_month"]  								= "SELECT * FROM statistic_salespermonth";
		queries["statistic_sales_year"]  									= "SELECT * FROM statistic_salesperyear";
		queries["statistic_products_day_withDate"]  			= "SELECT * FROM statistic_productsperday where day = ?";
		queries["statistic_products_month_withMonthYear"] = "SELECT * FROM statistic_productspermonth where month = ? and year = ?";
		queries["statistic_products_year_withYear"]  			= "SELECT * FROM statistic_productsperyear where year = ?";
		queries["statistic_sales_day_withDate"]  					= "SELECT * FROM statistic_salesperday where day = ?";
		queries["statistic_sales_month_withMonthYear"]  	= "SELECT * FROM statistic_salespermonth where month = ? and year = ?";
		queries["statistic_sales_year_withYear"]  				= "SELECT * FROM statistic_salesperyear where year = ?";

		/* compile queries into statements */
		foreach(var entry in queries.entries) {
			statements[entry.key] = new Statement(db, entry.value);
		}
#if 0
		foreach(var key in queries.get_keys()) {
			statements[key] = new Statement(db, queries[key]);
		}
#endif
	}

	public GLib.HashTable<string,string> get_products() {
		var result = new GLib.HashTable<string,string>(null, null);
		statements["products"].reset();

		while(statements["products"].step() == Sqlite.ROW)
			result[statements["products"].column_text(0)] = statements["products"].column_text(1);

		return result;
	}

#if 0
	public stock get_stats_stock() {
		var result = new stock();
		var now = time_t();

		/* init products */
		statements["products"].reset();
		while(statements["products"].step() == Sqlite.ROW) {
			var id = uint64.parse(statements["products"].column_text(0));
			var name = statements["products"].column_text(1);
			int amount = int.parse(statements["products"].column_text(2));
			var product = new stock.product(id, name);
			result.add(product);
			product.add(now, amount);

			statements["stock_amount"].reset();
			statements["stock_amount"].bind_text(1, "%llu".printf(id));
			statements["stock_amount"].bind_text(2, "%llu".printf(id));

			while(statements["stock_amount"].step() == Sqlite.ROW) {
				var timestamp = uint64.parse(statements["stock_amount"].column_text(0));
				var diff = statements["stock_amount"].column_int(1);
				product.add(timestamp+1, amount);
				amount -= diff;
				product.add(timestamp, amount);
			}
		}

		return result;
	}
#endif

#if 0
	public profit_per_product get_stats_profit_per_products() {
		var result = new profit_per_product();

		statements["profit_by_product"].reset();
		statements["profit_by_product"].bind_int(1, 0);
		statements["profit_by_product"].bind_text(2, "99999999999999");

		while(statements["profit_by_product"].step() == Sqlite.ROW) {
			var name = statements["profit_by_product"].column_text(0);
			var profit = statements["profit_by_product"].column_int(1);
			result.add(name, profit);
		}

		return result;
	}
#endif

#if 0
	public profit_per_weekday get_stats_profit_per_weekday() {
		var result = new profit_per_weekday();

		var now = new DateTime.now_utc();
		var today = new DateTime.utc(now.get_year(), now.get_month(), now.get_day_of_month(), 8, 0, 0);
		var tomorrow = today.add_days(1);
		var weekday = tomorrow.get_day_of_week()-1;

		var to   = tomorrow.to_unix();
		var from = to - day_in_seconds;

		var weeks = 8;

		for(int i=0; i<weeks*7; i++) {
			statements["profit_complex"].reset();
			statements["profit_complex"].bind_text(1, "%llu".printf(from));
			statements["profit_complex"].bind_text(2, "%llu".printf(to));

			if(statements["profit_complex"].step() == Sqlite.ROW)
				result.day[weekday] += statements["profit_complex"].column_int(0);

			from-=day_in_seconds;
			to-=day_in_seconds;
			weekday = (weekday + 1) % 7;
		}

		for(int i=0; i<7; i++)
			result.day[i] /= weeks;

		return result;
	}
#endif

#if 0
	public profit_per_day get_stats_profit_per_day() {
		var result = new profit_per_day();
		var to   = time_t();
		var from = to - day_in_seconds;

		/* 8 weeks */
		for(int i=0; i<8*7; i++) {
			statements["profit_complex"].reset();
			statements["profit_complex"].bind_text(1, "%llu".printf(from));
			statements["profit_complex"].bind_text(2, "%llu".printf(to));
			statements["sales_complex"].reset();
			statements["sales_complex"].bind_text(1, "%llu".printf(from));
			statements["sales_complex"].bind_text(2, "%llu".printf(to));


			if(statements["profit_complex"].step() == Sqlite.ROW)
				result.add_profit(from, statements["profit_complex"].column_int(0));
			if(statements["sales_complex"].step() == Sqlite.ROW)
				result.add_sales(from, statements["sales_complex"].column_int(0));

			from-=day_in_seconds;
			to-=day_in_seconds;
		}

		return result;
	}
#endif

	public Product get_product_for_ean(uint64 ean) throws DatabaseError {
		Product product = Product();
		try {
			product.ean = ean_alias_get(ean);
			product.name = get_product_name(ean);
			product.memberprice = get_product_price(1, ean);
			product.guestprice = get_product_price(0, ean);
			return product;
		} catch(DatabaseError e){
			throw e;
		}
	}

	public StockEntry[] get_stock() {
		StockEntry[] result = {};

		statements["stock_status"].reset();
		while(statements["stock_status"].step() == Sqlite.ROW) {
			StockEntry entry = {
				statements["stock_status"].column_text(0),
				statements["stock_status"].column_text(1),
				statements["stock_status"].column_text(2),
				statements["stock_status"].column_int(3),
				statements["stock_status"].column_int(4),
				statements["stock_status"].column_int(5)
			};

			result += entry;
		}

		return result;
	}

	public PriceEntry[] get_prices(uint64 product) {
		PriceEntry[] result = {};

		statements["prices"].reset();
		statements["prices"].bind_text(1, "%llu".printf(product));
		while(statements["prices"].step() == Sqlite.ROW) {
			PriceEntry entry = {
				statements["prices"].column_int64(0),
				statements["prices"].column_int(1),
				statements["prices"].column_int(2)
			};

			result += entry;
		}

		return result;
	}

	public RestockEntry[] get_restocks(uint64 product, bool descending) {
		RestockEntry[] result = {};

		var statement = statements[descending ? "restocks_desc" : "restocks_asc"];

		statement.reset();
		statement.bind_text(1, "%llu".printf(product));
		while(statement.step() == Sqlite.ROW) {
			RestockEntry entry = {
				statement.column_int64(0),
				statement.column_int(1)
			};

			Price p = statement.column_int(2);
			entry.price = @"$p";
			entry.supplier = statement.column_int(3);
			entry.best_before_date = statement.column_int64(4);

			result += entry;
		}

		return result;
	}

	public bool buy(int32 user, uint64 article) throws DatabaseError {
		int rc = 0;
		int64 timestamp = (new DateTime.now_utc()).to_unix();

		statements["purchase"].reset();
		statements["purchase"].bind_int(1, user);
		statements["purchase"].bind_text(2, "%llu".printf(article));
		statements["purchase"].bind_text(3, "%llu".printf(timestamp));

		rc = statements["purchase"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);

		return true;
	}

	public string get_product_name(uint64 article) throws DatabaseError {
		statements["product_name"].reset();
		statements["product_name"].bind_text(1, "%llu".printf(article));

		int rc = statements["product_name"].step();

		switch(rc) {
			case Sqlite.ROW:
				return statements["product_name"].column_text(0);
			case Sqlite.DONE:
				throw new DatabaseError.PRODUCT_NOT_FOUND("unknown product: %llu", article);
			default:
				throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}
	}

	public string get_product_category(uint64 article) throws DatabaseError {
		statements["product_category"].reset();
		statements["product_category"].bind_text(1, "%llu".printf(article));

		int rc = statements["product_category"].step();

		switch(rc) {
			case Sqlite.ROW:
				return statements["product_category"].column_text(0);
			case Sqlite.DONE:
				throw new DatabaseError.PRODUCT_NOT_FOUND("unknown product: %llu", article);
			default:
				throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}
	}

	public int get_product_amount(uint64 article) throws DatabaseError {
		statements["product_amount"].reset();
		statements["product_amount"].bind_text(1, "%llu".printf(article));

		int rc = statements["product_amount"].step();

		switch(rc) {
			case Sqlite.ROW:
				return statements["product_amount"].column_int(0);
			case Sqlite.DONE:
				throw new DatabaseError.PRODUCT_NOT_FOUND("unknown product: %llu", article);
			default:
				throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}
	}

	public bool get_product_deprecated(uint64 article) throws DatabaseError {
		statements["product_deprecated"].reset();
		statements["product_deprecated"].bind_text(1, "%llu".printf(article));

		int rc = statements["product_deprecated"].step();

		switch(rc) {
			case Sqlite.ROW:
				return statements["product_deprecated"].column_int(0) == 1;
			case Sqlite.DONE:
				throw new DatabaseError.PRODUCT_NOT_FOUND("unknown product: %llu", article);
			default:
				throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}
	}

	public void product_deprecate(uint64 article, bool value) throws DatabaseError {
		int rc;

		statements["product_set_deprecated"].reset();
		statements["product_set_deprecated"].bind_int(1, value ? 1 : 0);
		statements["product_set_deprecated"].bind_text(2, "%llu".printf(article));

		rc = statements["product_set_deprecated"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
	}

	public Price get_product_price(int user, uint64 article) throws DatabaseError {
		int64 timestamp = (new DateTime.now_utc()).to_unix();
		bool member = user != 0;

		statements["price"].reset();
		statements["price"].bind_text(1, "%llu".printf(article));
		statements["price"].bind_text(2, "%lld".printf(timestamp));

		int rc = statements["price"].step();

		switch(rc) {
			case Sqlite.ROW:
				if(member)
					return statements["price"].column_int(0);
				else
					return statements["price"].column_int(1);
			case Sqlite.DONE:
				throw new DatabaseError.PRODUCT_NOT_FOUND("unknown product: %llu", article);
			default:
				throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}
	}

	public string undo(int32 user) throws DatabaseError {
		uint64 pid = 0;
		int rc = 0;
		string pname;

		statements["last_purchase"].reset();
		statements["last_purchase"].bind_int(1, user);

		rc = statements["last_purchase"].step();
		switch(rc) {
			case Sqlite.ROW:
				pid = uint64.parse(statements["last_purchase"].column_text(0));
				pname = get_product_name(pid);
				write_to_log("Remove purchase of %s", pname);
				break;
			case Sqlite.DONE:
				throw new DatabaseError.PRODUCT_NOT_FOUND("undo not possible without purchases");
			default:
				throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}

		statements["undo"].reset();
		statements["undo"].bind_int(1, user);

		rc = statements["undo"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);

		return pname;
	}

	public void restock(int user, uint64 product, uint amount, uint price, int supplier, int64 best_before_date) throws DatabaseError {
		int rc = 0;
		int64 timestamp = (new DateTime.now_utc()).to_unix();

		statements["stock"].reset();
		statements["stock"].bind_int(1, user);
		statements["stock"].bind_text(2, @"$product");
		statements["stock"].bind_text(3, @"$amount");
		statements["stock"].bind_text(4, @"$price");
		statements["stock"].bind_int64(5, timestamp);
		if(supplier > 0)
			statements["stock"].bind_int(6, supplier);
		else
			statements["stock"].bind_null(6);
		if(best_before_date > 0)
			statements["stock"].bind_int64(7, best_before_date);
		else
			statements["stock"].bind_null(7);

		rc = statements["stock"].step();

		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);

		this.publish_mqtt_stock_info();
	}

	public void new_product(uint64 id, string name, int category, int memberprice, int guestprice) throws DatabaseError {
		statements["product_create"].reset();
		statements["product_create"].bind_text(1, @"$id");
		statements["product_create"].bind_text(2, name);
		statements["product_create"].bind_int(3, category);
		statements["product_create"].bind_int(4, 0);
		int rc = statements["product_create"].step();

		if(rc == Sqlite.CONSTRAINT) {
			throw new DatabaseError.CONSTRAINT_FAILED(db.errmsg());
		} else if(rc != Sqlite.DONE) {
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}

		new_price(id, 0, memberprice, guestprice);

		this.publish_mqtt_stock_info();
	}

	public void new_price(uint64 product, int64 timestamp, int memberprice, int guestprice) throws DatabaseError {
		statements["price_create"].reset();
		statements["price_create"].bind_text(1, @"$product");
		statements["price_create"].bind_int64(2, timestamp);
		statements["price_create"].bind_int(3, memberprice);
		statements["price_create"].bind_int(4, guestprice);
		int rc = statements["price_create"].step();

		if(rc != Sqlite.DONE) {
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}
	}

	public bool check_user_password(int32 user, string password) {
		statements["password_get"].reset();
		statements["password_get"].bind_int(1, user);

		if(statements["password_get"].step() == Sqlite.ROW) {
			var pwhash_db = statements["password_get"].column_text(0);
			var pwhash_user = Checksum.compute_for_string(ChecksumType.SHA256, password);

			return pwhash_db == pwhash_user;
		} else {
			return false;
		}
	}

	public void set_user_password(int32 user, string password) throws DatabaseError {
		var pwhash = Checksum.compute_for_string(ChecksumType.SHA256, password);
		int rc;

		/* create user auth line if not existing */
		statements["user_auth_create"].reset();
		statements["user_auth_create"].bind_int(1, user);
		rc = statements["user_auth_create"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);

		/* set password */
		statements["password_set"].reset();
		statements["password_set"].bind_text(1, pwhash);
		statements["password_set"].bind_int(2, user);
		rc = statements["password_set"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
	}

	public void set_sessionid(int user, string sessionid) throws DatabaseError {
		statements["session_set"].reset();
		statements["session_set"].bind_text(1, sessionid);
		statements["session_set"].bind_int(2, user);

		int rc = statements["session_set"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
	}

	public int get_user_by_sessionid(string sessionid) throws DatabaseError {
		statements["session_get"].reset();
		statements["session_get"].bind_text(1, sessionid);

		if(statements["session_get"].step() == Sqlite.ROW) {
			return statements["session_get"].column_int(0);
		} else {
			throw new DatabaseError.SESSION_NOT_FOUND("No such session available in database!");
		}
	}

	public UserInfo get_user_info(int user) throws DatabaseError {
		var result = UserInfo();
		statements["userinfo"].reset();
		statements["userinfo"].bind_int(1, user);
		int rc = statements["userinfo"].step();

		if(rc == Sqlite.ROW) {
			result.id = user;
			result.firstname   = statements["userinfo"].column_text(0);
			result.lastname    = statements["userinfo"].column_text(1);
			result.email       = statements["userinfo"].column_text(2);
			result.gender      = statements["userinfo"].column_text(3);
			result.street      = statements["userinfo"].column_text(4);
			result.postcode    = statements["userinfo"].column_text(5);
			result.city        = statements["userinfo"].column_text(6);
			result.pgp         = statements["userinfo"].column_text(7);
			result.hidden      = statements["userinfo"].column_int(8) == 1;
			result.disabled	   = statements["userinfo"].column_int(9) == 1;
			result.soundTheme  = statements["userinfo"].column_text(10);
			result.joined_at   = statements["userinfo"].column_int64(11);
			result.language    = statements["userinfo"].column_text(12);
		} else if(rc == Sqlite.DONE) {
			throw new DatabaseError.USER_NOT_FOUND("user not found");
		} else {
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}

		statements["rfid_userid"].reset();
    statements["rfid_userid"].bind_int(1, user);
    rc = statements["rfid_userid"].step();

    string[] rfid = {};

    while(rc == Sqlite.ROW) {
    	//string rfidcode = statements["rfid_userid"].column_text(0);
      rfid += statements["rfid_userid"].column_text(0);

      rc = statements["rfid_userid"].step();
    }

    result.rfid = rfid;

		return result;
	}

	public UserAuth get_user_auth(int user) throws DatabaseError {
		var result = UserAuth();
		result.id = user;
		result.superuser = false;
		result.auth_cashbox = false;
		result.auth_products = false;
		result.auth_users = false;

		statements["userauth"].reset();
		statements["userauth"].bind_int(1, user);
		int rc = statements["userauth"].step();

		if(rc == Sqlite.ROW) {
			result.superuser = statements["userauth"].column_int(0) == 1;
			result.auth_users = statements["userauth"].column_int(1) == 1;
			result.auth_products = statements["userauth"].column_int(2) == 1;
			result.auth_cashbox = statements["userauth"].column_int(3) == 1;
		} else if(rc == Sqlite.DONE) {
			/* entry not found, we return defaults */
		} else {
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}

		return result;
	}

	public void set_user_auth(UserAuth auth) throws DatabaseError {
		int rc;

		/* create user auth line if not existing */
		statements["user_auth_create"].reset();
		statements["user_auth_create"].bind_int(1, auth.id);
		rc = statements["user_auth_create"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);

		/* set authentication */
		statements["userauth_set"].reset();
		statements["userauth_set"].bind_int(1, auth.auth_users ? 1 : 0);
		statements["userauth_set"].bind_int(2, auth.auth_products ? 1 : 0);
		statements["userauth_set"].bind_int(3, auth.auth_cashbox ? 1 : 0);
		statements["userauth_set"].bind_int(4, auth.id);

		rc = statements["userauth_set"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
	}

	public string get_username(int user) throws DatabaseError {
		statements["username"].reset();
		statements["username"].bind_int(1, user);

		if(statements["username"].step() == Sqlite.ROW) {
			return statements["username"].column_text(0)+" "+statements["username"].column_text(1);
		} else {
			throw new DatabaseError.USER_NOT_FOUND("No such user available in database!");
		}
	}

	public string get_user_theme(int user, string fallback) throws DatabaseError {
		statements["user_theme_get"].reset();
		statements["user_theme_get"].bind_text(1, fallback);
		statements["user_theme_get"].bind_int(2, user);

		if(statements["user_theme_get"].step() == Sqlite.ROW) {
			return statements["user_theme_get"].column_text(0);
		} else {
			throw new DatabaseError.USER_NOT_FOUND("No such user available in database!");
		}
	}

	public string get_user_language(int user, string fallback) throws DatabaseError {
		statements["user_language_get"].reset();
		statements["user_language_get"].bind_text(1, fallback);
		statements["user_language_get"].bind_int(2, user);

		if(statements["user_language_get"].step() == Sqlite.ROW) {
			return statements["user_language_get"].column_text(0);
		} else {
			throw new DatabaseError.USER_NOT_FOUND("No such user available in database!");
		}
	}

	public void set_userTheme(int user, string userTheme) throws DatabaseError {
		statements["user_theme_set"].reset();
		if (userTheme == "") {
			statements["user_theme_set"].bind_null(1);
		} else {
			statements["user_theme_set"].bind_text(1, userTheme);
		}
		statements["user_theme_set"].bind_int(2, user);

		int rc = statements["user_theme_set"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
	}

	public void set_userLanguage(int user, string language) throws DatabaseError {
		statements["user_language_set"].reset();
		if (language == "") {
			statements["user_language_set"].bind_null(1);
		} else {
			statements["user_language_set"].bind_text(1, language);
		}
		statements["user_language_set"].bind_int(2, user);

		int rc = statements["user_language_set"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
	}

	public InvoiceEntry[] get_invoice(int user, int64 from=0, int64 to=-1) throws DatabaseError {
		InvoiceEntry[] result = {};

		if(to == -1) {
			to = time_t();
		}

		statements["invoice"].reset();
		statements["invoice"].bind_int(1, user);
		statements["invoice"].bind_int64(2, from);
		statements["invoice"].bind_int64(3, to);
		int rc = statements["invoice"].step();

		while(rc == Sqlite.ROW) {
			InvoiceEntry entry = {};
			entry.timestamp = statements["invoice"].column_int64(0);
			entry.product.ean = uint64.parse(statements["invoice"].column_text(1));
			entry.product.name = statements["invoice"].column_text(2);
			entry.price = statements["invoice"].column_int(3);
			result += entry;

			rc = statements["invoice"].step();
		}

		if(rc != Sqlite.DONE) {
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}

		return result;
	}

	public Sale[] get_sales(int64 from=0, int64 to=-1) throws DatabaseError {
		Sale[] result = {};

		if(to == -1) {
			to = time_t();
		}

		statements["sales"].reset();
		statements["sales"].bind_int64(1, from);
		statements["sales"].bind_int64(2, to);
		int rc = statements["sales"].step();

		while(rc == Sqlite.ROW) {
			Sale entry = {};
			entry.timestamp 			= statements["sales"].column_int64(0);
			entry.ean							= statements["sales"].column_int64(1);
			entry.productname			= statements["sales"].column_text(2);
			entry.userId					= statements["sales"].column_int(3);
			entry.userFirstname		= statements["sales"].column_text(4);
			entry.userLastname		= statements["sales"].column_text(5);
			entry.price						= statements["sales"].column_int(6);

			result += entry;

			rc = statements["sales"].step();
		}

		if(rc != Sqlite.DONE) {
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}

		return result;
	}

	public int64 get_first_purchase(int user) {
		statements["purchase_first"].reset();
		statements["purchase_first"].bind_int(1, user);

		if(statements["purchase_first"].step() == Sqlite.ROW)
			return statements["purchase_first"].column_int64(0);
		else
			return 0;
	}

	public int64 get_last_purchase(int user) {
		statements["purchase_last"].reset();
		statements["purchase_last"].bind_int(1, user);

		if(statements["purchase_last"].step() == Sqlite.ROW)
			return statements["purchase_last"].column_int64(0);
		else
			return 0;
	}

	public StatsInfo get_stats_info() {
		var result = StatsInfo();

		DateTime now = new DateTime.now_local();
		DateTime today = new DateTime.local(now.get_year(), now.get_month(), now.get_hour() < 8 ? now.get_day_of_month()-1 : now.get_day_of_month(), 8, 0, 0);
		DateTime month = new DateTime.local(now.get_year(), now.get_month(), 1, 0, 0, 0);

		DateTime last4weeks = now.add_days(-28);
		DateTime last4months = now.add_months(-4);

		statements["count_articles"].reset();
		if(statements["count_articles"].step() == Sqlite.ROW)
			result.count_articles = statements["count_articles"].column_int(0);

		statements["count_users"].reset();
		if(statements["count_users"].step() == Sqlite.ROW)
			result.count_users = statements["count_users"].column_int(0);

		statements["stock_value"].reset();
		if(statements["stock_value"].step() == Sqlite.ROW)
			result.stock_value = statements["stock_value"].column_int(0);

		statements["total_sales"].reset();
		statements["total_sales"].bind_int64(1, 0);
		if(statements["total_sales"].step() == Sqlite.ROW)
			result.sales_total = statements["total_sales"].column_int(0);

		statements["total_profit"].reset();
		statements["total_profit"].bind_int64(1, 0);
		if(statements["total_profit"].step() == Sqlite.ROW)
			result.profit_total = statements["total_profit"].column_int(0);

		statements["total_sales"].reset();
		statements["total_sales"].bind_int64(1, today.to_unix());
		if(statements["total_sales"].step() == Sqlite.ROW)
			result.sales_today = statements["total_sales"].column_int(0);

		statements["total_profit"].reset();
		statements["total_profit"].bind_int64(1, today.to_unix());
		if(statements["total_profit"].step() == Sqlite.ROW)
			result.profit_today = statements["total_profit"].column_int(0);

		statements["total_sales"].reset();
		statements["total_sales"].bind_int64(1, month.to_unix());
		if(statements["total_sales"].step() == Sqlite.ROW)
			result.sales_this_month = statements["total_sales"].column_int(0);

		statements["total_profit"].reset();
		statements["total_profit"].bind_int64(1, month.to_unix());
		if(statements["total_profit"].step() == Sqlite.ROW)
			result.profit_this_month = statements["total_profit"].column_int(0);

		statements["total_sales"].reset();
		statements["total_sales"].bind_int64(1, last4weeks.to_unix());
		if(statements["total_sales"].step() == Sqlite.ROW)
			result.sales_per_day = statements["total_sales"].column_int(0) / 28;

		statements["total_profit"].reset();
		statements["total_profit"].bind_int64(1, last4weeks.to_unix());
		if(statements["total_profit"].step() == Sqlite.ROW)
			result.profit_per_day = statements["total_profit"].column_int(0) / 28;

		statements["total_sales"].reset();
		statements["total_sales"].bind_int64(1, last4months.to_unix());
		if(statements["total_sales"].step() == Sqlite.ROW)
			result.sales_per_month = statements["total_sales"].column_int(0) / 4;

		statements["total_profit"].reset();
		statements["total_profit"].bind_int64(1, last4months.to_unix());
		if(statements["total_profit"].step() == Sqlite.ROW)
			result.profit_per_month = statements["total_profit"].column_int(0) / 4;

		return result;
	}

	public int[] get_member_ids() {
		int[] result = {};

		statements["user_get_ids"].reset();
		while(statements["user_get_ids"].step() == Sqlite.ROW)
			result += statements["user_get_ids"].column_int(0);

		return result;
	}

	public void user_disable(int user, bool value) throws DatabaseError {
		int rc;

		/* create user auth line if not existing */
		statements["user_auth_create"].reset();
		statements["user_auth_create"].bind_int(1, user);
		rc = statements["user_auth_create"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);

		/* set disabled flag */
		statements["user_disable"].reset();
		statements["user_disable"].bind_int(1, value ? 1 : 0);
		statements["user_disable"].bind_int(2, user);
		rc = statements["user_disable"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
	}

	public void user_replace(UserInfo u) throws DatabaseError {
		statements["user_replace"].reset();
		statements["user_replace"].bind_int(1, u.id);
		statements["user_replace"].bind_text(2, u.email);
		statements["user_replace"].bind_text(3, u.firstname);
		statements["user_replace"].bind_text(4, u.lastname);
		statements["user_replace"].bind_text(5, u.gender);
		statements["user_replace"].bind_text(6, u.street);
		statements["user_replace"].bind_text(7, u.postcode);
		statements["user_replace"].bind_text(8, u.city);
		statements["user_replace"].bind_text(9, u.pgp);
		statements["user_replace"].bind_int(10, u.hidden ? 1 : 0);
		statements["user_replace"].bind_int(11, u.disabled ? 1 : 0);
		statements["user_replace"].bind_int64(12, u.joined_at);
		statements["user_replace"].bind_text(13, u.soundTheme != "" ? u.soundTheme : null);
		statements["user_replace"].bind_text(14, u.language != "" ? u.language : null);

		int rc = statements["user_replace"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);

		statements["rfid_delete_user"].reset();
		statements["rfid_delete_user"].bind_int(1, u.id);
	  	rc = statements["rfid_delete_user"].step();
		if(rc != Sqlite.DONE)
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);

		foreach (string rfid in u.rfid) {
			statements["rfid_insert"].reset();
			statements["rfid_insert"].bind_int(1, u.id);
			statements["rfid_insert"].bind_text(2, rfid);
			rc = statements["rfid_insert"].step();
			if(rc != Sqlite.DONE)
				throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}
	}

	public bool user_is_disabled(int user) throws DatabaseError {
		return get_user_info(user).disabled;
	}

	public bool user_exists(int user) throws DatabaseError {
		if(user in get_member_ids())
			return true;
		return false;
	}

	public bool user_equals(UserInfo u) throws DatabaseError {
		var dbu = get_user_info(u.id);
		return u.equals(dbu);
	}

	public int64 get_timestamp_of_last_purchase() {
		statements["last_timestamp"].reset();
		if(statements["last_timestamp"].step() != Sqlite.ROW)
			return 0;
		return statements["last_timestamp"].column_int64(0);
	}

	public Category[] get_category_list() {
		Category[] result = {};

		statements["category_list"].reset();
		while(statements["category_list"].step() == Sqlite.ROW) {
			Category entry = {
				statements["category_list"].column_int(0),
				statements["category_list"].column_text(1)
			};

			result += entry;
		}

		return result;
	}

	public Supplier[] get_supplier_list() {
		Supplier[] result = {};

		statements["supplier_list"].reset();
		while(statements["supplier_list"].step() == Sqlite.ROW) {
			Supplier entry = {
				statements["supplier_list"].column_int64(0),
				statements["supplier_list"].column_text(1),
				statements["supplier_list"].column_text(2),
				statements["supplier_list"].column_text(3),
				statements["supplier_list"].column_text(4),
				statements["supplier_list"].column_text(5),
				statements["supplier_list"].column_text(6)
			};

			result += entry;
		}

		return result;
	}

	public Supplier get_supplier(int id) {
		Supplier result = Supplier();

		statements["supplier_get"].reset();
		statements["supplier_get"].bind_int(1, id);

		if(statements["supplier_get"].step() != Sqlite.ROW) {
			result.id = 0;
			result.name = "Unknown";
			result.postal_code = "";
			result.city = "";
			result.street = "";
			result.phone = "";
			result.website = "";
		} else {
			result.id = statements["supplier_get"].column_int64(0);
			result.name = statements["supplier_get"].column_text(1);
			result.postal_code = statements["supplier_get"].column_text(2);
			result.city = statements["supplier_get"].column_text(3);
			result.street = statements["supplier_get"].column_text(4);
			result.phone = statements["supplier_get"].column_text(5);
			result.website = statements["supplier_get"].column_text(6);
		}

		return result;
	}

	public void add_supplier(string name, string postal_code, string city, string street, string phone, string website) throws DatabaseError {
		statements["supplier_add"].reset();
		statements["supplier_add"].bind_text(1, name);
		statements["supplier_add"].bind_text(2, postal_code);
		statements["supplier_add"].bind_text(3, city);
		statements["supplier_add"].bind_text(4, street);
		statements["supplier_add"].bind_text(5, phone);
		statements["supplier_add"].bind_text(6, website);
		int rc = statements["supplier_add"].step();

		if(rc != Sqlite.DONE) {
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}
	}

	public int[] get_users_with_sales(int64 timestamp_from, int64 timestamp_to) {
		var result = new int[0];
		statements["users_with_sales"].reset();
		statements["users_with_sales"].bind_int64(1, timestamp_from);
		statements["users_with_sales"].bind_int64(2, timestamp_to);

		while(statements["users_with_sales"].step() == Sqlite.ROW) {
			result += statements["users_with_sales"].column_int(0);
		}

		return result;
	}

	public Price get_user_invoice_sum(int user, int64 timestamp_from, int64 timestamp_to) {
		Price result = 0;

		statements["user_invoice_sum"].reset();
		statements["user_invoice_sum"].bind_int(1, user);
		statements["user_invoice_sum"].bind_int64(2, timestamp_from);
		statements["user_invoice_sum"].bind_int64(3, timestamp_to);

		if(statements["user_invoice_sum"].step() == Sqlite.ROW)
			result = statements["user_invoice_sum"].column_int(0);

		return result;
	}

	public Price cashbox_status() {
		Price result = 0;

		statements["cashbox_status"].reset();

		if(statements["cashbox_status"].step() == Sqlite.ROW)
			result = statements["cashbox_status"].column_int(0);

		return result;
	}

	public void cashbox_add(int user, Price amount, int64 timestamp) throws DatabaseError {
		statements["cashbox_add"].reset();
		statements["cashbox_add"].bind_int(1, user);
		statements["cashbox_add"].bind_int(2, amount);
		statements["cashbox_add"].bind_int64(3, timestamp);

		int rc = statements["cashbox_add"].step();

		if(rc != Sqlite.DONE) {
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}
	}

	public CashboxDiff[] cashbox_history() {
		CashboxDiff[] result = {};

		statements["cashbox_history"].reset();

		while(statements["cashbox_history"].step() == Sqlite.ROW) {
			CashboxDiff entry = {
				statements["cashbox_history"].column_int(0),
				statements["cashbox_history"].column_int(1),
				statements["cashbox_history"].column_int64(2),
			};

			result += entry;
		};

		return result;
	}

	public CashboxDiff[] cashbox_changes(int64 start, int64 stop) {
		CashboxDiff[] result = {};

		statements["cashbox_changes"].reset();
		statements["cashbox_changes"].bind_int64(1, start);
		statements["cashbox_changes"].bind_int64(2, stop);

		while(statements["cashbox_changes"].step() == Sqlite.ROW) {
			CashboxDiff entry = {
				statements["cashbox_changes"].column_int(0),
				statements["cashbox_changes"].column_int(1),
				statements["cashbox_changes"].column_int64(2),
			};

			result += entry;
		};

		return result;
	}

	public void ean_alias_add(uint64 ean, uint64 real_ean) throws DatabaseError {
		statements["alias_ean_add"].reset();
		statements["alias_ean_add"].bind_text(1, "%llu".printf(ean));
		statements["alias_ean_add"].bind_text(2, "%llu".printf(real_ean));

		int rc = statements["alias_ean_add"].step();

		if(rc != Sqlite.DONE) {
			throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}
	}

	public uint64 ean_alias_get(uint64 ean) {
		uint64 result = ean;

		statements["alias_ean_get"].reset();
		statements["alias_ean_get"].bind_text(1, "%llu".printf(ean));

		if(statements["alias_ean_get"].step() == Sqlite.ROW)
			result = statements["alias_ean_get"].column_int64(0);

		return result;
	}

	public EanAlias[] ean_alias_list() {
		EanAlias[] result = {};

		statements["alias_ean_list"].reset();

		while(statements["alias_ean_list"].step() == Sqlite.ROW) {
			EanAlias entry = {
				statements["alias_ean_list"].column_int64(0),
				statements["alias_ean_list"].column_int64(1),
			};

			result += entry;
		};
		return result;
	}

	public static int sortBestBeforeEntry(BestBeforeEntry? a, BestBeforeEntry? b) {
		if(a.best_before_date == b.best_before_date)
			return 0;
		else if(a.best_before_date < b.best_before_date)
			return -1;
		else
			return 1;
	}

	public BestBeforeEntry?[] bestbeforelist() {
		var bbdlist = new GLib.GenericArray<BestBeforeEntry?>();

		foreach(var product in get_stock()) {
			var amount = product.amount;
			var pid = uint64.parse(product.id);

			if(amount <= 0)
				continue;

			foreach(var restock in get_restocks(pid, true)) {
				if (restock.amount > amount) {
					BestBeforeEntry entry = { pid, product.name, amount, restock.best_before_date };
					bbdlist.add(entry);
				} else {
					BestBeforeEntry entry = { pid, product.name, restock.amount, restock.best_before_date };
					bbdlist.add(entry);
				}

				amount -= restock.amount;
				if(amount <= 0)
					break;
			}
		}

		bbdlist.sort(sortBestBeforeEntry);

		return bbdlist.data;
	}

	public int get_userid_for_rfid(string rfid) throws IOError, DatabaseError{
		statements["userid_rfid"].reset();
		statements["userid_rfid"].bind_text(1, rfid);

		int rc = statements["userid_rfid"].step();

		switch(rc) {
			case Sqlite.ROW:
				return statements["userid_rfid"].column_int(0);
			case Sqlite.DONE:
				throw new DatabaseError.RFID_NOT_FOUND("unknown rfid: %s", rfid);
			default:
				throw new DatabaseError.INTERNAL_ERROR("internal error: %d", rc);
		}
	}

	public StatisticProductsPerDay[] get_statistic_products_per_day() throws DatabaseError {
		StatisticProductsPerDay[] result = {};

		statements["statistic_products_day"].reset();

		while(statements["statistic_products_day"].step() == Sqlite.ROW) {
			StatisticProductsPerDay entry = {
				statements["statistic_products_day"].column_text(0),
				statements["statistic_products_day"].column_int64(1),
				statements["statistic_products_day"].column_int(2),
				statements["statistic_products_day"].column_text(3),
				statements["statistic_products_day"].column_int64(4)
			};

			result += entry;
		}

		return result;
	}

	public StatisticProductsPerDay[] get_statistic_products_per_day_withDate(string date) throws DatabaseError {
		StatisticProductsPerDay[] result = {};

		statements["statistic_products_day_withDate"].reset();
		statements["statistic_products_day_withDate"].bind_text(1, date);

		while(statements["statistic_products_day_withDate"].step() == Sqlite.ROW) {
			StatisticProductsPerDay entry = {
				statements["statistic_products_day_withDate"].column_text(0),
				statements["statistic_products_day_withDate"].column_int64(1),
				statements["statistic_products_day_withDate"].column_int(2),
				statements["statistic_products_day_withDate"].column_text(3),
				statements["statistic_products_day_withDate"].column_int64(4)
			};

			result += entry;
		}

		return result;
	}

	public StatisticProductsPerMonth[] get_statistic_products_per_month() throws DatabaseError {
		StatisticProductsPerMonth[] result = {};

		statements["statistic_products_month"].reset();

		while(statements["statistic_products_month"].step() == Sqlite.ROW) {
			StatisticProductsPerMonth entry = {
				statements["statistic_products_month"].column_text(0),
				statements["statistic_products_month"].column_text(1),
				statements["statistic_products_month"].column_int64(2),
				statements["statistic_products_month"].column_int(3),
				statements["statistic_products_month"].column_text(4),
				statements["statistic_products_month"].column_int64(5)
			};

			result += entry;
		}

		return result;
	}

	public StatisticProductsPerMonth[] get_statistic_products_per_month_withMonthYear(string month, string year) throws DatabaseError {
		StatisticProductsPerMonth[] result = {};

		statements["statistic_products_month_withMonthYear"].reset();
		statements["statistic_products_month_withMonthYear"].bind_text(1, month);
		statements["statistic_products_month_withMonthYear"].bind_text(2, year);

		while(statements["statistic_products_month_withMonthYear"].step() == Sqlite.ROW) {
			StatisticProductsPerMonth entry = {
				statements["statistic_products_month_withMonthYear"].column_text(0),
				statements["statistic_products_month_withMonthYear"].column_text(1),
				statements["statistic_products_month_withMonthYear"].column_int64(2),
				statements["statistic_products_month_withMonthYear"].column_int(3),
				statements["statistic_products_month_withMonthYear"].column_text(4),
				statements["statistic_products_month_withMonthYear"].column_int64(5)
			};

			result += entry;
		}

	 return result;
  }

	public StatisticProductsPerYear[] get_statistic_products_per_year() throws DatabaseError {
		StatisticProductsPerYear[] result = {};

		statements["statistic_products_year"].reset();

		while(statements["statistic_products_year"].step() == Sqlite.ROW) {
			StatisticProductsPerYear entry = {
				statements["statistic_products_year"].column_text(0),
				statements["statistic_products_year"].column_int64(1),
				statements["statistic_products_year"].column_int(2),
				statements["statistic_products_year"].column_text(3),
				statements["statistic_products_year"].column_int64(4)
			};

			result += entry;
		}

		return result;
	}

	public StatisticProductsPerYear[] get_statistic_products_per_year_withYear(string year) throws DatabaseError {
		StatisticProductsPerYear[] result = {};

		statements["statistic_products_year_withYear"].reset();
		statements["statistic_products_year_withYear"].bind_text(1, year);

		while(statements["statistic_products_year_withYear"].step() == Sqlite.ROW) {
			StatisticProductsPerYear entry = {
				statements["statistic_products_year_withYear"].column_text(0),
				statements["statistic_products_year_withYear"].column_int64(1),
				statements["statistic_products_year_withYear"].column_int(2),
				statements["statistic_products_year_withYear"].column_text(3),
				statements["statistic_products_year_withYear"].column_int64(4)
			};

			result += entry;
		}

		return result;
	}

	public StatisticSalesPerDay[] get_statistic_sales_per_day() throws DatabaseError {
		StatisticSalesPerDay[] result = {};

		statements["statistic_sales_day"].reset();

		while(statements["statistic_sales_day"].step() == Sqlite.ROW) {
			StatisticSalesPerDay entry = {
				statements["statistic_sales_day"].column_text(0),
				statements["statistic_sales_day"].column_int64(1),
				statements["statistic_sales_day"].column_int(2)
			};

			result += entry;
		}

		return result;
	}

	public StatisticSalesPerDay[] get_statistic_sales_per_day_withDate(string date) throws DatabaseError {
		StatisticSalesPerDay[] result = {};

		statements["statistic_sales_day_withDate"].reset();
		statements["statistic_sales_day_withDate"].bind_text(1, date);

		while(statements["statistic_sales_day_withDate"].step() == Sqlite.ROW) {
			StatisticSalesPerDay entry = {
				statements["statistic_sales_day_withDate"].column_text(0),
				statements["statistic_sales_day_withDate"].column_int64(1),
				statements["statistic_sales_day_withDate"].column_int(2)
			};

			result += entry;
		}

		return result;
	}

	public StatisticSalesPerMonth[] get_statistic_sales_per_month() throws DatabaseError {
		StatisticSalesPerMonth[] result = {};

		statements["statistic_sales_month"].reset();

		while(statements["statistic_sales_month"].step() == Sqlite.ROW) {
			StatisticSalesPerMonth entry = {
				statements["statistic_sales_month"].column_text(0),
				statements["statistic_sales_month"].column_text(1),
				statements["statistic_sales_month"].column_int64(2),
				statements["statistic_sales_month"].column_int(3)
			};

			result += entry;
		}

		return result;
	}

	public StatisticSalesPerMonth[] get_statistic_sales_per_month_withMonthYear(string month, string year) throws DatabaseError {
		StatisticSalesPerMonth[] result = {};

		statements["statistic_sales_month_withMonthYear"].reset();
		statements["statistic_sales_month_withMonthYear"].bind_text(1, month);
		statements["statistic_sales_month_withMonthYear"].bind_text(2, year);

		while(statements["statistic_sales_month_withMonthYear"].step() == Sqlite.ROW) {
			StatisticSalesPerMonth entry = {
				statements["statistic_sales_month_withMonthYear"].column_text(0),
				statements["statistic_sales_month_withMonthYear"].column_text(1),
				statements["statistic_sales_month_withMonthYear"].column_int64(2),
				statements["statistic_sales_month_withMonthYear"].column_int(3)
			};

			result += entry;
		}

		return result;
	}

	public StatisticSalesPerYear[] get_statistic_sales_per_year() throws DatabaseError {
		StatisticSalesPerYear[] result = {};

		statements["statistic_sales_year"].reset();

		while(statements["statistic_sales_year"].step() == Sqlite.ROW) {
			StatisticSalesPerYear entry = {
				statements["statistic_sales_year"].column_text(0),
				statements["statistic_sales_year"].column_int64(1),
				statements["statistic_sales_year"].column_int(2)
			};

			result += entry;
		}

		return result;
	}

	public StatisticSalesPerYear[] get_statistic_sales_per_year_withYear(string year) throws DatabaseError {
		StatisticSalesPerYear[] result = {};

		statements["statistic_sales_year_withYear"].reset();
		statements["statistic_sales_year_withYear"].bind_text(1, year);

		while(statements["statistic_sales_year_withYear"].step() == Sqlite.ROW) {
			StatisticSalesPerYear entry = {
				statements["statistic_sales_year_withYear"].column_text(0),
				statements["statistic_sales_year_withYear"].column_int64(1),
				statements["statistic_sales_year_withYear"].column_int(2)
			};

			result += entry;
		}

		return result;
	}

	public void publish_mqtt_stock_info() {
		StockEntry[] stockData = this.get_stock();

		string[] articles = {};
		foreach (StockEntry e in stockData) {
			articles += "{\"ean\":\"%s\",\"name\":\"%s\",\"category\":\"%s\",\"amount\":\"%i\",\"memberprice\":\"%s\",\"guestprice\":\"%s\"}".printf(e.id,e.name,e.category,e.amount,e.memberprice.to_string(),e.guestprice.to_string());
		}
		string message = "["+ string.joinv(",",articles) +"]";
		try {
			mqtt.push_message(message,this.cfg.get_string("MQTT", "stockInfoTopic"));
		} catch (Error e) {
			error("Error: %s\n",e.message);
		}
	}

}
