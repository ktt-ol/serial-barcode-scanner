/* Copyright 2013, Sebastian Reichel <sre@ring0.de>
 * Copyright 2017-2018, Johannes Rudolph <johannes.rudolph@gmx.com>
 * Copyright 2018, Malte Modler <malte@malte-modler.de>
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
	//StatusPanel statuswin;
	MessageBoxOverlay mbOverlay;

	public CursesUI(string binarylocation) {
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
		banner    = new Logo(binarylocation);
		//statuswin = new StatusPanel();
		messages  = new MessageBox();
		clkwin    = new ClockWindow(binarylocation);

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

	// we've disabled the status bar to have more space
	//public void status(string message) {
	//	statuswin.set(message);
	//}

	public void log(MessageType type, string message) {
		switch (type) {
			case MessageType.WARNING:
				messages.add(message, MessageBox.WARN_COLOR);
				break;
			case MessageType.ERROR:
				messages.add(message, MessageBox.ERROR_COLOR);
				break;
			default:
				messages.add(message, MessageBox.INFO_COLOR);
				break;
		}

	}

	public void log_overlay(string title, string message, int closeAfter) {
		mbOverlay = new MessageBoxOverlay(title, message, closeAfter);
		Timeout.add_seconds(closeAfter, closeMbOverlay);
	}

	public void dialog_open(string title, string message, int closeAfter=0) {
		dialog = new Dialog(message, title, closeAfter);
		if (closeAfter > 0) {
			Timeout.add_seconds(closeAfter, close);
		}
	}

	bool closeMbOverlay() {
		mbOverlay = null;
		messages.redraw();
		//statuswin.redraw();
		// just call me once
		return false;
	}

	bool close() {
		dialog_close();
		// just call me once
		return false;
	}

	public void dialog_close() {
		dialog = null;
		messages.redraw();
		banner.redraw();
		clkwin.redraw();
		//statuswin.redraw();
	}
	
	public void setPrivacyMode(bool mode){
                messages.setPrivacyMode(mode);
        }
}
