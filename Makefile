all: compile gettext

build:
	meson build

compile: build
	cd build && ninja

gettext: build
	cd build && ninja shopsystem-pot
	cd build && ninja shopsystem-update-po

install: build
	cd build && DESTDIR=`pwd`/tmpinst ninja install

clean:
	rm -rf build

shop.db: sql/tables.sql sql/views.sql sql/trigger.sql
	@for file in $^ ; do \
		echo "sqlite3 shop.db < $$file"; \
		sqlite3 shop.db < $$file; \
	done

.PHONY: all clean install gettext
