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
	if(data.has_prefix("USER ")) {
		string str_id = data.substring(5);
		uint64 id = uint64.parse(str_id);

		/* check if data has valid format */
		if(data != "USER %llu".printf(id)) {
			stdout.printf("ungültige Benutzernummer: %s\n", data);
			return false;
		}

		if(db.is_logged_in()) {
			stdout.printf("Last User forgot to logout!\n");
			db.logout();
		}

		stdout.printf("Login: %llu\n".printf(id));
		return db.login(id);
	} else if(data == "GUEST") {
		if(db.is_logged_in()) {
			stdout.printf("Last User forgot to logout!\n");
			db.logout();
		}

		stdout.printf("Login: Guest\n");
		return db.login(0);
	} else if(data == "UNDO") {
		if(!db.is_logged_in()) {
			stdout.printf("Can't undo if not logged in!\n");
			return false;
		} else {
			stdout.printf("Undo last purchase!\n");
			return db.undo();
		}
	} else if(data == "LOGOUT") {
		if(db.is_logged_in()) {
			stdout.printf("Logout!\n");
			return db.logout();
		}

		return false;
	} else if(data == "STOCK") {
		if(!db.is_logged_in()) {
			stdout.printf("You must be logged in to go into the stock mode\n");
			return false;
		} else {
			stdout.printf("Going into stock mode!\n");
			return db.go_into_stock_mode();
		}
	} else if(db.is_in_stock_mode()) {
		if(!data.has_prefix("AMOUNT")) {
			uint64 id = uint64.parse(data);

			/* check if data has valid format */
			if(data != "%llu".printf(id)) {
				stdout.printf("ungültiges Produkt: %s\n", data);
				return false;
			}

			stdout.printf("wähle Produkt: %s\n", db.get_product_name(id));

			return db.choose_stock_product(id);
		} else {
			uint64 amount = uint64.parse(data.substring(7));

			/* check if data has valid format */
			if(data != "AMOUNT %llu".printf(amount)) {
				stdout.printf("ungültiges Produkt: %s\n", data);
				return false;
			}

			stdout.printf("zum Bestand hinzufügen: %llu\n", amount);

			return db.add_stock_product(amount);
		}
	} else {
		uint64 id = uint64.parse(data);

		/* check if data has valid format */
		if(data != "%llu".printf(id)) {
			stdout.printf("ungültiges Produkt: %s\n", data);
			return false;
		}

		if(db.buy(id)) {
			stdout.printf("gekaufter Artikel: %s\n", db.get_product_name(id));
			return true;
		} else {
			stdout.printf("Kauf fehlgeschlagen!\n");
			return false;
		}
	}
}
