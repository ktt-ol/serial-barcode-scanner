all: invoice

invoice: main.vala invoice.vala ../mail/mailer-interface.vala ../pdf-invoice/pdf-invoice-interface.vala ../database/db-interface.vala ../config/config-interface.vala ../price.vapi
	valac -X -w -o $@ --pkg gio-2.0 $^

clean:
	rm -f invoice

.PHONY: all clean
