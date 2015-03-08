include ../config.mk

all: libcairobarcode.so

libcairobarcode.so: ean.vala code39.vala error.vala
	${VALAC} -o $@ -H libcairobarcode.h --library libcairobarcode -X -fPIC -X -shared --pkg cairo $^

clean:
	rm -f libcairobarcode.h libcairobarcode.so libcairobarcode.vapi

.PHONY: all clean
