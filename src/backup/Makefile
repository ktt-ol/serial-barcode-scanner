all: backup

backup: main.vala ../mail/mailer-interface.vala ../config/config-interface.vala
	valac -o $@ --pkg gio-2.0 $^

clean:
	rm -f backup

.PHONY: all clean
