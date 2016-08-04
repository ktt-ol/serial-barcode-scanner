SERVICEFILESIN=$(wildcard *.service.in)
SERVICEFILES=$(basename ${SERVICEFILESIN})
INSTALLPATH=/usr/share/dbus-1/services/
BINARYPATH=$(realpath $(dir $(lastword $(MAKEFILE_LIST)))/../src)
ESCAPEDBINARYPATH=

%.service: %.service.in
	@echo [GEN] $@
	@sed "s~\$${PATH}~${BINARYPATH}~g" $< > $@

all: ${SERVICEFILES}

install: ${SERVICEFILES}
	@echo Installing DBus service files into ${INSTALLPATH}...
	@mkdir -p ${INSTALLPATH}
	@$(foreach file,${SERVICEFILES},install -m644 ${file} ${INSTALLPATH}/${file};)

uninstall:
	@echo Remove DBus service files from ${INSTALLPATH}...
	@$(foreach file,${SERVICEFILES},rm -f ${INSTALLPATH}/${file};)

clean:
	@rm -f ${SERVICEFILES}

.PHONY: all clean install uninstall
