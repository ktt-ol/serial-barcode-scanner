INSTALLPATH=/lib/systemd/system/
UDEVPATH=/lib/udev/rules.d/
SERVICEFILES=$(wildcard *.service)
TIMERFILES=$(wildcard *.timer)
RULESFILES=$(wildcard *.timer)

install: ${SERVICEFILES} ${TIMERFILES} ${RULESFILES}
	@echo Installing systemd files into ${INSTALLPATH}...
	@mkdir -p ${INSTALLPATH}
	@$(foreach file,${SERVICEFILES},install -m644 ${file} ${INSTALLPATH}/${file};)
	@$(foreach file,${TIMERFILES},install -m644 ${file} ${INSTALLPATH}/${file};)
	@echo Installing udev files into ${UDEVPATH}...
	@mkdir -p ${UDEVPATH}
	@$(foreach file,${RULESFILES},install -m644 ${file} ${UDEVPATH}/${file};)

uninstall:
	@echo Remove systemd files from ${INSTALLPATH}...
	@$(foreach file,${SERVICEFILES},rm -f ${INSTALLPATH}/${file};)
	@$(foreach file,${TIMERFILES},rm -f ${INSTALLPATH}/${file};)
	@echo Remove udev files from ${UDEVPATH}...
	@$(foreach file,${RULESFILES},rm -f ${UDEVPATH}/${file};)

.PHONY: install uninstall
