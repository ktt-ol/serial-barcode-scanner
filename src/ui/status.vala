using Curses;

public class StatusPanel {
	Window win;

	public StatusPanel() {
		win = new Window(1, COLS - 2, LINES-1, 1);
		win.bkgdset(COLOR_PAIR(2) | Attribute.BOLD);

		win.clrtobot();
		win.refresh();
	}

	public void set(string msg) {
		win.mvaddstr(0,1, msg);
		win.clrtobot();
		win.refresh();
	}

	public void redraw() {
		win.touchwin();
		win.refresh();
	}
}
