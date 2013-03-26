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

public class CursesUI {
	MessageBox messages;
	Dialog dialog;
	Logo banner;
	ClockWindow clkwin;
	StatusPanel statuswin;

	public CursesUI() {
		/* unicode support */
		Intl.setlocale(LocaleCategory.CTYPE, "");

		/* initialize curses */
		Curses.initscr();

		/* disable cursor */
		Curses.curs_set(0);

		/* initialize color mode and define color pairs */
		Curses.start_color();
		Curses.init_pair(0, Curses.Color.WHITE, Curses.Color.BLACK);
		Curses.init_pair(1, Curses.Color.GREEN, Curses.Color.BLACK);
		Curses.init_pair(2, Curses.Color.WHITE, Curses.Color.RED);

		/* initialize widgets */
		banner    = new Logo();
		statuswin = new StatusPanel();
		messages  = new MessageBox();
		clkwin    = new ClockWindow();

		clkwin.update();

		Timeout.add_seconds(10, update_time);
	}

	~CursesUI() {
		exit();
	}

	public void exit() {
		/* Reset the terminal mode */
		Curses.endwin();
	}

	bool update_time() {
		clkwin.update();
		return true;
	}

	public void status(string message) {
		statuswin.set(message);
	}

	public void log(string message) {
		messages.add(message);
	}

	public void dialog_open(string title, string message) {
		dialog = new Dialog(message, title);
	}

	public void dialog_close() {
		dialog = null;
		messages.redraw();
		banner.redraw();
		clkwin.redraw();
		statuswin.redraw();
	}
}
