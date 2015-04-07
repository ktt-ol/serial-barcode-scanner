all: config
	@echo > /dev/null

config: main.vala config.vala config-interface.vala
	valac -X -w -o $@ --pkg gio-2.0 $^

clean:
	rm -rf config

.PHONY: all clean
