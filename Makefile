PREFIX=/usr/local

# web.vala (currently disabled)
barcode-scanner: main.vala device.vala db.vala
	valac-0.16 --output $@ --pkg posix --pkg linux --pkg libsoup-2.4 --pkg sqlite3 $^

shop.db: create_db.sql
	sqlite3 shop.db < create_db.sql

install: barcode-scanner
	install -m755 barcode-scanner $(DESTDIR)$(PREFIX)/bin/barcode-scanner

clean:
	rm -f barcode-scanner

.PHONY: clean install
