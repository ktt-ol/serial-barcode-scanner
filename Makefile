all:
	@cd src && make --no-print-directory all

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

.PHONY: all clean install
