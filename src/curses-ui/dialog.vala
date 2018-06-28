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

public class Dialog {
	Window win;
	Window subwin;

	string dialogTitle;
	int dialogWidth;
	int countdownValue;

	public Dialog(string message, string title = "KtT Shopsystem Error", int titleCountdown=0, int h=16, int w=60)
	requires (title.length <= w-4)
	{
		dialogTitle = title;
		dialogWidth = w;
		countdownValue = titleCountdown;
		int y = LINES/2-h/2;
		int x = COLS/2-w/2;

		win = new Window(h, w, y, x);

		/* make the dialog white on red */
		win.bkgdset(COLOR_PAIR(2) | Attribute.BOLD);
		win.clrtobot();

		/* message subwindow */
		subwin = win.derwin(h-4, w-4, 2, 2);
		subwin.clrtobot();
		subwin.printw(message);
		subwin.refresh();

		/* dialog title */
		win.box(0,0);
		setTitle();
		win.refresh();

		if (countdownValue > 0) {
			Timeout.add_seconds(1, decrementTitleCountdown);
		}
	}

	private void setTitle() {
		var title = dialogTitle;
		if (countdownValue > 0) {
			title = "%s (%d)".printf(title, countdownValue);
		}
		int title_x = (dialogWidth-title.length)/2;
		win.mvaddstr(0, title_x, title);
		win.mvaddch(0, title_x-2, Acs.RTEE);
		win.mvaddch(0, title_x-1, ' ');
		win.mvaddch(0, title_x+title.length, ' ');
		win.mvaddch(0, title_x+title.length+1, Acs.LTEE);
		// fixing the countdown (for a reasonable countdown)
		win.mvaddch(0, title_x+title.length+2, Acs.HLINE);
		win.mvaddch(0, title_x+title.length+3, Acs.HLINE);
	}

	private bool decrementTitleCountdown() {
		countdownValue--;
		setTitle();
		win.refresh();
		// run again until countdown is zero
		return countdownValue > 0;
	}
}
