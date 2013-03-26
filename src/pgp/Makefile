all: pgp

pgp: main.vala pgp.vala pgp-interface.vala ../config/config-interface.vala
	valac -o $@ --vapidir ../../vapi -X -lgpgme --pkg gpgme --pkg gio-2.0 --pkg libarchive $^

clean:
	rm -rf pgp

.PHONY: all clean
