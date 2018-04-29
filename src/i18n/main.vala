/* Copyright 2018, Johannes Rudolph <johannes.rudolph@gmx.com>
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

I18N i18n;

public static int main(string[] args) {
	string binarylocation = File.new_for_path(args[0]).get_parent().get_path();

	i18n = new I18N(binarylocation + "/../../i18n/i18n.cfg");

	Bus.own_name(
		BusType.SYSTEM,
		"io.mainframe.shopsystem.I18n",
		BusNameOwnerFlags.NONE,
		on_bus_aquired,
		() => {},
		() => stderr.printf("Could not aquire name\n"));

	new MainLoop().run();

	return 0;
}

void on_bus_aquired(DBusConnection con) {
    try {
        con.register_object("/io/mainframe/shopsystem/i18n", i18n);
    } catch(IOError e) {
        stderr.printf("Could not register service\n");
    }
}
