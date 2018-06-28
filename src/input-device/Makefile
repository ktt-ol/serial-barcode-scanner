all: input-device
	@echo > /dev/null

input-device: main.vala input-device.vala input-device-interface.vala ../config/config-interface.vala
	valac -X -D'GETTEXT_PACKAGE="shopsystem"' -X -w -o $@ --pkg linux --pkg posix --pkg gio-2.0 $^

clean:
	rm -rf input-device

.PHONY: all clean
