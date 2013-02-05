SRC=src/main.vala src/device.vala src/scannersession.vala  src/db.vala src/audio.vala src/web.vala src/graph-data.vala src/template.vala src/websession.vala src/admin.vala src/price.vapi
DEPS=--pkg posix --pkg linux --pkg libsoup-2.4 --pkg sqlite3 --pkg gee-1.0 --pkg gio-2.0 --pkg gstreamer-0.10 --pkg libarchive --pkg gpgme
FLAGS=-X -lgpgme -X -w --enable-experimental --thread --vapidir=vapi

barcode-scanner: $(SRC)
	valac-0.16 --output $@ $(FLAGS) $(DEPS) $^

shop.db: sql/tables.sql sql/views.sql sql/trigger.sql
	@for file in $^ ; do \
		echo "sqlite3 shop.db < $$file"; \
		sqlite3 shop.db < $$file; \
	done

run: barcode-scanner
	./barcode-scanner /dev/ttyS0

clean:
	@rm -f barcode-scanner src/*.c

.PHONY: clean install
