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

public class ScannerSession {
	public int user {
		get;
		private set;
		default = 0;
	}
	public string name {
		get;
		private set;
		default = "Guest";
	}
	public bool logged_in {
		get;
		private set;
		default = false;
	}
	public bool disabled {
		get;
		private set;
		default = false;
	}
	public string theme {
		get;
		private set;
		default = "beep";
	}

	public void logout() {
		logged_in = false;
	}

	public bool login(int user) {
		this.user      = user;
		try {
			this.name      = db.get_username(user);
			this.disabled  = db.get_user_auth(user).disabled;
		} catch(WebSessionError e) {
			return false;
		}
		this.logged_in = true;
		this.theme = audio.get_random_user_theme();

		return true;
	}

	public ScannerSession() {
	}

	public bool interpret(string scannerdata) {
		if(scannerdata.has_prefix("USER ")) {
			string str_id = scannerdata.substring(5);
			int32 id = int.parse(str_id);

			/* check if scannerdata has valid format */
			if(scannerdata != "USER %d".printf(id)) {
				audio.play_system("error.ogg");
				write_to_log("Error: Invalid User ID: %s", scannerdata);
				return false;
			}

			if(logged_in) {
				write_to_log("Warning: Last user forgot to logout");
				logout();
			}

			if(login(id)) {
				audio.play_user(theme, "login");
				write_to_log("Login: %s (%d)", name, user);
				return true;
			} else {
				audio.play_system("error.ogg");
				write_to_log("Error: Login failed (User ID = %d)", id);
				return false;
			}
		} else if(scannerdata == "GUEST") {
			if(logged_in) {
				write_to_log("Warning: Last user forgot to logout");
				logout();
			}

			if(login(0)) {
				audio.play_user(theme, "login");
				write_to_log("Login: %s (%d)", name, user);
				return true;
			} else {
				audio.play_system("error.ogg");
				write_to_log("Error: Login failed (User ID = 0)");
				return false;
			}
		} else if(scannerdata == "UNDO") {
			if(!logged_in) {
				audio.play_system("error.ogg");
				write_to_log("Error: Can't undo if not logged in!");
				return false;
			} else {
				if(db.undo(user)) {
					audio.play_user(theme, "purchase");
					write_to_log("Undo last purchase!");
					return true;
				} else {
					audio.play_user(theme, "error");
					write_to_log("Error: Couldn't undo last purchase!");
					return false;
				}
			}
		} else if(scannerdata == "LOGOUT") {
			if(logged_in) {
				audio.play_user(theme, "logout");
				write_to_log("Logout!");
				logout();
				return true;
			}

			return false;
		} else {
			uint64 id = 0;
			scannerdata.scanf("%llu", out id);

			/* check if scannerdata has valid format */
			if(scannerdata != "%llu".printf(id) && scannerdata != "%08llu".printf(id) && scannerdata != "%013llu".printf(id)) {
				audio.play_user(theme, "error");
				write_to_log("Error: invalid product: %s", scannerdata);
				return false;
			}

			var name  = db.get_product_name(id);

			if(!logged_in) {
				var mprice = db.get_product_price(0, id);
				var gprice = db.get_product_price(1, id);

				audio.play_system("error.ogg");
				write_to_log(@"article info: $name (Member: $mprice €, Guest: $gprice €)");
				write_to_log("Error: Login required for purchase!");
				return false;
			}

			if(db.buy(user, id)) {
				var price = db.get_product_price(user, id);
				audio.play_user(theme, "purchase");
				write_to_log(@"article bought: $name ($price €)");
				return true;
			} else {
				audio.play_user(theme, "error");
				write_to_log("Error: purchase failed!");
				return false;
			}
		}
	}
}

