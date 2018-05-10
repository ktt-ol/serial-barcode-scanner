DAEMONS=audio backup cli config curses-ui database i18n input-device invoice mail pdf-invoice pdf-stock pgp report scanner-session serial-device input-device web

all:
	@$(foreach dir,$(DAEMONS),cd $(dir) && echo "Building $(dir)..." && make --no-print-directory all ; cd ..;)

clean:
	@$(foreach dir,$(DAEMONS),cd $(dir) && make --no-print-directory clean ; cd ..;)

.PHONY: all clean
