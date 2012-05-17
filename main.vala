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
			stdout.printf("Logout\n");
			return db.logout();
		} else {
			stdout.printf("Login: %llu\n".printf(id));
			return db.login(id);
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
