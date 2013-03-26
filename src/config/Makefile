all: config

config: main.vala config.vala config-interface.vala
	valac -o $@ --pkg gio-2.0 $^

clean:
	rm -rf config

.PHONY: all clean
