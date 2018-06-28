include ../../config.mk

LIBCAIROBARCODE=-X -I../libcairobarcode -X -L../libcairobarcode -X -lcairobarcode

all: pdf-stock
	@echo > /dev/null

pdf-stock: main.vala pdf-stock.vala ../database/db-interface.vala ../price.vapi ../libcairobarcode/libcairobarcode.vapi
	${VALAC} -X -D'GETTEXT_PACKAGE="shopsystem"' -X -w ${LIBCAIROBARCODE} -o $@ --pkg cairo --pkg pangocairo --pkg gio-2.0 --pkg posix $^

test: test.vala pdf-stock-interface.vala
	${VALAC} -X -D'GETTEXT_PACKAGE="shopsystem"' -X -w -o $@ --pkg gio-2.0 $^

run: pdf-stock
	LD_LIBRARY_PATH=../libcairobarcode ./pdf-stock

clean:
	rm -rf pdf-stock test

.PHONY: all clean run
