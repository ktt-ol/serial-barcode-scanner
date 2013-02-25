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
