all: curses-ui
	@echo > /dev/null

curses-ui: *.vala ../audio/audio-interface.vala ../scanner-session/scannersession-interface.vala
	valac -X -w -o $@ --pkg curses -X -lncursesw --pkg posix --pkg gio-2.0 $^

clean:
	rm -rf curses-ui

.PHONY: all clean
