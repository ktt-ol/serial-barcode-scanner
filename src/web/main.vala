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
string templatedir;

public static int main(string[] args) {
	TlsCertificate? cert = null;
	string certificate = "";
	string privatekey = "";
	uint port = 8080;

	try {
		db  = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Database", "/io/mainframe/shopsystem/database");
		pgp = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.PGP", "/io/mainframe/shopsystem/pgp");
		cfg = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
		templatedir = cfg.get_string("WEB", "filepath");
		port = cfg.get_integer("WEB", "port");

		try {
			certificate = cfg.get_string("WEB", "cert");
			privatekey = cfg.get_string("WEB", "key");
		} catch(KeyFileError e) {
			warning("KeyFileError: %s\n", e.message);
		}
	} catch(IOError e) {
		error("IOError: %s\n", e.message);
	} catch(KeyFileError e) {
		error("KeyFileError: %s\n", e.message);
	}

	stdout.printf("Web Server Port: %u\n", port);
	stdout.printf("TLS certificate: %s\n", certificate);
	stdout.printf("TLS private key: %s\n", privatekey);

	/* attach WebServer to MainLoop */
	try {
		if(certificate != "" && privatekey != "")
			cert = new TlsCertificate.from_files(certificate, privatekey);
		new WebServer(port, cert);
	} catch(Error e) {
		error("Could not start Webserver: %s\n", e.message);
	}

	/* start MainLoop */
	new MainLoop().run();

	return 0;
}
