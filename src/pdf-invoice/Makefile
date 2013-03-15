all: pdf-invoice

pdf-invoice: pdf-invoice.vala ../price.vapi
	valac --pkg pangocairo --pkg posix --pkg gio-2.0 $^

clean:
	rm -rf pdf-invoice

.PHONY: all clean
