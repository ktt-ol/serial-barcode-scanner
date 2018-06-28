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

using Curses;

public class MessageBoxOverlay {
	Window win;
	string dialogTitle;
	int countdownValue;

	public MessageBoxOverlay(string title, string message, int countdown) {
		dialogTitle = title;
		countdownValue = countdown;

		win = new Window(LINES-10, COLS - 4, 9, 2);
		win.bkgdset(COLOR_PAIR(2) | Attribute.BOLD);

		win.clrtobot();
		win.refresh();

		win.addstr("\n" + message);
		setTitle();
		win.refresh();

		Timeout.add_seconds(1, decrementTitleCountdown);
	}

	private void setTitle() {
		var title = "    === %s (%d) ===    ".printf(dialogTitle, countdownValue);
		int title_x = (COLS - title.length)/2;
		win.mvaddstr(0, title_x, title);
	}

	private bool decrementTitleCountdown() {
		countdownValue--;
		setTitle();
		win.refresh();
		// run again until countdown is zero
		return countdownValue > 0;
	}
}
