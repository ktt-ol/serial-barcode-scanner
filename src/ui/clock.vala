using Curses;

public class ClockWindow {
	AsciiNumbers ascii;
	Window win;

	public ClockWindow() {
		ascii = new AsciiNumbers();
		win   = new Window(6, 18, 1, COLS-2-18);
		win.bkgdset(COLOR_PAIR(0) | Attribute.BOLD);

		win.clrtobot();
		win.box(0, 0);

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

		win.mvaddstr(5,4, now.format("%Y-%m-%d"));

		win.refresh();
	}

	public void redraw() {
		win.touchwin();
		win.refresh();
	}

}
