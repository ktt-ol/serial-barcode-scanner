include ../config.mk

all: test

libcairobarcode.so:
	#TODO

test: test.vala ean.vala code39.vala error.vala
	${VALAC} -o $@ --pkg cairo $^

clean:
	rm -f test test.svg

.PHONY: all clean
