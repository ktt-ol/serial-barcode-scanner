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

public class ClockWindow {
	AsciiNumbers ascii;
	Window win;
	string dateformat;
	Config cfg;

	public ClockWindow() {
		ascii = new AsciiNumbers();
		win   = new Window(6, 18, 1, COLS-2-18);
		win.bkgdset(COLOR_PAIR(0) | Attribute.BOLD);

		win.clrtobot();
		win.box(0, 0);
		
		cfg = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
		dateformat = cfg.get_string("DATE-FORMAT", "format");

		win.refresh();
	}

	public void update() {
		string[] x;
		var now = new DateTime.now_local();

		x = ascii.get('0' + (char) (now.get_hour() / 10));
		win.mvaddstr(1,1, x[0]);
		win.mvaddstr(2,1, x[1]);
		win.mvaddstr(3,1, x[2]);

		x = ascii.get('0' + (char) (now.get_hour() % 10));
		win.mvaddstr(1,4, x[0]);
		win.mvaddstr(2,4, x[1]);
		win.mvaddstr(3,4, x[2]);

		x = ascii.get(':');
		win.mvaddstr(1,7, x[0]);
		win.mvaddstr(2,7, x[1]);
		win.mvaddstr(3,7, x[2]);

		x = ascii.get('0' + (char) (now.get_minute() / 10));
		win.mvaddstr(1,10, x[0]);
		win.mvaddstr(2,10, x[1]);
		win.mvaddstr(3,10, x[2]);

		x = ascii.get('0' + (char) (now.get_minute() % 10));
		win.mvaddstr(1,13, x[0]);
		win.mvaddstr(2,13, x[1]);
		win.mvaddstr(3,13, x[2]);


		win.clrtobot();
		win.box(0, 0);

		win.mvaddstr(5,4, now.format(dateformat));

		win.refresh();
	}

	public void redraw() {
		win.touchwin();
		win.refresh();
	}

}
