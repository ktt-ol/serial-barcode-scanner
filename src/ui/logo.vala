using Curses;

public class Logo {
	Window win;

	public Logo() {
		win = new Window(8, COLS - 2, 0, 1);
		win.bkgdset(COLOR_PAIR(1) | Attribute.BOLD);

		win.addstr("\n");
		win.addstr("   _  ___  _____   ____  _                               _                 \n");
		win.addstr("  | |/ / ||_   _| / ___|| |__   ___  _ __  ___ _   _ ___| |_ ___ _ __ ___  \n");
		win.addstr("  | ' /| __|| |   \\___ \\| '_ \\ / _ \\| '_ \\/ __| | | / __| __/ _ \\ '_ ` _ \\ \n");
		win.addstr("  | . \\| |_ | |    ___) | | | | (_) | |_) \\__ \\ |_| \\__ \\ ||  __/ | | | | |\n");
		win.addstr("  |_|\\_\\\\__||_|   |____/|_| |_|\\___/| .__/|___/\\__, |___/\\__\\___|_| |_| |_|\n");
		win.addstr("                                    |_|        |___/                       \n");

		win.clrtobot();

		win.box(0, 0);

		win.refresh();
	}

	public void redraw() {
		win.touchwin();
		win.refresh();
	}

}
