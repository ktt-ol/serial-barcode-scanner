all: database
	@echo > /dev/null

database: main.vala database.vala db-interface.vala ../config/config-interface.vala ../price.vapi
	valac -X -w -o $@ --pkg sqlite3 --pkg gee-1.0 --pkg gio-2.0 $^

clean:
	rm -rf db

.PHONY: all clean
