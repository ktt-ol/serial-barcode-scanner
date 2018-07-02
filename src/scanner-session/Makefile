all: scanner-session
	@echo > /dev/null

scanner-session: *.vala ./states/*.vala ../database/db-interface.vala ../input-device/input-device-interface.vala ../cli/cli-interface.vala ../audio/audio-interface.vala ../i18n/i18n-interface.vala ../config/config-interface.vala ../price.vapi
	valac -X -w -o $@ --pkg gio-2.0 $^

clean:
	rm -rf scanner-session

.PHONY: all clean
