/* Copyright 2015, Holger Cremer <HolgerCremer@gmail.com>
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

CliImpl cli;
MainLoop ml;
string[] commands;

public static int main(string[] args) {
	if (args.length == 1) {
		stdout.printf("Nothing to send.\nUsage: %s <commnds to send...>\nExample: %s \"USER 1\" \"LOGOUT\"\n", args[0], args[0]);
		return 0;
	}
	commands = args[1:args.length];
	
	cli = new CliImpl();
	Bus.own_name(
		BusType.SYSTEM,
		"io.mainframe.shopsystem.Cli",
		BusNameOwnerFlags.NONE,
		on_bus_aquired,
		on_name_aquired,
		() => stderr.printf("Could not aquire name\n"));

	ml = new MainLoop();

	ml.run();

	return 0;
}

void on_name_aquired() {
	foreach (string cmd in commands) {
		cli.send(cmd);
	}

	// wait a minimal amount of time, to ensure the event was sent
	TimeoutSource time = new TimeoutSource (100);
    time.set_callback (() => {
        ml.quit ();
        return false;
    });
 	time.attach (ml.get_context ());

}

void on_bus_aquired(DBusConnection con) {
    try {
        con.register_object("/io/mainframe/shopsystem/cli", cli);        
    } catch(IOError e) {
        stderr.printf("Could not register service\n");
    }

}