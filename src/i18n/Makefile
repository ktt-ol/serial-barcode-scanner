all: i18n
	@echo > /dev/null

i18n: main.vala i18n.vala i18n-interface.vala
	valac -X -w -o $@ --pkg gio-2.0 $^

clean:
	rm -rf i18n

.PHONY: all clean
