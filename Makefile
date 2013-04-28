all:
	cd src && make all

clean:
	cd src && make clean

install:
	cd src && make install
	cd dbus && make install

shop.db: sql/tables.sql sql/views.sql sql/trigger.sql
	@for file in $^ ; do \
		echo "sqlite3 shop.db < $$file"; \
		sqlite3 shop.db < $$file; \
	done

.PHONY: all clean install
