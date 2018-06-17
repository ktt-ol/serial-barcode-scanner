/* Copyright 2015, Sebastian Reichel <sre@ring0.de>
 * Copyright 2017-2018, Johannes Rudolph <johannes.rudolph@gmx.com>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

[DBus (name = "io.mainframe.shopsystem.InputDevice")]
public class Device {
	private IOChannel io_read;
	private string buffer;
	private bool shift;
	private string device;

	public signal void received_barcode(string barcode);

	public Device(string device) {
		this.device = device;
		if (this.device == "ignore") {
 			stdout.printf("Ignoring InputDevice!\n");
 			return;
 		}
		this.connect();
	}
	
	private void connect(){
		try {
			io_read = new IOChannel.file(this.device, "r");
			this.buffer = "";
			this.shift = false;

			int fd = io_read.unix_get_fd();
			int flags = Posix.fcntl(fd, Posix.F_GETFL, 0);
			Posix.fcntl(fd, Posix.F_SETFL, flags | Posix.O_NONBLOCK);

			if(!(io_read.add_watch(IOCondition.IN | IOCondition.HUP, device_read) != 0)) {
				error("Could not bind IOChannel");
			}
		} catch(FileError e) {
			error("FileError: %s", e.message);
		}
	}

	private char linux_event_lookup(uint16 code) {
		int c = code;

		switch(c) {
			case Linux.Input.KEY_0:
				return '0';
			case Linux.Input.KEY_1:
				return '1';
			case Linux.Input.KEY_2:
				return '2';
			case Linux.Input.KEY_3:
				return '3';
			case Linux.Input.KEY_4:
				return '4';
			case Linux.Input.KEY_5:
				return '5';
			case Linux.Input.KEY_6:
				return '6';
			case Linux.Input.KEY_7:
				return '7';
			case Linux.Input.KEY_8:
				return '8';
			case Linux.Input.KEY_9:
				return '9';
			case Linux.Input.KEY_A:
				return 'a';
			case Linux.Input.KEY_B:
				return 'b';
			case Linux.Input.KEY_C:
				return 'c';
			case Linux.Input.KEY_D:
				return 'd';
			case Linux.Input.KEY_E:
				return 'e';
			case Linux.Input.KEY_F:
				return 'f';
			case Linux.Input.KEY_G:
				return 'g';
			case Linux.Input.KEY_H:
				return 'h';
			case Linux.Input.KEY_I:
				return 'i';
			case Linux.Input.KEY_J:
				return 'j';
			case Linux.Input.KEY_K:
				return 'k';
			case Linux.Input.KEY_L:
				return 'l';
			case Linux.Input.KEY_M:
				return 'm';
			case Linux.Input.KEY_N:
				return 'n';
			case Linux.Input.KEY_O:
				return 'o';
			case Linux.Input.KEY_P:
				return 'p';
			case Linux.Input.KEY_Q:
				return 'q';
			case Linux.Input.KEY_R:
				return 'r';
			case Linux.Input.KEY_S:
				return 's';
			case Linux.Input.KEY_T:
				return 't';
			case Linux.Input.KEY_U:
				return 'u';
			case Linux.Input.KEY_V:
				return 'v';
			case Linux.Input.KEY_W:
				return 'w';
			case Linux.Input.KEY_X:
				return 'x';
			case Linux.Input.KEY_Y:
				return 'y';
			case Linux.Input.KEY_Z:
				return 'z';
			case Linux.Input.KEY_SPACE:
				return ' ';
			case Linux.Input.KEY_DOT:
				return '.';
			case Linux.Input.KEY_MINUS:
				return '-';
			case Linux.Input.KEY_SLASH:
				return '/';
			case Linux.Input.KEY_ENTER:
				return '\n';
			default:
				return '\0';
		}
	}

	private char linux_event_lookup_shift(uint16 code) {
		int c = code;

		switch(c) {
			case Linux.Input.KEY_EQUAL:
				return '+';
			case Linux.Input.KEY_4:
				return '$';
			case Linux.Input.KEY_5:
				return '%';
			case Linux.Input.KEY_A:
				return 'A';
			case Linux.Input.KEY_B:
				return 'B';
			case Linux.Input.KEY_C:
				return 'C';
			case Linux.Input.KEY_D:
				return 'D';
			case Linux.Input.KEY_E:
				return 'E';
			case Linux.Input.KEY_F:
				return 'F';
			case Linux.Input.KEY_G:
				return 'G';
			case Linux.Input.KEY_H:
				return 'H';
			case Linux.Input.KEY_I:
				return 'I';
			case Linux.Input.KEY_J:
				return 'J';
			case Linux.Input.KEY_K:
				return 'K';
			case Linux.Input.KEY_L:
				return 'L';
			case Linux.Input.KEY_M:
				return 'M';
			case Linux.Input.KEY_N:
				return 'N';
			case Linux.Input.KEY_O:
				return 'O';
			case Linux.Input.KEY_P:
				return 'P';
			case Linux.Input.KEY_Q:
				return 'Q';
			case Linux.Input.KEY_R:
				return 'R';
			case Linux.Input.KEY_S:
				return 'S';
			case Linux.Input.KEY_T:
				return 'T';
			case Linux.Input.KEY_U:
				return 'U';
			case Linux.Input.KEY_V:
				return 'V';
			case Linux.Input.KEY_W:
				return 'W';
			case Linux.Input.KEY_X:
				return 'X';
			case Linux.Input.KEY_Y:
				return 'Y';
			case Linux.Input.KEY_Z:
				return 'Z';
			case Linux.Input.KEY_SPACE:
				return ' ';
			case Linux.Input.KEY_ENTER:
				return '\n';
			default:
				return '\0';

		}
	}

	private bool device_read(IOChannel source, IOCondition cond) {
		Linux.Input.Event ev = {};
		char key = '\0';

		if((cond & IOCondition.HUP) == IOCondition.HUP){
			stdout.printf("Lost device try reconnect");
			this.connect();
		}
		do {
			int fd = source.unix_get_fd();
			ssize_t s = Posix.read(fd, &ev, sizeof(Linux.Input.Event));

			/* short read */
			if (s != sizeof(Linux.Input.Event)) {
				if(s > 0)
					stdout.printf("short read!\n");
				return true;
			}

			/* only handle key events */
			if (ev.type != Linux.Input.EV_KEY)
				continue;

			if (ev.code == Linux.Input.KEY_LEFTSHIFT) {
				shift = (ev.value == 1);
				continue;
			}

			/* ignore key-release */
			if (ev.value != 1)
				continue;

			/* key event to ascii */
			key = shift ? linux_event_lookup_shift(ev.code) : linux_event_lookup(ev.code);

			/* add buffer */
			if (key != '\n')
				buffer += "%c".printf(key);
		} while(key != '\n');

		stdout.printf("barcode: %s\n", buffer);

		if(buffer.has_prefix("USER ") || buffer.has_prefix("STOCK") || buffer.has_prefix("AMOUNT ")) {
			if(!check_code39_checksum(buffer))
				received_barcode("SCANNER RETURNED INCORRECT DATA");
			else  {/* remove checksum */
				buffer = buffer[0:-1];
				received_barcode(buffer);
			}
		}
		else
			received_barcode(buffer);

		buffer = "";
		return true;
	}

	private bool check_code39_checksum(string data) {
		int result = 0;

		for(int i = 0; i<data.length-1; i++) {
			if(data[i] >= '0' && data[i] <= '9')
				result += data[i] - '0';
			else if(data[i] >= 'A' && data[i] <= 'Z')
				result += data[i] - 'A' + 10;
			else
				switch(data[i]) {
					case '-':
						result += 36; break;
					case '.':
						result += 37; break;
					case ' ':
						result += 38; break;
					case '$':
						result += 39; break;
					case '/':
						result += 40; break;
					case '+':
						result += 41; break;
					case '%':
						result += 42; break;
					default:
						/* invalid character */
						return false;
				}

			result %= 43;
		}

		if(result < 10)
			result = result + '0';
		else if(result < 36)
			result = result - 10 + 'A';
		else
			switch(result) {
				case 36: result = '-'; break;
				case 37: result = '.'; break;
				case 38: result = ' '; break;
				case 39: result = '$'; break;
				case 40: result = '/'; break;
				case 41: result = '+'; break;
				case 42: result = '%'; break;
			}

		return (data[data.length-1] == result);
	}

	/**
	 * @param duration duration of the blink in 0.1 seconds
	 */
	public void blink(uint duration) {
		/* not supported */
	}
}
