CONFIGFILES=$(wildcard *.conf)
INSTALLPATH=/etc/dbus-1/system.d

all:

install: ${CONFIGFILES}
	@echo Installing DBus config files into ${INSTALLPATH}...
	@mkdir -p ${INSTALLPATH}
	@$(foreach file,${CONFIGFILES},install -m644 ${file} ${INSTALLPATH}/${file};)

uninstall:
	@echo Remove DBus config files from ${INSTALLPATH}...
	@$(foreach file,${CONFIGFILES},rm -f ${INSTALLPATH}/${file};)

.PHONY: all install uninstall
