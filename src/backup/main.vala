/* Copyright 2013, Sebastian Reichel <sre@ring0.de>
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

public static int main(string[] args) {
	try {
		Mailer mailer = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Mail", "/io/mainframe/shopsystem/mailer");
		Config cfg = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
		string dbfile = cfg.get_string("DATABASE", "file");

		string mailpath = mailer.create_mail();
		Mail mail = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Mail", mailpath);

		uint8[] dbdata;
		FileUtils.get_data(dbfile, out dbdata);

		var now = new DateTime.now_local().format(cfg.get_string("DATE-TIME", "formatDateTime"));

		mail.from = {cfg.get_string("GENERAL", "shortname")+" Shopsystem", cfg.get_string("MAIL", "mailfromaddress")};
		mail.add_recipient({cfg.get_string("MAIL", "backupaddress")}, RecipientType.TO);
		mail.subject = "Backup " cfg.get_string("GENERAL", "shortname")+" Shopsystem" +" "+now;
		mail.set_main_part("You can find a backup of 'shop.db' attached to this mail.", MessageType.PLAIN);
		mail.add_attachment("shop.db", "application/x-sqlite3", dbdata);

		mailer.send_mail(mailpath);
	} catch(Error e) {
		stderr.printf("Error: %s\n", e.message);
	}

	return 0;
}
