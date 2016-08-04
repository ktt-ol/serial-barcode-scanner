all: backup
	@echo > /dev/null

backup: main.vala ../mail/mailer-interface.vala ../config/config-interface.vala
	valac -X -w -o $@ --pkg gio-2.0 $^

clean:
	rm -f backup

.PHONY: all clean
