using Curses;

public class Dialog {
	Window win;
	Window subwin;

	public Dialog(string message, string title = "KtT Shopsystem Error", int h=16, int w=60)
	requires (title.length <= w-4)
	{
		int y = LINES/2-h/2;
		int x = COLS/2-w/2;

		int title_x = (w-title.length)/2;

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
		win.mvaddstr(0, title_x, title);
		win.mvaddch(0, title_x-2, Acs.RTEE);
		win.mvaddch(0, title_x-1, ' ');
		win.mvaddch(0, title_x+title.length, ' ');
		win.mvaddch(0, title_x+title.length+1, Acs.LTEE);
		win.refresh();
	}
}
