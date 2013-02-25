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
