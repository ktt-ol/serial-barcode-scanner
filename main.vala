public Device dev;
public Database db;

public static int main(string[] args) {
	if(args.length < 2) {
		stderr.printf("%s <device>\n", args[0]);
		return 1;
	}

	dev = new Device(args[1], 9600, 8, 1);
	db = new Database("shop.db");

	while(true) {
		string message = dev.receive();
		if(interpret((string) message))
			dev.blink(10);
	}
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
			stdout.printf("[%lld] Going into stock mode!\n", timestamp);
			return db.go_into_stock_mode();
		}
	} else if(db.is_in_stock_mode()) {
		if(!data.has_prefix("AMOUNT")) {
			uint64 id = uint64.parse(data);

			/* check if data has valid format */
			if(data != "%llu".printf(id)) {
				stdout.printf("[%lld] ungültiges Produkt: %s\n", timestamp, data);
				return false;
			}

			stdout.printf("[%lld] wähle Produkt: %s\n", timestamp, db.get_product_name(id));

			return db.choose_stock_product(id);
		} else {
			uint64 amount = uint64.parse(data.substring(7));

			/* check if data has valid format */
			if(data != "AMOUNT %llu".printf(amount)) {
				stdout.printf("[%lld] ungültiges Produkt: %s\n", timestamp, data);
				return false;
			}

			stdout.printf("[%lld] zum Bestand hinzufügen: %llu\n", timestamp, amount);

			return db.add_stock_product(amount);
		}
	} else {
		uint64 id = uint64.parse(data);

		/* check if data has valid format */
		if(data != "%llu".printf(id)) {
			stdout.printf("[%lld] ungültiges Produkt: %s\n", timestamp, data);
			return false;
		}

		if(db.buy(id)) {
			stdout.printf("[%lld] gekaufter Artikel: %s\n", timestamp, db.get_product_name(id));
			return true;
		} else {
			stdout.printf("[%lld] Kauf fehlgeschlagen!\n", timestamp);
			return false;
		}
	}
}
