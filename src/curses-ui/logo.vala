/* Copyright 2013, Sebastian Reichel <sre@ring0.de>
 * Copyright 2017-2018, Johannes Rudolph <johannes.rudolph@gmx.com>
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

using Curses;

public class Logo {
	Window win;

	public Logo(string binarylocation) {
		win = new Window(8, COLS - 2, 0, 1);
		win.bkgdset(COLOR_PAIR(1) | Attribute.BOLD);

		win.addstr("\n");

		var file = File.new_for_path (binarylocation + "/../../logo.txt");

		if (!file.query_exists ()) {
			stderr.printf ("File '%s' doesn't exist.\n", file.get_path ());
		}

		try {
			// Open file for reading and wrap returned FileInputStream into a
			// DataInputStream, so we can read line by line
			var dis = new DataInputStream (file.read ());
			string line;
			// Read lines until end of file (null) is reached
			while ((line = dis.read_line (null)) != null) {
				win.addstr(line+"\n");
			}
		} catch (Error e) {
			error ("%s", e.message);
		}

		win.clrtobot();

		win.box(0, 0);

		win.refresh();
	}

	public void redraw() {
		win.touchwin();
		win.refresh();
	}

}
