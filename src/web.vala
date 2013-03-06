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

	void handler_default(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			var t = new WebTemplate("index.html", l);
			t.replace("TITLE", "KtT Shop System");
			t.menu_set_active("home");
			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_logout(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			l.logout();
			var t = new WebTemplate("logout.html", l);
			t.replace("TITLE", "KtT Shop System");
			t.menu_set_active("home");
			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
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
			if(!session.superuser) {
				handler_403(server, msg, path, query, client);
				return;
			}

			var t = new WebTemplate("users/index.html", session);
			t.replace("TITLE", "KtT Shop System: User");
			t.menu_set_active("users");
			var data = "";
			foreach(var m in db.get_member_ids()) {
				try {
					var name = db.get_username(m);
					data += @"<tr><td>$m</td><td><a href=\"/users/$m\">$name</a></td></tr>";
				} catch(WebSessionError e) {
				}
			}
			t.replace("DATA", data);

			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_user_pgp_import(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			if(!session.superuser) {
				handler_403(server, msg, path, query, client);
				return;
			}

			var t = new WebTemplate("users/import-pgp.html", session);
			t.replace("TITLE", "KtT Shop System: PGP Key Import");
			t.menu_set_active("users");

			Soup.Buffer filedata;
			var postdata = Soup.Form.decode_multipart(msg, "file", null, null, out filedata);

			if(postdata == null || !postdata.contains("step")) {
				t.replace("DATA", "");
				t.replace("STEP1",  "block");
				t.replace("STEP2",  "none");
				msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
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
				return;
			}
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_user_import(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			if(!session.superuser) {
				handler_403(server, msg, path, query, client);
				return;
			}
			var t = new WebTemplate("users/import.html", session);
			t.replace("TITLE", "KtT Shop System: User Import");
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
					if(member.exists_in_db() && !member.equals_db()) {
						var dbmember = db.get_user_info(member.id);
						data1 += @"<tr class=\"error\"><td><i class=\"icon-minus-sign\"></i><td>$(dbmember.id)</td><td>$(dbmember.firstname)</td><td>$(dbmember.lastname)</td><td>$(dbmember.email)</td><td>$(dbmember.gender)</td><td>$(dbmember.street)</td><td>$(dbmember.postcode)</td><td>$(dbmember.city)</td><td>$(dbmember.pgp)</td></tr>";
					}
					if(!member.exists_in_db() || !member.equals_db()) {
						data1 += @"<tr class=\"success\"><td><i class=\"icon-plus-sign\"></td><td>$(member.id)</td><td>$(member.firstname)</td><td>$(member.lastname)</td><td>$(member.email)</td><td>$(member.gender)</td><td>$(member.street)</td><td>$(member.postcode)</td><td>$(member.city)</td><td>$(member.pgp)</td></tr>";
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
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_user_entry(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client, int id) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			if(id != session.user && !session.superuser) {
				handler_403(server, msg, path, query, client);
				return;
			}
			var t = new WebTemplate("users/entry.html", session);
			t.replace("TITLE", "KtT Shop System: User Info %llu".printf(id));
			t.menu_set_active("users");

			var userinfo = db.get_user_info(id);

			t.replace("UID", "%d".printf(userinfo.id));
			t.replace("FIRSTNAME", userinfo.firstname);
			t.replace("LASTNAME", userinfo.lastname);
			t.replace("EMAIL", userinfo.email);
			t.replace("GENDER", userinfo.gender);
			t.replace("STREET", userinfo.street);
			t.replace("POSTALCODE", "%d".printf(userinfo.postcode));
			t.replace("CITY", userinfo.city);
			t.replace("PGPKEYID", userinfo.pgp);

			var userauth = db.get_user_auth(id);
			t.replace("DISABLED", userauth.disabled ? "true" : "false");
			t.replace("ISSUPERUSER", userauth.superuser ? "true" : "false");

			var postdata = Soup.Form.decode_multipart(msg, null, null, null, null);
			if(postdata != null && postdata.contains("password1") && postdata.contains("password2")) {
				if(postdata["password1"] != postdata["password2"]) {
					t.replace("MESSAGE", "<div class=\"alert alert-error\">Error! Passwords do not match!</div>");
				} else if(postdata["password1"] == "") {
					t.replace("MESSAGE", "<div class=\"alert alert-error\">Error! Empty Password not allowed!</div>");
				} else {
					db.set_user_password(id, postdata["password1"]);
					t.replace("MESSAGE", "<div class=\"alert alert-success\">Password Changed!</div>");
				}
			} else {
				t.replace("MESSAGE", "");
			}

			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
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
			if(id != l.user && !l.superuser) {
				handler_403(server, msg, path, query, client);
				return;
			}
			var t = new WebTemplate("users/invoice.html", l);
			t.replace("TITLE", "KtT Shop System: User Invoice %llu".printf(id));
			t.menu_set_active("users");

			/* years, in which something has been purchased by the user */
			var first = db.get_first_purchase(id);
			var last  = db.get_last_purchase(id);
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
				var timestamp = new DateTime.from_unix_utc(e.timestamp);
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
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
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
			t.replace("TITLE", "KtT Shop System: Product List");
			t.menu_set_active("products");

			string table = "";
			foreach(var e in db.get_stock()) {
				table += "<tr><td><a href=\"/products/%s\">%s</a></td><td><a href=\"/products/%s\">%s</a></td><td>%d</td><td>%s€</td><td>%s€</td></tr>".printf(
					e.id, e.id, e.id, e.name, e.amount, e.memberprice, e.guestprice
				);
			}

			t.replace("DATA", table);

			if(l.superuser)
				t.replace("NEWPRODUCT", "block");
			else
				t.replace("NEWPRODUCT", "none");

			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_product_entry(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client, uint64 id) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			var t = new WebTemplate("products/entry.html", l);
			t.replace("TITLE", "KtT Shop System: Product %llu".printf(id));
			t.menu_set_active("products");

			/* ean */
			t.replace("EAN", "%llu".printf(id));

			/* name */
			string name = db.get_product_name(id);
			t.replace("NAME", name);

			/* amount */
			t.replace("AMOUNT", "%d".printf(db.get_product_amount(id)));

			if(l.superuser)
				t.replace("ISADMIN", "block");
			else
				t.replace("ISADMIN", "none");

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
			foreach(var e in db.get_restocks(id)) {
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
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_products_new(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			var template = new WebTemplate("products/new.html", session);
			template.replace("TITLE", "KtT Shop System: New Product");
			template.menu_set_active("products");

			if(!session.superuser) {
				handler_403(server, msg, path, query, client);
				return;
			}

			if(query != null && query.contains("name") && query.contains("id") && query.contains("memberprice") && query.contains("guestprice")) {
				var name = query["name"];
				var ean = uint64.parse(query["id"]);
				Price memberprice = Price.parse(query["memberprice"]);
				Price guestprice  = Price.parse(query["guestprice"]);

				if(ean > 0 && memberprice > 0 && guestprice > 0 && db.new_product(ean, name, memberprice, guestprice)) {
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
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_product_restock(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client, uint64 id) {
		try {
			var session = new WebSession(server, msg, path, query, client);

			if(!session.superuser) {
				handler_403(server, msg, path, query, client);
				return;
			}

			var template = new WebTemplate("products/restock.html", session);
			template.replace("TITLE", "KtT Shop System: Restock Product %llu".printf(id));
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

				if(amount >= 1 && price >= 1) {
					if(db.restock(session.user, id, amount, price, supplier, bbd.to_unix())) {
						template.replace("AMOUNT", @"$amount");
						template.replace("PRICE", @"$price");
						template.replace("BESTBEFORE", bbd.format("%Y-%m-%d"));
						template.replace("SUPPLIER", db.get_supplier(supplier).name);
						template.replace("RESTOCK.OK", "block");
						template.replace("RESTOCK.FAIL", "none");
						msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
						return;
					}
				}
			}

			template.replace("RESTOCK.OK", "none");
			template.replace("RESTOCK.FAIL", "block");
			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
			return;
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_product_newprice(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client, uint64 id) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			int64 timestamp = (new DateTime.now_utc()).to_unix();

			if(!session.superuser) {
				handler_403(server, msg, path, query, client);
				return;
			}

			var template = new WebTemplate("products/newprice.html", session);
			template.replace("TITLE", "KtT Shop System: New Price for Product %llu".printf(id));
			template.replace("NAME", db.get_product_name(id));
			template.menu_set_active("products");

			if(query != null && query.contains("guest") && query.contains("member")) {
				Price member = Price.parse(query["member"]);
				Price guest =  Price.parse(query["guest"]);

				if(guest >= 1 && member >= 1) {
					if(db.new_price(id, timestamp, member, guest)) {
						template.replace("GUEST", @"$guest");
						template.replace("MEMBER", @"$member");
						template.replace("NEWPRICE.OK", "block");
						template.replace("NEWPRICE.FAIL", "none");
						msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
						return;
					}
				}
			}

			template.replace("NEWPRICE.OK", "none");
			template.replace("NEWPRICE.FAIL", "block");
			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
			return;
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}


	void handler_stats(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var l = new WebSession(server, msg, path, query, client);
			var t = new WebTemplate("stats/index.html", l);
			t.replace("TITLE", "KtT Shop System: Statistics");
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
			t.replace("TITLE", "KtT Shop System: Statistics: Stock");
			t.menu_set_active("stats");
			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
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
			t.replace("TITLE", "KtT Shop System: Statistics: Profit");
			t.menu_set_active("stats");
			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
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
			t.replace("TITLE", "KtT Shop System: Statistics: Profit/Weekday");
			t.menu_set_active("stats");
			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
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
			t.replace("TITLE", "KtT Shop System: Statistics: Profit/Product");
			t.menu_set_active("stats");
			msg.set_response("text/html", Soup.MemoryUse.COPY, t.data);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_js(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var t = new WebTemplate.DATA(path);
			msg.set_response("text/javascript", Soup.MemoryUse.COPY, t.data);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_css(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var t = new WebTemplate.DATA(path);
			msg.set_response("text/css", Soup.MemoryUse.COPY, t.data);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	void handler_img(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var f = File.new_for_path("templates/"+path);
			uint8[] data = null;

			if(f.query_exists() && f.load_contents(null, out data, null)) {
				msg.set_response("image/png", Soup.MemoryUse.COPY, data);
				return;
			}
		} catch(Error e) {
			error("there has been some error: %s!\n", e.message);
		}

		handler_404(server, msg, path, query, client);
		return;
	}

	void handler_404(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		string result = "Page not Found\n";
		msg.set_status(404);
		msg.set_response("text/plain", Soup.MemoryUse.COPY, result.data);
	}

	void handler_403(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			var template = new WebTemplate("errors/403.html", session);
			template.replace("TITLE", "Access Denied");
			template.menu_set_active("");
			msg.set_status(403);
			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}	}

	void handler_todo(Soup.Server server, Soup.Message msg, string path, GLib.HashTable? query, Soup.ClientContext client) {
		try {
			var session = new WebSession(server, msg, path, query, client);
			var template = new WebTemplate("errors/todo.html", session);
			template.replace("TITLE", "KtT Shop System: ToDo");
			template.menu_set_active("");
			msg.set_response("text/html", Soup.MemoryUse.COPY, template.data);
		} catch(TemplateError e) {
			stderr.printf(e.message+"\n");
			handler_404(server, msg, path, query, client);
		}
	}

	public WebServer(int port = 8080) {
		srv = new Soup.Server(Soup.SERVER_PORT, port);

		/* index */
		srv.add_handler("/", handler_default);

		/* logout */
		srv.add_handler("/logout", handler_logout);

		/* data (js, css, img) */
		srv.add_handler("/js", handler_js);
		srv.add_handler("/css", handler_css);
		srv.add_handler("/img", handler_img);

		/* products */
		srv.add_handler("/products", handler_products);
		srv.add_handler("/products/new", handler_products_new);

		/* stats */
		srv.add_handler("/stats", handler_stats);
		srv.add_handler("/stats/stock", handler_stats_stock);
		srv.add_handler("/stats/profit_per_day", handler_stats_profit_per_day);
		srv.add_handler("/stats/profit_per_weekday", handler_stats_profit_per_weekday);
		srv.add_handler("/stats/profit_per_product", handler_stats_profit_per_product);

		/* users */
		srv.add_handler("/users", handler_users);
		srv.add_handler("/users/import", handler_user_import);
		srv.add_handler("/users/import-pgp", handler_user_pgp_import);

		srv.run_async();
	}
}
