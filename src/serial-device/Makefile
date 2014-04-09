all: serial-device

serial-device: main.vala serial-device.vala serial-device-interface.vala ../config/config-interface.vala
	valac -X -w -o $@ --pkg linux --pkg posix --pkg gio-2.0 $^

clean:
	rm -rf serial-device

.PHONY: all clean
