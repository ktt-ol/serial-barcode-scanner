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

using Curses;

public class MessageBox {
	Window win;
	Window subwin;
	DateTime last;

	public MessageBox() {
		win = new Window(LINES-9, COLS - 2, 8, 1);
		win.bkgdset(COLOR_PAIR(0));

		win.clrtobot();
		win.box(0, 0);
		win.refresh();

		subwin = win.derwin(LINES-11, COLS-4, 1, 1);
		subwin.scrollok(true);
		subwin.clrtobot();
		subwin.refresh();

		last = new DateTime.from_unix_utc(0);
	}

	public void add(string msg) {
		var now = new DateTime.now_local();

		if(now.get_day_of_year() != last.get_day_of_year() || now.get_year() != last.get_year()) {
			string curtime = now.format("%Y-%m-%d");
			subwin.addstr("\nDate Changed: " + curtime);
		}

		last = now;

		string curtime = now.format("%H:%M:%S");
		subwin.addstr("\n[" + curtime + "] " + msg);
		subwin.refresh();
	}

	public void redraw() {
		win.touchwin();
		win.refresh();
		subwin.touchwin();
		subwin.refresh();
	}
}
