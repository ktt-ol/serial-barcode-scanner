public class Database {
	private Sqlite.Database db;
	private Sqlite.Statement insert_stmt;
	private Sqlite.Statement product_stmt;
	uint64 user = 0;
	private static string insert_query = "INSERT INTO purchases ('user', 'product') VALUES (?, ?)";
	private static string product_query = "SELECT name FROM products WHERE id = ?";

	public Database(string file) {
		int rc;

		rc = Sqlite.Database.open (file, out db);
		if(rc != Sqlite.OK) {
			error("could not open database!");
		}

		rc = this.db.prepare_v2(insert_query, -1, out insert_stmt);
		if(rc != Sqlite.OK) {
			error("could not prepare insert statement!");
		}

		rc = this.db.prepare_v2(product_query, -1, out product_stmt);
		if(rc != Sqlite.OK) {
			error("could not prepare article statement!");
		}
	}

	public void login(uint64 id) {
		this.user = id;
	}

	public void logout() {
		this.user = 0;
	}

	public void buy(uint64 article) {
		this.insert_stmt.reset();
		this.insert_stmt.bind_text(1, "%llu".printf(user));
		this.insert_stmt.bind_text(2, "%llu".printf(article));

		int rc = this.insert_stmt.step();

		if(rc != Sqlite.DONE)
			error("[interner Fehler: %d]".printf(rc));
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

	public bool is_logged_in() {
		return (user != 0);
	}
}
