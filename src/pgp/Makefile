all: pgp
	@echo > /dev/null

pgp: main.vala pgp.vala pgp-interface.vala ../config/config-interface.vala
	valac -X -D'GETTEXT_PACKAGE="shopsystem"' --Xcc="-D_FILE_OFFSET_BITS=64" -X -w -o $@ --vapidir ../../vapi -X -lgpgme --pkg gpgme --pkg gio-2.0 --pkg libarchive $^

clean:
	rm -rf pgp

.PHONY: all clean
