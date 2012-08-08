/* Copyright 2012, Sebastian Reichel <sre@ring0.de>
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

public class Device {
	private Posix.termios newtio;
	private Posix.termios restoretio;
	public int fd=-1;
	private IOChannel io_read;
	public int byterate;
	private File lockfile;

	public signal void received_barcode(string barcode);

	public Device(string device, int rate, int bits, int stopbits) {
		Posix.speed_t baudrate = Posix.B9600;

		/* check lock file */
		lockfile = File.new_for_path("/var/lock/LCK.." + device.replace("/dev/", ""));
		if(lockfile.query_exists()) {
			error("device is locked!\n");
			/* TODO: check pid */
		}

		try {
			var pid = "%d\n".printf(Posix.getpid());
			lockfile.replace_contents(pid.data, null, false, FileCreateFlags.NONE, null);

			fd = Posix.open(device, Posix.O_RDWR /*| Posix.O_NONBLOCK*/);

			if(fd < 0) {
				fd = -1;
				lockfile.delete();
				error("Could not open device!\n");
			}

		} catch(Error e) {
			error("Could not create lock file: %s!\n", e.message);
		}


		Posix.tcflush(fd, Posix.TCIOFLUSH);

		Posix.tcgetattr(fd, out restoretio);

		/* apply settings */
		switch(rate) {
			case 300:
				baudrate = Posix.B300;
				break;
			case 600:
				baudrate = Posix.B600;
				break;
			case 1200:
				baudrate = Posix.B1200;
				break;
			case 2400:
				baudrate = Posix.B2400;
				break;
			case 4800:
				baudrate = Posix.B4800;
				break;
			case 9600:
				baudrate = Posix.B9600;
				break;
			case 19200:
				baudrate = Posix.B19200;
				break;
			case 38400:
				baudrate = Posix.B38400;
				break;
			case 57600:
				baudrate = Posix.B57600;
				break;
			case 115200:
				baudrate = Posix.B115200;
				break;
			case 230400:
				baudrate = Posix.B230400;
				break;
			default:
				/* not supported */
				rate = 9600;
				break;
		}

		Posix.cfsetospeed(ref newtio, baudrate);
		Posix.cfsetispeed(ref newtio, baudrate);

		switch(bits) {
			case 5:
				newtio.c_cflag = (newtio.c_cflag & ~Posix.CSIZE) | Posix.CS5;
				break;
			case 6:
				newtio.c_cflag = (newtio.c_cflag & ~Posix.CSIZE) | Posix.CS6;
				break;
			case 7:
				newtio.c_cflag = (newtio.c_cflag & ~Posix.CSIZE) | Posix.CS7;
				break;
			case 8:
			default:
				newtio.c_cflag = (newtio.c_cflag & ~Posix.CSIZE) | Posix.CS8;
				break;
		}

		newtio.c_cflag |= Posix.CLOCAL | Posix.CREAD;

		newtio.c_cflag &= ~(Posix.PARENB | Posix.PARODD);

		/* TODO: parity */

		newtio.c_cflag &= ~Linux.Termios.CRTSCTS;

		if(stopbits == 2)
			newtio.c_cflag |= Posix.CSTOPB;
		else
			newtio.c_cflag &= ~Posix.CSTOPB;

		newtio.c_iflag = Posix.IGNBRK;

		newtio.c_lflag = 0;
		newtio.c_oflag = 0;

		newtio.c_cc[Posix.VTIME]=1;
		newtio.c_cc[Posix.VMIN]=1;

		newtio.c_lflag &= ~(Posix.ECHONL|Posix.NOFLSH);

		int mcs=0;
		Posix.ioctl(fd, Linux.Termios.TIOCMGET, out mcs);
		mcs |= Linux.Termios.TIOCM_RTS;
		Posix.ioctl(fd, Linux.Termios.TIOCMSET, out mcs);

		Posix.tcsetattr(fd, Posix.TCSANOW, newtio);

		this.byterate = rate/bits;

		try {
			io_read = new IOChannel.unix_new(fd);
			io_read.set_line_term("\r\n", 2);
			if(io_read.set_encoding(null) != IOStatus.NORMAL)
				error("Failed to set encoding");
			if(!(io_read.add_watch(IOCondition.IN | IOCondition.HUP, device_read) != 0)) {
				error("Could not bind IOChannel");
			}
		} catch(IOChannelError e) {
			error("IOChannel: %s", e.message);
		}
	}

	~Device() {
		/* restore old tty config */
		Posix.tcsetattr(fd, Posix.TCSANOW, restoretio);

		/* close file */
		Posix.close(fd);

		/* remove lock */
		lockfile.delete();
	}

	private bool device_read(IOChannel gio, IOCondition cond) {
		IOStatus ret;
		string msg;
		size_t len, term_char;

		if((cond & IOCondition.HUP) == IOCondition.HUP)
			error("Lost device");

		try {
			ret = gio.read_line(out msg, out len, out term_char);
			msg = msg[0:(long)term_char];

			if(msg.has_prefix("USER ") || msg.has_prefix("STOCK") || msg.has_prefix("AMOUNT ")) {
				if(!check_code39_checksum(msg))
					received_barcode("SCANNER RETURNED INCORRECT DATA");
				else  {/* remove checksum */
					msg = msg[0:-1];
					received_barcode(msg);
				}
			}
			else
				received_barcode(msg);
		}
		catch(IOChannelError e) {
			stderr.printf("IOChannel Error: %s", e.message);
			return false;
		}
		catch(ConvertError e) {
			stderr.printf("Convert Error: %s", e.message);
			return false;
		}
		return true;
	}

	private ssize_t write(void *buf, size_t count) {
		ssize_t size = Posix.write(fd, buf, count);
		return size;
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
		uint size = byterate/10 * duration;
		var msg = new uint8[size];
		Posix.memset(msg, 0xFF, msg.length);
		this.write(msg, msg.length);
}
}
