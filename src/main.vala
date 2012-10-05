/* Copyright 2012, Sebastian Reichel <sre@ring0.de>
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

public Device dev;
public Database db;
public AudioPlayer audio;
public CSVMemberFile csvimport;

public static int main(string[] args) {
	Gst.init(ref args);

	if(args.length < 2) {
		stderr.printf("%s <device>\n", args[0]);
		return 1;
	}

	dev = new Device(args[1], 9600, 8, 1);
	db = new Database("shop.db");
	audio = new AudioPlayer();

	dev.received_barcode.connect((data) => {
		if(interpret(data))
			dev.blink(10);
	});

	write_to_log("KtT Shop System has been started");
	audio.play("system/startup.ogg");

	/* attach webserver to mainloop */
	new WebServer();

	/* run mainloop */
	new MainLoop().run();

	/* call destructors */
	dev = null;
	db  = null;

	return 0;
}

public void write_to_log(string format, ...) {
	var arguments = va_list();
	var message = format.vprintf(arguments);

	stdout.printf(message + "\n");
}

public static bool interpret(string data) {
	if(data.has_prefix("USER ")) {
		string str_id = data.substring(5);
		int32 id = int.parse(str_id);

		/* check if data has valid format */
		if(data != "USER %d".printf(id)) {
			write_to_log("ungültige Benutzernummer: %s", data);
			return false;
		}

		if(db.is_logged_in()) {
			write_to_log("Last User forgot to logout!");
			db.logout();
		}

		write_to_log("Login: %d", id);
		return db.login(id);
	} else if(data == "GUEST") {
		if(db.is_logged_in()) {
			write_to_log("Last User forgot to logout!");
			db.logout();
		}

		write_to_log("Login: Guest");
		return db.login(0);
	} else if(data == "UNDO") {
		if(!db.is_logged_in()) {
			write_to_log("Can't undo if not logged in!");
			return false;
		} else {
			write_to_log("Undo last purchase!");
			return db.undo();
		}
	} else if(data == "LOGOUT") {
		if(db.is_logged_in()) {
			write_to_log("Logout!");
			return db.logout();
		}

		return false;
	} else {
		uint64 id = uint64.parse(data);

		/* check if data has valid format */
		if(data != "%llu".printf(id)) {
			write_to_log("ungültiges Produkt: %s", data);
			return false;
		}

		if(db.buy(id)) {
			write_to_log("gekaufter Artikel: %s (%d,%02d €)", db.get_product_name(id), db.get_product_price(id)/100, db.get_product_price(id) % 100);
			return true;
		} else {
			write_to_log("Kauf fehlgeschlagen!");
			return false;
		}
	}
}
