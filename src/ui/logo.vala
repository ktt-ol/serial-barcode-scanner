using Curses;

public class Logo {
	Window win;

	public Logo() {
		win = new Window(8, COLS - 2, 0, 1);
		win.bkgdset(COLOR_PAIR(1) | Attribute.BOLD);

		win.addstr("\n");
		win.addstr("   _  ___  _____   ____  _                 \n");
		win.addstr("  | |/ / ||_   _| / ___|| |__   ___  _ __  \n");
		win.addstr("  | ' /| __|| |   \\___ \\| '_ \\ / _ \\| '_ \\ \n");
		win.addstr("  | . \\| |_ | |    ___) | | | | (_) | |_) )\n");
		win.addstr("  |_|\\_\\\\__||_|   |____/|_| |_|\\___/| .__/ \n");
		win.addstr("                                    |_|    \n");

		win.clrtobot();

		win.box(0, 0);

		win.refresh();
	}

	public void redraw() {
		win.touchwin();
		win.refresh();
	}

}
