all: pdf-invoice
	@echo > /dev/null

pdf-invoice: main.vala pdf-invoice.vala pdf-invoice-interface.vala ../config/config-interface.vala ../database/db-interface.vala ../price.vapi
	valac -X -w -g -o $@ --pkg pangocairo --pkg librsvg-2.0 --pkg posix --pkg gdk-2.0 --pkg gio-2.0 $^

test: pdf-invoice-interface.vala ../database/db-interface.vala test.vala ../price.vapi
	valac -X -w -o $@ --pkg gio-2.0 $^

clean:
	rm -rf pdf-invoice test

.PHONY: all clean
