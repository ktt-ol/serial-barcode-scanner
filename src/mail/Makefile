all: mailer
	@echo > /dev/null

mailer: main.vala mailer.vala mail.vala mailer-interface.vala ../config/config-interface.vala
	valac -X -w -o $@ --vapidir=../../vapi --pkg posix --pkg libesmtp --pkg gio-2.0 --pkg gmime-2.6 -X -D_GNU_SOURCE -X -lesmtp -X -lssl -X -lcrypto -X -ldl -X -pthread $^

clean:
	rm -f mailer

.PHONY: all clean
