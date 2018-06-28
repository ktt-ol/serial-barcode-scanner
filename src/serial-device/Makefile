all: serial-device
	@echo > /dev/null

serial-device: main.vala serial-device.vala ../input-device/input-device-interface.vala ../config/config-interface.vala
	valac -X -D'GETTEXT_PACKAGE="shopsystem"' -X -w -o $@ --pkg linux --pkg posix --pkg gio-2.0 $^

clean:
	rm -rf serial-device

.PHONY: all clean
