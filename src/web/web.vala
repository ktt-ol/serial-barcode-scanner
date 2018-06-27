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

public class WebServer {
	private Soup.Server srv;
	private string longname;
	private string shortname;

	void handler_default(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			var t = new WebTemplate("index.html", l);
			t.replace("TITLE", shortname + " Shop System");
			t.replace("SHORTNAME", shortname);
			t.menu_set_active("home");
			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_logout(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			l.logout();
			var t = new WebTemplate("logout.html", l);
			t.replace("TITLE", shortname + " Shop System");
			t.replace("SHORTNAME", shortname);
			t.menu_set_active("home");
			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_users(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		string[] pathparts = path.split("/");

		if(pathparts.length <= 2) {
			handler_user_list(server, msg, path, query, client);
		} else {
			int id = int.parse(pathparts[2]);

			if(pathparts.length <= 3) {
				handler_user_entry(server, msg, path, query, client, id);
			} else {
				switch(pathparts[3]) {
					case "invoice":
						uint16 selectedyear = (pathparts.length >= 5 && pathparts[4] != "") ? (uint16) int.parse(pathparts[4]) : (uint16) (new DateTime.now_local()).get_year();
						uint8 selectedmonth = (pathparts.length >= 6 && pathparts[5] != "") ? (uint8)  int.parse(pathparts[5]) : (uint8) (new DateTime.now_local()).get_month();
						uint8 selectedday   = (pathparts.length >= 7 && pathparts[6] != "") ? (uint8)  int.parse(pathparts[6]) : (uint8) (new DateTime.now_local()).get_day_of_month();
						handler_user_invoice(server, msg, path, query, client, id, selectedyear, selectedmonth, selectedday);
						break;
					case "stats":
						handler_todo(server, msg, path, query, client);
						break;
					case "toggle_auth_products":
					case "toggle_auth_cashbox":
					case "toggle_auth_users":
						handler_user_toggle_auth(server, msg, path, query, client, id, pathparts[3]);
						break;
					default:
						handler_404(server, msg, path, query, client);
						break;
				}
			}
		}
	}

	void handler_user_list(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			if(!session.superuser && !session.auth_users) {
				handler_403(server, msg, path, query, client);
				return;
			}

			var t = new WebTemplate("users/index.html", session);
			t.replace("TITLE", shortname + " Shop System: User");
			t.replace("SHORTNAME", shortname);
			t.menu_set_active("users");
			var data = "";
			foreach(var m in db.get_member_ids()) {
				try {
					var name = db.get_username(m);
					data += @"<tr><td>$m</td><td><a href=\"/users/$m\">$name</a></td></tr>";
				} catch(DatabaseError e) {
					/* TODO: write error to log */
				}
			}
			t.replace("DATA", data);

			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_user_pgp_import(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			if(!session.superuser && !session.auth_users) {
				handler_403(server, msg, path, query, client);
				return;
			}

			var t = new WebTemplate("users/import-pgp.html", session);
			t.replace("TITLE", shortname + " Shop System: PGP Key Import");
			t.replace("SHORTNAME", shortname);
			t.menu_set_active("users");

			Soup.Buffer filedata;
			var postdata = Soup.Form.decode_multipart(msg, "file", null, null, out filedata);

			if(postdata == null || !postdata.contains("step")) {
				t.replace("DATA", "");
				t.replace("STEP1",  "block");
				t.replace("STEP2",  "none");
				msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
				msg.set_status(200);
				return;
			} else {
				var keylist = pgp.import_archive(filedata.data);
				string keylisttemplate;

				if(keylist.length > 0) {
					keylisttemplate = "<ul>\n";
					foreach(string s in keylist) {
						keylisttemplate += "<li>"+s+"</li>\n";
					}
					keylisttemplate += "</ul>\n";
				} else {
					keylisttemplate = "<p><b>No new keys!</b></p>";
				}

				t.replace("DATA", keylisttemplate);
				t.replace("STEP1",  "none");
				t.replace("STEP2",  "block");
				msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
				msg.set_status(200);
				return;
			}
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_user_import(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			if(!session.superuser && !session.auth_users) {
				handler_403(server, msg, path, query, client);
				return;
			}
			var t = new WebTemplate("users/import.html", session);
			t.replace("TITLE", shortname + " Shop System: User Import");
			t.replace("SHORTNAME", shortname);
			t.menu_set_active("users");

			Soup.Buffer filedata;
			var postdata = Soup.Form.decode_multipart(msg, "file", null, null, out filedata);
			if(postdata == null || !postdata.contains("step")) {
				t.replace("DATA1", "");
				t.replace("DATA2", "");
				t.replace("STEP1",  "block");
				t.replace("STEP2",  "none");
				t.replace("STEP23", "none");
				t.replace("STEP3",  "none");
				msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
				msg.set_status(200);
				return;
			} else {
				if(filedata != null) {
					string text = (string) filedata.data;
					text = text.substring(0,(long) filedata.length-1);
					csvimport = new CSVMemberFile(text);
				}

				if(csvimport == null) {
					handler_403(server, msg, path, query, client);
					return;
				}

				/* new & changed users */
				string data1 = "";
				foreach(var member in csvimport.get_members()) {
					if(db.user_exists(member.id) && !db.user_equals(member)) {
						var dbmember = db.get_user_info(member.id);
						data1 += @"<tr class=\"error\"><td><i class=\"icon-minus-sign\"></i><td>$(dbmember.id)</td><td>$(dbmember.firstname)</td><td>$(dbmember.lastname)</td><td>$(dbmember.email)</td><td>$(dbmember.gender)</td><td>$(dbmember.street)</td><td>$(dbmember.postcode)</td><td>$(dbmember.city)</td><td>$(dbmember.pgp)</td><td>$(dbmember.hidden)</td><td>$(dbmember.disabled)</td><td>$(dbmember.joined_at)</td></tr>";
					}
					if(!db.user_exists(member.id) || !db.user_equals(member)) {
						data1 += @"<tr class=\"success\"><td><i class=\"icon-plus-sign\"></td><td>$(member.id)</td><td>$(member.firstname)</td><td>$(member.lastname)</td><td>$(member.email)</td><td>$(member.gender)</td><td>$(member.street)</td><td>$(member.postcode)</td><td>$(member.city)</td><td>$(member.pgp)</td><td>$(member.hidden)</td><td>$(member.disabled)</td><td>$(member.joined_at)</td></tr>";
					}
				}
				t.replace("DATA1", data1);

				/* removed users */
				Gee.List<int> blockedusers = csvimport.missing_unblocked_members();
				if(blockedusers.size > 0) {
					string data2 = "<b>Disabling the following users</b>, because they are no longer found in the member CSV: <ul>";

					foreach(var member in blockedusers) {
						try {
							string name = db.get_username(member);
							data2 += @"<li>$name ($member)</li>";
						} catch(Error e) {}
					}

					data2 += "</ul>";
					t.replace("DATA2", data2);
				} else {
					t.replace("DATA2", "");
				}

				/* show correct blocks */
				t.replace("STEP1",  "none");
				t.replace("STEP23", "block");
				if(postdata["step"] == "1") {
					t.replace("STEP2",  "block");
					t.replace("STEP3",  "none");
				} else {
					t.replace("STEP2",  "none");
					t.replace("STEP3",  "block");
				}

				if(postdata["step"] == "2") {
					/* disable users */
					foreach(var member in csvimport.missing_unblocked_members()) {
						db.user_disable(member, true);
					}

					/* update users */
					foreach(var member in csvimport.get_members()) {
						db.user_replace(member);
					}

					csvimport = null;
				}
			}

			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_user_toggle_auth(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client, int id, string action) {
		try {
			var l = new WebSession(server, msg, path, query, client);

			if(!(l.superuser || l.auth_users)) {
				handler_403(server, msg, path, query, client);
				return;
			}

			var olduserauth = db.get_user_auth(id);

			switch(action) {
				case "toggle_auth_products":
					olduserauth.auth_products = !olduserauth.auth_products;
					break;
				case "toggle_auth_cashbox":
					olduserauth.auth_cashbox = !olduserauth.auth_cashbox;
					break;
				case "toggle_auth_users":
					olduserauth.auth_users = !olduserauth.auth_users;
					break;
			}

			db.set_user_auth(olduserauth);

			var newuserauth = db.get_user_auth(id);

			var auth_products = newuserauth.auth_products ? "true" : "false";
			var auth_cashbox = newuserauth.auth_cashbox ? "true" : "false";
			var auth_users = newuserauth.auth_users ? "true" : "false";

			msg.set_response("application/json", Soup.MemoryUse.COPY, @"{ \"products\": \"$auth_products\", \"cashbox\": \"$auth_cashbox\", \"users\": \"$auth_users\"  }".data);
			msg.set_status(200);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_user_entry(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client, int id) {
		try {
			var session = new WebSession(server, msg, path, query, client);

			if(id != session.user && !(session.superuser || session.auth_users)) {
				handler_403(server, msg, path, query, client);
				return;
			}
			var t = new WebTemplate("users/entry.html", session);
			t.replace("TITLE", shortname + " Shop System: User Info %llu".printf(id));
			t.replace("SHORTNAME", shortname);
			t.menu_set_active("users");

			var userinfo = db.get_user_info(id);

			t.replace("UID", "%d".printf(userinfo.id));
			t.replace("FIRSTNAME", userinfo.firstname);
			t.replace("LASTNAME", userinfo.lastname);
			t.replace("EMAIL", userinfo.email);
			t.replace("GENDER", userinfo.gender);
			t.replace("STREET", userinfo.street);
			t.replace("POSTALCODE", userinfo.postcode);
			t.replace("CITY", userinfo.city);
			t.replace("PGPKEYID", userinfo.pgp);
			t.replace("DISABLED", userinfo.disabled ? "true" : "false");
			t.replace("HIDDEN", userinfo.hidden ? "true" : "false");
			t.replace("RFID", string.joinv("<br>",userinfo.rfid));

			var userauth = db.get_user_auth(id);
			t.replace("ISSUPERUSER", userauth.superuser ? "true" : "false");
			t.replace("HAS_AUTH_PRODUCTS", userauth.auth_products ? "Yes" : "No");
			t.replace("HAS_AUTH_CASHBOX", userauth.auth_cashbox ? "Yes" : "No");
			t.replace("HAS_AUTH_USERS", userauth.auth_users ? "Yes" : "No");

			t.replace("BTN_AUTH_PRODUCTS", userauth.auth_products ? "btn-success" : "btn-danger");
			t.replace("BTN_AUTH_CASHBOX", userauth.auth_cashbox ? "btn-success" : "btn-danger");
			t.replace("BTN_AUTH_USERS", userauth.auth_users ? "btn-success" : "btn-danger");

			if(session.superuser) {
				t.replace("ISADMIN2", "");
			} else {
				t.replace("ISADMIN2", "disabled=\"disabled\"");
			}

			var userThemeList = audio.get_user_themes();
			var message = "";
			var postdata = Soup.Form.decode_multipart(msg, null, null, null, null);
			if(postdata != null && postdata.contains("password1") && postdata.contains("password2")) {
				if(postdata["password1"] != postdata["password2"]) {
					message = "<div class=\"alert alert-error\">Error! Passwords do not match!</div>";
				} else if(postdata["password1"] == "") {
					message = "<div class=\"alert alert-error\">Error! Empty Password not allowed!</div>";
				} else {
					db.set_user_password(id, postdata["password1"]);
					message = "<div class=\"alert alert-success\">Password Changed!</div>";
				}
			} else if(postdata != null && postdata.contains("soundTheme")) {
				if (postdata["soundTheme"] in userThemeList) {
					userinfo.soundTheme = postdata["soundTheme"];
					db.set_userTheme(id, postdata["soundTheme"]);
				} else {
					userinfo.soundTheme = null;
					db.set_userTheme(id, "");
				}
				message = "<div class=\"alert alert-success\">Sound theme changed.</div>";
			}
			t.replace("MESSAGE", message);

			var soundThemes = "";
			foreach(var theme in userThemeList) {
				var selected = userinfo.soundTheme == theme ? "selected" : "";
			  soundThemes += @"<option $selected>$theme</option>";
			}
			t.replace("SOUND_THEMES", soundThemes);

			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_user_invoice(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client, int id, uint16 selectedyear, uint8 selectedmonth, uint8 selectedday) {
		DateTime start, stop;

		DateYear  y = (DateYear) selectedyear;
		if(!y.valid() || y > 8000) {
			selectedyear = (uint16) new DateTime.now_local().get_year();
			y = (DateYear) selectedyear;
		}

		DateMonth m = (DateMonth) selectedmonth;
		if(selectedmonth != 0 && !m.valid()) {
			selectedmonth = (uint8) new DateTime.now_local().get_month();
			m = (DateMonth) selectedmonth;
		}

		DateDay d = (DateDay) selectedday;
		if(selectedday != 0 && !d.valid()) {
			selectedday = (uint8) new DateTime.now_local().get_day_of_month();
			d = (DateDay) selectedday;
		}

		try {
			var l = new WebSession(server, msg, path, query, client);
			if(id != l.user && !(l.superuser || l.auth_users)) {
				handler_403(server, msg, path, query, client);
				return;
			}
			var t = new WebTemplate("users/invoice.html", l);
			t.replace("TITLE", shortname + " Shop System: User Invoice %llu".printf(id));
			t.replace("SHORTNAME", shortname);
			t.menu_set_active("users");

			/* years, in which something has been purchased by the user */
			var first = new DateTime.from_unix_local(db.get_first_purchase(id));
			var last  = new DateTime.from_unix_local(db.get_last_purchase(id));
			string years = "";
			for(int i=first.get_year(); i <= last.get_year(); i++) {
				years += @"<li><a href=\"/users/$id/invoice/$i/$selectedmonth/$selectedday\">$i</a></li>";
			}
			t.replace("YEARS", years);
			t.replace("SELECTEDYEAR", @"$selectedyear");

			/* months, in which something has been purchased by the user */
			string[] monthnames = { "All Months", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" };
			string months = @"<li><a href=\"/users/$id/invoice/$selectedyear/0/0\">All Months</a></li>";
			for(int i=1; i<monthnames.length; i++) {
				if(first.get_year() == selectedyear && i > 0 && i < first.get_month())
					months += @"<li><a href=\"/users/$id/invoice/$selectedyear/$i/$selectedday\" class=\"disabled\"\">$(monthnames[i])</a></li>";
				else if(selectedyear < first.get_year())
					months += @"<li><a href=\"/users/$id/invoice/$selectedyear/$i/$selectedday\" class=\"disabled\"\">$(monthnames[i])</a></li>";
				else if(last.get_year() == selectedyear && i > last.get_month())
					months += @"<li><a href=\"/users/$id/invoice/$selectedyear/$i/$selectedday\" class=\"disabled\"\">$(monthnames[i])</a></li>";
				else if(selectedyear > last.get_year())
					months += @"<li><a href=\"/users/$id/invoice/$selectedyear/$i/$selectedday\" class=\"disabled\"\">$(monthnames[i])</a></li>";
				else
					months += @"<li><a href=\"/users/$id/invoice/$selectedyear/$i/$selectedday\">$(monthnames[i])</a></li>";
			}
			t.replace("MONTHS", months);
			t.replace("SELECTEDMONTH", @"$(monthnames[selectedmonth])");

			int dim     = m.valid() ? Date.get_days_in_month(m, y) : 0;
			string days = @"<li><a href=\"/users/$id/invoice/$selectedyear/$selectedmonth/0\">All Days</a></li>";
			for(int i=1; i<=dim; i++) {
				if(first.get_year() == selectedyear && first.get_month() == selectedmonth && i < first.get_day_of_month())
					days += @"<li><a href=\"/users/$id/invoice/$selectedyear/$selectedmonth/$i\" class=\"disabled\">$i</a></li>";
				else if(selectedyear < first.get_year() || (selectedyear == first.get_year() && selectedmonth < first.get_month()))
					days += @"<li><a href=\"/users/$id/invoice/$selectedyear/$selectedmonth/$i\" class=\"disabled\">$i</a></li>";
				else if(last.get_year() == selectedyear && last.get_month() == selectedmonth && i > last.get_day_of_month())
					days += @"<li><a href=\"/users/$id/invoice/$selectedyear/$selectedmonth/$i\" class=\"disabled\">$i</a></li>";
				else if(selectedyear > last.get_year() || (selectedyear == last.get_year() && selectedmonth > last.get_month()))
					days += @"<li><a href=\"/users/$id/invoice/$selectedyear/$selectedmonth/$i\" class=\"disabled\">$i</a></li>";
				else
					days += @"<li><a href=\"/users/$id/invoice/$selectedyear/$selectedmonth/$i\">$i</a></li>";
			}
			t.replace("DAYS", days);
			if(selectedday > 0)
				t.replace("SELECTEDDAY", @"$selectedday");
			else
				t.replace("SELECTEDDAY", "All Days");

			if(selectedday != 0) {
				start = new DateTime.local(selectedyear, selectedmonth, selectedday, 8, 0, 0);
				stop = start.add_days(1);
			} else if(selectedmonth != 0) {
				start = new DateTime.local(selectedyear, selectedmonth, 1, 0, 0, 0);
				stop = start.add_months(1);
			} else {
				start = new DateTime.local(selectedyear, 1, 1, 0, 0, 0);
				stop = start.add_years(1);
			}

			string table = "";
			Price sum = 0;
			foreach(var e in db.get_invoice(id, start.to_unix(), stop.to_unix())) {
				var timestamp = new DateTime.from_unix_local(e.timestamp);
				var date = timestamp.format("%d.%m.%Y");
				var time = timestamp.format("%H:%M:%S");
				var product = e.product.name;
				var price = e.price;
				table += @"<tr><td>$date</td><td>$time</td><td>$product</td><td>$price€</td></tr>";
				sum += e.price;
			}

			t.replace("DATA", table);
			t.replace("SUM", @"$sum €");

			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_products(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		string[] pathparts = path.split("/");

		if(pathparts.length <= 2 || pathparts[2] == "") {
			handler_product_list(server, msg, path, query, client);
		} else {
			uint64 id = uint64.parse(pathparts[2]);

			if(pathparts.length <= 3) {
				handler_product_entry(server, msg, path, query, client, id);
			} else {
				switch(pathparts[3]) {
					case "restock":
						handler_product_restock(server, msg, path, query, client, id);
						break;
					case "newprice":
						handler_product_newprice(server, msg, path, query, client, id);
						break;
					case "togglestate":
						handler_product_togglestate(server, msg, path, query, client, id);
						break;
					default:
						handler_product_entry(server, msg, path, query, client, id);
						break;
				}
			}
		}
	}

	void handler_product_list(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			var t = new WebTemplate("products/index.html", l);
			t.replace("TITLE", shortname + " Shop System: Product List");
			t.replace("SHORTNAME", shortname);
			t.menu_set_active("products");

			string table = "";
			foreach(var e in db.get_stock()) {
				table += @"<tr><td><a href=\"/products/$(e.ean)\">$(e.ean)</a></td><td><a href=\"/products/$(e.ean)\">$(e.name)</a></td><td>$(e.category)</td><td>$(e.amount)</td><td>$(e.memberprice)€</td><td>$(e.guestprice)€</td></tr>";
			}

			t.replace("DATA", table);

			string categories = "";
			foreach(var c in db.get_category_list()) {
				categories += @"<option value=\"$(c.id)\">$(c.name)</option>";
			}
			t.replace("CATEGORIES", categories);

			if(l.superuser || l.auth_products)
				t.replace("NEWPRODUCT", "block");
			else
				t.replace("NEWPRODUCT", "none");

			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_product_bestbefore(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			var t = new WebTemplate("products/bestbefore.html", l);
			t.replace("TITLE", shortname + " Shop System: Best Before List");
			t.replace("SHORTNAME", shortname);
			t.menu_set_active("products");

			string table = "";
			foreach(var e in db.bestbeforelist()) {
				string bbd;
				if(e.best_before_date > 0)
					bbd = (new DateTime.from_unix_local(e.best_before_date)).format("%Y-%m-%d");
				else
					bbd = "";

				table += @"<tr><td><a href=\"/products/$(e.ean)\">$(e.ean)</a></td><td><a href=\"/products/$(e.ean)\">$(e.name)</a></td><td>$(e.amount)</td><td>$(bbd)</td></tr>";
			}

			t.replace("DATA", table);

			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_product_togglestate(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client, uint64 id) {
		try {
			var l = new WebSession(server, msg, path, query, client);

			if(!l.superuser && !l.auth_products) {
				handler_403(server, msg, path, query, client);
				return;
			}

			var oldstate = db.get_product_deprecated(id);
			db.product_deprecate(id, !oldstate);
			var newstate = db.get_product_deprecated(id);

			var statestr = newstate ? "deprecated" : "active";
			msg.set_response("application/json", Soup.MemoryUse.COPY, @"{ \"state\": \"$statestr\" }".data);
			msg.set_status(200);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_product_entry(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client, uint64 id) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			var t = new WebTemplate("products/entry.html", l);
			t.replace("TITLE", shortname + " Shop System: Product %llu".printf(id));
			t.replace("SHORTNAME", shortname);
			t.menu_set_active("products");

			/* ean */
			t.replace("EAN", "%llu".printf(id));

			/* name */
			string name = db.get_product_name(id);
			t.replace("NAME", name);

			/* category */
			string category = db.get_product_category(id);
			t.replace("CATEGORY", category);

			/* amount */
			t.replace("AMOUNT", "%d".printf(db.get_product_amount(id)));

			var deprecated = db.get_product_deprecated(id);
			t.replace("BTNSTATE", deprecated ? "btn-danger" : "btn-success");
			t.replace("STATE", deprecated ? "Deprecated" : "Active");

			if(l.superuser || l.auth_products) {
				t.replace("ISADMIN", "block");
				t.replace("ISADMIN2", "");
			} else {
				t.replace("ISADMIN", "none");
				t.replace("ISADMIN2", "disabled=\"disabled\"");
			}

			/* prices */
			string prices = "";
			foreach(var e in db.get_prices(id)) {
				var time = new DateTime.from_unix_local(e.valid_from);
				prices += @"<tr><td>%s</td><td>$(e.memberprice)€</td><td>$(e.guestprice)€</td></tr>".printf(
					time.format("%Y-%m-%d %H:%M")
				);
			}
			t.replace("PRICES", prices);

			/* restocks */
			string restocks = "";
			foreach(var e in db.get_restocks(id, false)) {
				var time = new DateTime.from_unix_local(e.timestamp);
				var supplier = db.get_supplier(e.supplier).name;
				if(supplier == "Unknown")
					supplier = "";
				string bbd;
				if(e.best_before_date > 0)
					bbd = (new DateTime.from_unix_local(e.best_before_date)).format("%Y-%m-%d");
				else
					bbd = "";
				restocks += "<tr><td>%s</td><td>%d</td><td>%s€</td><td>%s</td><td>%s</td></tr>".printf(
					time.format("%Y-%m-%d %H:%M"), e.amount, e.price, supplier, bbd
				);
			}
			t.replace("RESTOCKS", restocks);

			/* suppliers */
			string suppliers = "<option value=\"0\">Unknown</option>";
			foreach(var e in db.get_supplier_list()) {
				suppliers += "<option value=\"%lld\">%s</option>".printf(e.id, e.name);
			}
			t.replace("SUPPLIERS", suppliers);

			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_products_new(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			var template = new WebTemplate("products/new.html", session);
			template.replace("TITLE", shortname + " Shop System: New Product");
			template.replace("SHORTNAME", shortname);
			template.menu_set_active("products");

			if(!session.superuser && !session.auth_products) {
				handler_403(server, msg, path, query, client);
				return;
			}

			if(query != null && query.contains("name") && query.contains("id") && query.contains("memberprice") && query.contains("guestprice")) {
				var name = query["name"];
				var ean = uint64.parse(query["id"]);
				int category = int.parse(query["category"]);
				Price memberprice = Price.parse(query["memberprice"]);
				Price guestprice  = Price.parse(query["guestprice"]);

				if(ean > 0 && memberprice > 0 && guestprice > 0 && category >= 0) {
					db.new_product(ean, name, category, memberprice, guestprice);
					template.replace("NAME", name);
					template.replace("EAN", @"$ean");
					template.replace("MEMBERPRICE", @"$memberprice€");
					template.replace("GUESTPRICE", @"$guestprice€");
					template.replace("NEW.OK", "block");
					template.replace("NEW.FAIL", "none");
				} else {
					template.replace("NAME", "...");
					template.replace("NEW.OK", "none");
					template.replace("NEW.FAIL", "block");
				}
			} else {
				template.replace("NAME", "...");
				template.replace("NEW.OK", "none");
				template.replace("NEW.FAIL", "block");
			}

			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_product_restock(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client, uint64 id) {
		try {
			var session = new WebSession(server, msg, path, query, client);

			if(!session.superuser && !session.auth_products) {
				handler_403(server, msg, path, query, client);
				return;
			}

			var template = new WebTemplate("products/restock.html", session);
			template.replace("TITLE", shortname + " Shop System: Restock Product %llu".printf(id));
			template.replace("SHORTNAME", shortname);
			template.replace("NAME", db.get_product_name(id));
			template.menu_set_active("products");

			if(query != null && query.contains("amount") && query.contains("price")) {
				int amount = int.parse(query["amount"]);
				int supplier = int.parse(query["supplier"]);
				string best_before_date = query["best_before_date"];
				Price price = Price.parse(query["price"]);
				DateTime bbd;

				var dateparts = best_before_date.split("-");
				if(dateparts.length == 3) {
					bbd = new DateTime.local(int.parse(dateparts[0]), int.parse(dateparts[1]), int.parse(dateparts[2]), 0, 0, 0);
				} else {
					bbd = new DateTime.from_unix_local(0);
				}

				if(amount >= 1 && price >= 0) {
					db.restock(session.user, id, amount, price, supplier, bbd.to_unix());
					template.replace("AMOUNT", @"$amount");
					template.replace("PRICE", @"$price");
					template.replace("BESTBEFORE", bbd.format("%Y-%m-%d"));
					template.replace("SUPPLIER", db.get_supplier(supplier).name);
					template.replace("RESTOCK.OK", "block");
					template.replace("RESTOCK.FAIL", "none");
					msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
					msg.set_status(200);
					return;
				}
			}

			template.replace("RESTOCK.OK", "none");
			template.replace("RESTOCK.FAIL", "block");
			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
			msg.set_status(200);
			return;
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_product_newprice(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client, uint64 id) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			int64 timestamp = (new DateTime.now_utc()).to_unix();

			if(!session.superuser && !session.auth_products) {
				handler_403(server, msg, path, query, client);
				return;
			}

			var template = new WebTemplate("products/newprice.html", session);
			template.replace("TITLE", shortname + " Shop System: New Price for Product %llu".printf(id));
			template.replace("NAME", db.get_product_name(id));
			template.menu_set_active("products");

			if(query != null && query.contains("guest") && query.contains("member")) {
				Price member = Price.parse(query["member"]);
				Price guest =  Price.parse(query["guest"]);

				if(guest >= 1 && member >= 1) {
					db.new_price(id, timestamp, member, guest);
					template.replace("GUEST", @"$guest");
					template.replace("MEMBER", @"$member");
					template.replace("NEWPRICE.OK", "block");
					template.replace("NEWPRICE.FAIL", "none");
					msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
					msg.set_status(200);
					return;
				}
			}

			template.replace("NEWPRICE.OK", "none");
			template.replace("NEWPRICE.FAIL", "block");
			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
			msg.set_status(200);
			return;
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_alias_list(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			var t = new WebTemplate("aliases/index.html", l);
			t.replace("TITLE", shortname + " Shop System: Alias List");
			t.replace("SHORTNAME", shortname);
			t.menu_set_active("aliases");

			string table = "";
			foreach(var e in db.ean_alias_list()) {
				var productname = db.get_product_name(e.real_ean);
				table += @"<tr><td>$(e.ean)</td><td><a href=\"/products/$(e.real_ean)\">$(e.real_ean)</a></td><td><a href=\"/products/$(e.real_ean)\">$(productname)</a></td></tr>";
			}

			t.replace("DATA", table);

			if(l.superuser || l.auth_products)
				t.replace("NEWALIAS", "block");
			else
				t.replace("NEWALIAS", "none");

			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_alias_new(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			var template = new WebTemplate("aliases/new.html", session);
			template.replace("TITLE", shortname + " Shop System: New Alias");
			template.replace("SHORTNAME", shortname);
			template.menu_set_active("aliases");

			if(!session.superuser && !session.auth_products) {
				handler_403(server, msg, path, query, client);
				return;
			}

			if(query != null && query.contains("ean") && query.contains("real_ean")) {
				var ean = uint64.parse(query["ean"]);
				var real_ean = uint64.parse(query["real_ean"]);

				if(ean > 0 && real_ean > 0) {
					db.ean_alias_add(ean, real_ean);
					template.replace("EAN", @"$ean");
					template.replace("REAL_EAN", @"$real_ean");
					template.replace("NEW.OK", "block");
					template.replace("NEW.FAIL", "none");
				} else {
					template.replace("EAN", "virtual ean");
					template.replace("REAL_EAN", "real ean");
					template.replace("NEW.OK", "none");
					template.replace("NEW.FAIL", "block");
				}
			} else {
				template.replace("EAN", "virtual ean");
				template.replace("REAL_EAN", "real ean");
				template.replace("NEW.OK", "none");
				template.replace("NEW.FAIL", "block");
			}

			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

#if 0
	void handler_stats(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			var t = new WebTemplate("stats/index.html", l);
			t.replace("TITLE", shortname + " Shop System: Statistics");
			t.replace("SHORTNAME", shortname);
			t.menu_set_active("stats");

			var stats = db.get_stats_info();

			t.replace("NUMBER_OF_ARTICLES", @"$(stats.count_articles)");
			t.replace("NUMBER_OF_USERS", @"$(stats.count_users)");
			t.replace("STOCK_VALUE", @"$(stats.stock_value)€");
			t.replace("TOTAL_SALES", @"$(stats.sales_total)€");
			t.replace("TOTAL_PROFIT", @"$(stats.profit_total)€");
			t.replace("SALES_TODAY", @"$(stats.sales_today)€");
			t.replace("PROFIT_TODAY", @"$(stats.profit_today)€");
			t.replace("SALES_THIS_MONTH", @"$(stats.sales_this_month)€");
			t.replace("PROFIT_THIS_MONTH", @"$(stats.profit_this_month)€");
			t.replace("SALES_PER_DAY", @"$(stats.sales_per_day)€");
			t.replace("PROFIT_PER_DAY", @"$(stats.profit_per_day)€");
			t.replace("SALES_PER_MONTH", @"$(stats.sales_per_month)€");
			t.replace("PROFIT_PER_MONTH", @"$(stats.profit_per_month)€");

			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_stats_stock(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			var t = new WebTemplate("stats/stock.html", l);
			string data = db.get_stats_stock().json;
			t.replace("DATA", data);
			t.replace("SHORTNAME", shortname);
			t.replace("TITLE", shortname + " Shop System: Statistics: Stock");
			t.menu_set_active("stats");
			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_stats_profit_per_day(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			var t = new WebTemplate("stats/profit_per_day.html", l);
			string data = db.get_stats_profit_per_day().json;
			t.replace("DATA", data);
			t.replace("SHORTNAME", shortname);
			t.replace("TITLE", shortname + " Shop System: Statistics: Profit");
			t.menu_set_active("stats");
			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_stats_profit_per_weekday(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			var t = new WebTemplate("stats/profit_per_weekday.html", l);
			string data = db.get_stats_profit_per_weekday().json;
			t.replace("DATA", data);
			t.replace("SHORTNAME", shortname);
			t.replace("TITLE", shortname + " Shop System: Statistics: Profit/Weekday");
			t.menu_set_active("stats");
			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_stats_profit_per_product(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			var t = new WebTemplate("stats/profit_per_product.html", l);
			string data = db.get_stats_profit_per_products().json;
			t.replace("DATA", data);
			t.replace("SHORTNAME", shortname);
			t.replace("TITLE", shortname + " Shop System: Statistics: Profit/Product");
			t.menu_set_active("stats");
			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}
#endif

	void handler_js(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var t = new WebTemplate.DATA(path);
			msg.set_response("text/javascript", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_css(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var t = new WebTemplate.DATA(path);
			msg.set_response("text/css", Soup.MemoryUse.COPY, t.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_img(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var f = File.new_for_path(templatedir+path);
			uint8[] data = null;

			if(f.query_exists() && f.load_contents(null, out data, null)) {
				msg.set_response("image/png", Soup.MemoryUse.COPY, data);
				msg.set_status(200);
				return;
			}
		} catch(Error e) {
			error("there has been some error: %s!\n", e.message);
		}

		handler_404(server, msg, path, query, client);
		return;
	}

	void handler_400_fallback(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		string result = "Internal Server Error\n";
		msg.set_response("text/plain", Soup.MemoryUse.COPY, result.data);
		msg.set_status(400);
	}

	void handler_400(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client, string errmsg) {
		/* strip exception prefix */
		string errormessage = errmsg.substring(errmsg.index_of_char(':', errmsg.index_of_char(':', 0)+1)+2);

		try {
			var session = new WebSession(server, msg, path, query, client);
			var template = new WebTemplate("errors/400.html", session);
			template.replace("TITLE", "Internal Server Error");
			template.replace("ERRMSG", errormessage);
			template.menu_set_active("");
			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
			msg.set_status(400);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			stderr.printf(e.message+"\n");
			handler_400_fallback(server, msg, path, query, client);
		} catch(IOError e) {
			stderr.printf(e.message+"\n");
			handler_400_fallback(server, msg, path, query, client);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_404(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		string result = "Page not Found\n";
		msg.set_response("text/plain", Soup.MemoryUse.COPY, result.data);
		msg.set_status(404);
	}

	void handler_403(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			var template = new WebTemplate("errors/403.html", session);
			template.replace("TITLE", "Access Denied");
			template.menu_set_active("");
			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
			msg.set_status(403);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_todo(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			var template = new WebTemplate("errors/todo.html", session);
			template.replace("TITLE", shortname + " Shop System: ToDo");
			template.replace("SHORTNAME", shortname);
			template.menu_set_active("");
			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_cashbox(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);

			if(!session.superuser && !session.auth_cashbox) {
				handler_403(server, msg, path, query, client);
				return;
			}

			var template = new WebTemplate("cashbox/index.html", session);
			var status = db.cashbox_status().to_string();
			var history = db.cashbox_history();

			var hist = "";
			foreach(var diff in history) {
				var dt = new DateTime.from_unix_local(diff.timestamp);
				var dts = dt.format("%Y-%m-%d %H:%M:%S");
				var name = "";
				if(diff.user != -3) {
					var ui = db.get_user_info(diff.user);
					name = @"$(ui.firstname) $(ui.lastname)";
				} else if(diff.amount < 0) {
					name = "Loss";
				} else {
					name = "Donation";
				}
				hist += "<tr>";
				hist += @"<td>$(dts)</td><td>$(name)</td><td class=\"text-right\">$(diff.amount) €</td>";
				hist += "</tr>\n";
			}

			template.replace("TITLE", shortname + " Shop System: Cashbox");
			template.replace("SHORTNAME", shortname);
			template.replace("CASHBOX_STATUS", status);
			template.replace("CASHBOX_HISTORY", hist);
			template.menu_set_active("cashbox");
			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_cashbox_add(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);

			if(!session.superuser && !session.auth_cashbox) {
				handler_403(server, msg, path, query, client);
				return;
			}

			var template = new WebTemplate("cashbox/add.html", session);
			template.replace("TITLE", shortname + " Shop System: Cashbox Balance");
			template.replace("SHORTNAME", shortname);
			template.menu_set_active("cashbox");

			bool error = false;
			if(query == null || !query.contains("type") || !query.contains("amount"))
				error = true;

			int64 timestamp = (new DateTime.now_utc()).to_unix();
			Price amount = Price.parse(query["amount"]);
			string type = query["type"];

			switch(type) {
				case "withdrawal":
					if(amount > 0)
						amount *= -1;
					db.cashbox_add(session.user, amount, timestamp);
					break;
				case "deposit":
					if(amount < 0)
						amount *= -1;
					db.cashbox_add(session.user, amount, timestamp);
					break;
				case "loss":
					if(amount > 0)
						amount *= -1;
					db.cashbox_add(-3, amount, timestamp);
					break;
				case "donation":
					if(amount < 0)
						amount *= -1;
					db.cashbox_add(-3, amount, timestamp);
					break;
				default:
					error = true;
					break;
			}

			if(error) {
				template.replace("TYPE", "");
				template.replace("AMOUNT", "");
				template.replace("NEW.OK", "none");
				template.replace("NEW.FAIL", "block");
			} else {
				template.replace("TYPE", type);
				template.replace("AMOUNT", amount.to_string());
				template.replace("NEW.OK", "block");
				template.replace("NEW.FAIL", "none");
			}

			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	void handler_cashbox_detail_selection(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		string[] pathparts = path.split("/");

		if(pathparts.length > 4) {
			DateYear year = (DateYear) int.parse(pathparts[3]);
			DateMonth month = (DateMonth) int.parse(pathparts[4]);
			handler_cashbox_detail(server, msg, path, query, client, year, month);
		} else {
			try {
				var session = new WebSession(server, msg, path, query, client);
				var template = new WebTemplate("cashbox/selection.html", session);
				template.replace("TITLE", shortname + " Shop System: Cashbox Detail");
				template.replace("SHORTNAME", shortname);
				template.menu_set_active("cashbox");
				msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
				msg.set_status(200);
			} catch(TemplateError e) {
				stderr.printf(e.message+"\n");
				handler_404(server, msg, path, query, client);
			} catch(DatabaseError e) {
				handler_400(server, msg, path, query, client, e.message);
			} catch(IOError e) {
				handler_400(server, msg, path, query, client, e.message);
			} catch(DBusError e) {
				handler_400(server, msg, path, query, client, e.message);
			}
		}
	}

	void handler_cashbox_detail(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client, DateYear year, DateMonth month) {
		try {
			var session = new WebSession(server, msg, path, query, client);

			if(!session.superuser) {
				handler_403(server, msg, path, query, client);
				return;
			}

			if(!year.valid() || year > 8000) {
				handler_403(server, msg, path, query, client);
				return;
			}

			if(!month.valid()) {
				handler_403(server, msg, path, query, client);
				return;
			}

			var start = new DateTime.local(year, month, 1, 0, 0, 0);
			var stop = start.add_months(1);

			/* guest debit */
			Price debit = 0;
			foreach(var e in db.get_invoice(0, start.to_unix(), stop.to_unix())) {
				debit += e.price;
			}

			Price loss = 0;
			string loss_list = "";
			Price donation = 0;
			string donation_list = "";
			Price withdrawal = 0;
			string withdrawal_list = "";
			foreach(var e in db.cashbox_changes(start.to_unix(), stop.to_unix())) {
				var dt = new DateTime.from_unix_local(e.timestamp);
				var dts = dt.format("%Y-%m-%d %H:%M:%S");

				if(e.user == -3) {
					if(e.amount < 0) {
						loss += e.amount;
						loss_list += @"<tr><td>$(dts)</td><td class=\"text-right\">$(e.amount) €</td></tr>";
					} else {
						donation += e.amount;
						donation_list += @"<tr><td>$(dts)</td><td class=\"text-right\">$(e.amount) €</td></tr>";
					}
				} else {
					var ui = db.get_user_info(e.user);
					var name = @"$(ui.firstname) $(ui.lastname)";
					withdrawal += e.amount;
					withdrawal_list += @"<tr><td>$(dts)</td><td>$(name)</td><td class=\"text-right\">$(e.amount) €</td></tr>";
				}
			}

			var template = new WebTemplate("cashbox/detail.html", session);
			template.replace("TITLE", shortname + " Shop System: Cashbox Detail");
			template.menu_set_active("cashbox");
			template.replace("SHORTNAME", shortname);
			template.replace("DATE", start.format("%B %Y"));
			template.replace("DEBIT", debit.to_string());
			template.replace("LOSS", loss.to_string());
			template.replace("DONATION", donation.to_string());
			template.replace("WITHDRAWAL", withdrawal.to_string());

			template.replace("LOSS_LIST", loss_list);
			template.replace("DONATION_LIST", donation_list);
			template.replace("WITHDRAWAL_LIST", withdrawal_list);

			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
			msg.set_status(200);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		} catch(DatabaseError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(IOError e) {
			handler_400(server, msg, path, query, client, e.message);
		} catch(DBusError e) {
			handler_400(server, msg, path, query, client, e.message);
		}
	}

	public WebServer(uint port = 8080, TlsCertificate? cert = null) throws Error {
		/* get configuration */
		Config config = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
		try {
			longname = config.get_string("GENERAL", "longname");
			shortname = config.get_string("GENERAL", "shortname");
		} catch(KeyFileError e) {
			longname = "Logname Missing in Config";
			shortname = "Shortname Missing in Config";
		}

		srv = new Soup.Server("tls-certificate", cert);
		Soup.ServerListenOptions options = 0;

		if(cert != null)
			options |= Soup.ServerListenOptions.HTTPS;

		if(!srv.listen_all(port, options)) {
			throw new GLib.IOError.FAILED("Could not setup webserver!");
		}

		/* index */
		srv.add_handler("/", handler_default);

		/* logout */
		srv.add_handler("/logout", handler_logout);

		/* data (js, css, img) */
		srv.add_handler("/js", handler_js);
		srv.add_handler("/css", handler_css);
		srv.add_handler("/img", handler_img);

		/* cashbox */
		srv.add_handler("/cashbox", handler_cashbox);
		srv.add_handler("/cashbox/add", handler_cashbox_add);
		srv.add_handler("/cashbox/detail", handler_cashbox_detail_selection);

		/* products */
		srv.add_handler("/products", handler_products);
		srv.add_handler("/products/new", handler_products_new);
		srv.add_handler("/products/bestbefore", handler_product_bestbefore);

		srv.add_handler("/aliases", handler_alias_list);
		srv.add_handler("/aliases/new", handler_alias_new);

#if 0
		/* stats */
		srv.add_handler("/stats", handler_stats);
		srv.add_handler("/stats/stock", handler_stats_stock);
		srv.add_handler("/stats/profit_per_day", handler_stats_profit_per_day);
		srv.add_handler("/stats/profit_per_weekday", handler_stats_profit_per_weekday);
		srv.add_handler("/stats/profit_per_product", handler_stats_profit_per_product);
#endif

		/* users */
		srv.add_handler("/users", handler_users);
		srv.add_handler("/users/import", handler_user_import);
		srv.add_handler("/users/import-pgp", handler_user_pgp_import);
	}
}
