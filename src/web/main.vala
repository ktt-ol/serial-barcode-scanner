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

Database db;
public CSVMemberFile csvimport;
public PGP pgp;
public Config cfg;
public AudioPlayer audio;
public PDFStock pdfStock;
string templatedir;
string? shortname;

public static int main(string[] args) {
	Intl.setlocale(LocaleCategory.ALL, "");
	Intl.textdomain("shopsystem");

	TlsCertificate? cert = null;
	string certificate = "";
	string privatekey = "";
	uint port = 8080;

	try {
		db  = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Database", "/io/mainframe/shopsystem/database");
		pgp = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.PGP", "/io/mainframe/shopsystem/pgp");
		cfg = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
		audio = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.AudioPlayer", "/io/mainframe/shopsystem/audio");
		pdfStock = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.StockPDF", "/io/mainframe/shopsystem/stockpdf");
		var datapath = cfg.get_string("GENERAL", "datapath");
		templatedir = Path.build_filename(datapath, "templates");
		port = cfg.get_integer("WEB", "port");
	} catch(IOError e) {
		error(_("IO Error: %s\n"), e.message);
	} catch(KeyFileError e) {
		error(_("KeyFile Error: %s\n"), e.message);
	} catch(DBusError e) {
		error(_("DBus Error: %s\n"), e.message);
	}

	try {
		certificate = cfg.get_string("WEB", "cert");
		privatekey = cfg.get_string("WEB", "key");
	} catch(KeyFileError e) {
		warning(_("KeyFile Error: %s\n"), e.message);
	} catch(IOError e) {
		error(_("IO Error: %s\n"), e.message);
	} catch(DBusError e) {
		error(_("DBus Error: %s\n"), e.message);
	}

	try {
		shortname = cfg.get_string("GENERAL", "shortname");
	} catch(KeyFileError e) {
		shortname = "";
		warning(_("KeyFile Error: %s\n"), e.message);
	} catch(IOError e) {
		error(_("IO Error: %s\n"), e.message);
	} catch(DBusError e) {
		error(_("DBus Error: %s\n"), e.message);
	}

	stdout.printf(_("Web Server Port: %u\n"), port);
	stdout.printf(_("TLS certificate: %s\n"), certificate);
	stdout.printf(_("TLS private key: %s\n"), privatekey);

	/* attach WebServer to MainLoop */
	try {
		if(certificate != "" && privatekey != "")
			cert = new TlsCertificate.from_files(certificate, privatekey);
		new WebServer(port, cert);
	} catch(Error e) {
		error(_("Could not start Webserver: %s\n"), e.message);
	}

	/* start MainLoop */
	new MainLoop().run();

	return 0;
}
