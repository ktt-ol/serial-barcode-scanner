DAEMONS=audio config curses-ui database pdf-invoice pdf-stock pgp scanner-session serial-device input-device web

all:
	@$(foreach dir,$(DAEMONS),cd $(dir) && echo "Building $(dir)..." && make --no-print-directory all && cd ..;)

clean:
	@$(foreach dir,$(DAEMONS),cd $(dir) && make --no-print-directory clean && cd ..;)

.PHONY: all clean
