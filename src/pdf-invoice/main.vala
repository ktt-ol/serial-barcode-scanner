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

private string datadir;

public static int main(string[] args) {
	Intl.setlocale(LocaleCategory.ALL, "");
	Intl.textdomain("shopsystem");

	try {
		Config cfg = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
		datadir = cfg.get_string("INVOICE", "datadir");
	} catch(DBusError e) {
		error(_("DBus Error: %s\n"), e.message);
	} catch(IOError e) {
		error(_("IO Error: %s\n"), e.message);
	} catch(KeyFileError e) {
		error(_("Config Error: %s\n"), e.message);
	}

	Bus.own_name(
		BusType.SYSTEM,
		"io.mainframe.shopsystem.InvoicePDF",
		BusNameOwnerFlags.NONE,
		on_bus_acquired,
		() => {},
		() => stderr.printf(_("Could not acquire name\n")));

	new MainLoop().run();

	return 0;
}

void on_bus_acquired(DBusConnection conn) {
    try {
        conn.register_object("/io/mainframe/shopsystem/invoicepdf", new InvoicePDF(datadir));
    } catch(Error e) {
        stderr.printf(_("Could not register service: %s\n"), e.message);
    }
}
