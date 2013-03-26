all: curses-ui

curses-ui: clock.vala curses-ui.vala dialog.vala logo.vala main.vala message_box.vala numbers.vala status.vala ../audio/audio-interface.vala
	valac -o $@ --pkg curses -X -lncursesw --pkg posix --pkg gio-2.0 $^

clean:
	rm -rf curses-ui

.PHONY: all clean
