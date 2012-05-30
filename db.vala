public class Database {
	private Sqlite.Database db;
	private Sqlite.Statement product_stmt;
	private Sqlite.Statement purchase_stmt1;
	private Sqlite.Statement purchase_stmt2;
	private Sqlite.Statement undo_stmt1;
	private Sqlite.Statement undo_stmt2;
	private Sqlite.Statement undo_stmt3;
	private Sqlite.Statement stock_stmt1;
	private Sqlite.Statement stock_stmt2;
	int32 user = 0;
	uint64 product = 0;
	bool logged_in = false;
	bool stock_mode = false;
	private static string product_query = "SELECT name FROM products WHERE id = ?";
	private static string purchase_query1 = "INSERT INTO purchases ('user', 'product', 'timestamp') VALUES (?, ?, ?)";
	private static string purchase_query2 = "UPDATE products SET amount = amount - 1 WHERE id = ?";
	private static string undo_query1 = "SELECT product FROM purchases WHERE user = ? ORDER BY timestamp DESC LIMIT 1";
	private static string undo_query2 = "DELETE FROM purchases WHERE user = ? ORDER BY timestamp DESC LIMIT 1";
	private static string undo_query3 = "UPDATE products SET amount = amount + 1 WHERE id = ?";
	private static string stock_query1 = "INSERT INTO restock ('user', 'product', 'amount', 'timestamp') VALUES (?, ?, ?, ?)";
	private static string stock_query2 = "UPDATE products SET amount = amount + ? WHERE id = ?";

	public Database(string file) {
		int rc;

		rc = Sqlite.Database.open (file, out db);
		if(rc != Sqlite.OK) {
			error("could not open database!");
		}

		rc = this.db.prepare_v2(purchase_query1, -1, out purchase_stmt1);
		if(rc != Sqlite.OK) {
			error("could not prepare first purchase statement!");
		}

		rc = this.db.prepare_v2(purchase_query2, -1, out purchase_stmt2);
		if(rc != Sqlite.OK) {
			error("could not prepare second purchase statement!");
		}

		rc = this.db.prepare_v2(product_query, -1, out product_stmt);
		if(rc != Sqlite.OK) {
			error("could not prepare article statement!");
		}

		rc = this.db.prepare_v2(undo_query1, -1, out undo_stmt1);
		if(rc != Sqlite.OK) {
			error("could not prepare first undo statement!");
		}

		rc = this.db.prepare_v2(undo_query2, -1, out undo_stmt2);
		if(rc != Sqlite.OK) {
			error("could not prepare second undo statement!");
		}

		rc = this.db.prepare_v2(undo_query3, -1, out undo_stmt3);
		if(rc != Sqlite.OK) {
			error("could not prepare third undo statement!");
		}

		rc = this.db.prepare_v2(stock_query1, -1, out stock_stmt1);
		if(rc != Sqlite.OK) {
			error("could not prepare first stock statement!");
		}

		rc = this.db.prepare_v2(stock_query2, -1, out stock_stmt2);
		if(rc != Sqlite.OK) {
			error("could not prepare second stock statement!");
		}

	}

	public bool login(int32 id) {
		this.user = id;
		this.logged_in = true;
		return true;
	}

	public bool logout() {
		this.user = 0;
		this.stock_mode = false;
		this.logged_in = false;
		return true;
	}

	public bool buy(uint64 article) {
		if(is_logged_in()) {
			int rc = 0;
			int64 timestamp = (new DateTime.now_utc()).to_unix();

			this.purchase_stmt1.reset();
			this.purchase_stmt1.bind_text(1, "%d".printf(user));
			this.purchase_stmt1.bind_text(2, "%llu".printf(article));
			this.purchase_stmt1.bind_text(3, "%llu".printf(timestamp));

			rc = this.purchase_stmt1.step();
			if(rc != Sqlite.DONE)
				error("[interner Fehler: %d]".printf(rc));

			this.purchase_stmt2.reset();
			this.purchase_stmt2.bind_text(1, "%llu".printf(article));

			rc = this.purchase_stmt2.step();
			if(rc != Sqlite.DONE)
				error("[interner Fehler: %d]".printf(rc));

			return true;
		} else {
			return false;
		}
	}

	public string get_product_name(uint64 article) {
		this.product_stmt.reset();
		this.product_stmt.bind_text(1, "%llu".printf(article));

		int rc = this.product_stmt.step();

		switch(rc) {
			case Sqlite.ROW:
				return this.product_stmt.column_text(0);
			case Sqlite.DONE:
				return "unbekanntes Produkt: %llu".printf(article);
			default:
				return "[interner Fehler: %d]".printf(rc);
		}
	}

	public bool undo() {
		if(is_logged_in()) {
			uint64 pid = 0;
			int rc = 0;

			this.undo_stmt1.reset();
			this.undo_stmt1.bind_text(1, "%d".printf(user));

			rc = this.undo_stmt1.step();
			switch(rc) {
				case Sqlite.ROW:
					pid = uint64.parse(this.undo_stmt1.column_text(0));
					break;
				case Sqlite.DONE:
					stdout.printf("undo not possible without purchases\n");
					return false;
				default:
					error("[interner Fehler: %d]".printf(rc));
			}

			this.undo_stmt2.reset();
			this.undo_stmt2.bind_text(1, "%d".printf(user));

			rc = this.undo_stmt2.step();
			if(rc != Sqlite.DONE)
				error("[interner Fehler: %d]".printf(rc));

			this.undo_stmt3.reset();
			this.undo_stmt3.bind_text(1, "%llu".printf(pid));

			rc = this.undo_stmt3.step();
			if(rc != Sqlite.DONE)
				error("[interner Fehler: %d]".printf(rc));

			return true;
		}

		return false;
	}

	public bool choose_stock_product(uint64 id) {
		if(is_in_stock_mode()) {
			product = id;
			return true;
		}
		return false;
	}

	public bool add_stock_product(uint64 amount) {
		if(is_in_stock_mode() && product != 0) {
			int rc = 0;
			int64 timestamp = (new DateTime.now_utc()).to_unix();

			this.stock_stmt1.reset();
			this.stock_stmt1.bind_text(1, "%d".printf(user));
			this.stock_stmt1.bind_text(2, "%llu".printf(product));
			this.stock_stmt1.bind_text(3, "%llu".printf(amount));
			this.stock_stmt1.bind_text(4, "%llu".printf(timestamp));

			rc = this.stock_stmt1.step();
			if(rc != Sqlite.DONE)
				error("[interner Fehler: %d]".printf(rc));

			this.stock_stmt2.reset();
			this.stock_stmt2.bind_text(1, "%llu".printf(amount));
			this.stock_stmt2.bind_text(2, "%llu".printf(product));

			rc = this.stock_stmt2.step();
			if(rc != Sqlite.DONE)
				error("[interner Fehler: %d]".printf(rc));

			return true;
		}

		return false;
	}

	public bool go_into_stock_mode() {
		if(is_logged_in())
			stock_mode = true;
		return stock_mode;
	}

	public bool is_logged_in() {
		return this.logged_in;
	}

	public bool is_in_stock_mode() {
		return this.stock_mode;
	}
}
