DAEMONS=audio config curses-ui database pdf-invoice pdf-stock pgp scanner-session serial-device web

all:
	@$(foreach dir,$(DAEMONS),cd $(dir) && make all && cd ..;)

clean:
	@$(foreach dir,$(DAEMONS),cd $(dir) && make clean && cd ..;)

.PHONY: all clean
