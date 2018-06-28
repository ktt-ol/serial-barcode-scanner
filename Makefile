all:
	@cd src && make --no-print-directory all

gettext: locale/de/LC_MESSAGES/shopsystem.mo

locale/de/LC_MESSAGES/shopsystem.mo: locale/de.po
	install -d locale/de/LC_MESSAGES/
	msgfmt -o $@ $<

locale/%.po: locale/messages.pot
	msgmerge -N --backup=off --update $@ $<

locale/messages.pot: */*/*.vala
	xgettext --language=vala --from-code=utf-8 --keyword=_ --escape --sort-output -o $@ */*/*.vala

clean:
	@cd src && make --no-print-directory clean

install:
	@cd src && make --no-print-directory install
	@cd dbus && make --no-print-directory install

shop.db: sql/tables.sql sql/views.sql sql/trigger.sql
	@for file in $^ ; do \
		echo "sqlite3 shop.db < $$file"; \
		sqlite3 shop.db < $$file; \
	done

.PHONY: all clean install gettext
