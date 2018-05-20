all: mqtt
	@echo > /dev/null

mqtt: *.vala ../config/config-interface.vala
	valac -X -w -o $@ --pkg gio-2.0 --pkg posix $^

clean:
	rm -f report

.PHONY: all clean
