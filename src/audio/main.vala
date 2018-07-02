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

AudioPlayerImplementation player;

public static int main(string[] args) {
	Gst.init(ref args);

	Bus.own_name(
		BusType.SYSTEM,
		"io.mainframe.shopsystem.AudioPlayer",
		BusNameOwnerFlags.NONE,
		on_bus_aquired,
		() => {},
		() => stderr.printf("Could not aquire name\n"));

	try {
		Config cfg = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
		var path = cfg.get_string("AUDIO", "path");
		player = new AudioPlayerImplementation(path);
	} catch(IOError e) {
		error("IOError: %s\n", e.message);
	} catch(KeyFileError e) {
		error("KeyFileError Audo path not defined: %s\n", e.message);
	}

	new MainLoop().run();

	return 0;
}

void on_bus_aquired(DBusConnection con) {
    try {
        con.register_object("/io/mainframe/shopsystem/audio", player);
    } catch(IOError e) {
        stderr.printf("Could not register service\n");
    }
}
