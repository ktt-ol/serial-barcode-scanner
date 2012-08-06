public Device dev;
public Database db;
public Gtk.Builder builder;

public static int main(string[] args) {
	Gtk.init (ref args);

	if(args.length < 2) {
		stderr.printf("%s <device>\n", args[0]);
		return 1;
	}

	dev = new Device(args[1], 9600, 8, 1);
	db = new Database("shop.db");
	builder = new Gtk.Builder();
	try {
		builder.add_from_file("user-interface.ui");
	} catch(Error e) {
		stderr.printf ("Could not load UI: %s\n", e.message);
		return 1;
	}

	dev.received_barcode.connect((data) => {
		if(interpret(data))
			dev.blink(10);
	});

	init_ui();

	Gtk.main();
	return 0;
}

public static bool interpret(string data) {
	int64 timestamp = (new DateTime.now_utc()).to_unix();

	if(data.has_prefix("USER ")) {
		string str_id = data.substring(5);
		int32 id = int.parse(str_id);

		/* check if data has valid format */
		if(data != "USER %d".printf(id)) {
			stdout.printf("[%lld] ungültige Benutzernummer: %s\n", timestamp, data);
			return false;
		}

		if(db.is_logged_in()) {
			stdout.printf("[%lld] Last User forgot to logout!\n", timestamp);
			db.logout();
		}

		stdout.printf("[%lld] Login: %d\n", timestamp, id);
		return db.login(id);
	} else if(data == "GUEST") {
		if(db.is_logged_in()) {
			stdout.printf("[%lld] Last User forgot to logout!\n", timestamp);
			db.logout();
		}

		stdout.printf("[%lld] Login: Guest\n", timestamp);
		return db.login(0);
	} else if(data == "UNDO") {
		if(!db.is_logged_in()) {
			stdout.printf("[%lld] Can't undo if not logged in!\n", timestamp);
			return false;
		} else {
			stdout.printf("[%lld] Undo last purchase!\n", timestamp);
			return db.undo();
		}
	} else if(data == "LOGOUT") {
		if(db.is_logged_in()) {
			stdout.printf("[%lld] Logout!\n", timestamp);
			return db.logout();
		}

		return false;
	} else if(data == "STOCK") {
		if(!db.is_logged_in()) {
			stdout.printf("[%lld] You must be logged in to go into the stock mode\n", timestamp);
			return false;
		} else {
			show_restock_dialog();
			return true;
		}
	} else {
		uint64 id = uint64.parse(data);

		/* check if data has valid format */
		if(data != "%llu".printf(id)) {
			stdout.printf("[%lld] ungültiges Produkt: %s\n", timestamp, data);
			return false;
		}

		if(db.buy(id)) {
			stdout.printf("[%lld] gekaufter Artikel: %s (%d,%02d €)\n", timestamp, db.get_product_name(id), db.get_product_price(id)/100, db.get_product_price(id) % 100);
			return true;
		} else {
			stdout.printf("[%lld] Kauf fehlgeschlagen!\n", timestamp);
			return false;
		}
	}
}
