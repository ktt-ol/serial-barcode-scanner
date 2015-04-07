all: web
	@echo > /dev/null

web: main.vala web.vala websession.vala csv.vala template.vala ../database/db-interface.vala ../pgp/pgp-interface.vala ../price.vapi ../config/config-interface.vala
	valac -X -w -o $@ --vapidir=../../vapi --enable-experimental --pkg gee-1.0 --pkg gio-2.0 --pkg libsoup-2.4 --pkg posix $^

clean:
	rm -rf web

.PHONY: all clean
