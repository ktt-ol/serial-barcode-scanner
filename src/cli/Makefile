all: cli
	@echo > /dev/null

cli: main.vala cli.vala cli-interface.vala ../config/config-interface.vala
	valac -X -D'GETTEXT_PACKAGE="shopsystem"' -X -w -o $@ --pkg linux --pkg posix --pkg gio-2.0 $^

clean:
	rm -rf cli

.PHONY: all clean
