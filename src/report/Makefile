all: report
	@echo > /dev/null

report: *.vala ../mail/mailer-interface.vala ../database/db-interface.vala ../config/config-interface.vala ../price.vapi
	valac -X -w -o $@ --pkg gio-2.0 $^

clean:
	rm -f report

.PHONY: all clean
