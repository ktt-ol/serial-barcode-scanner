public class Device {
	private Posix.termios newtio;
	private Posix.termios restoretio;
	public int fd=-1;
	public int byterate;

	public Device(string device, int rate, int bits, int stopbits) {
		Posix.speed_t baudrate = Posix.B9600;

		fd = Posix.open(device, Posix.O_RDWR /*| Posix.O_NONBLOCK*/);

		if(fd < 0) {
			fd = -1;
			stderr.printf("Could not open device!\n");
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
	}

	private ssize_t read(void *buf, size_t count) {
		return Posix.read(fd, buf, count);
	}

	private ssize_t write(void *buf, size_t count) {
		ssize_t size = Posix.write(fd, buf, count);
		return size;
	}

	public string receive() {
		char[] detected = {};
		char buf[64];

		while(true) {
			int size = (int) this.read(buf, 64);

			if(size <= 0)
				error("serial device lost.\n");

			for(int i = 0; i < size; i++) {
				if(buf[i] != '\r' && buf[i] != '\n') {
					detected += (char) buf[i];
				} else {
					if(detected.length > 0) {
						detected += '\0';

						if(((string) detected).has_prefix("USER ")) {
							if(!check_code39_checksum((string) detected))
								return "SCANNER RETURNED INCORRECT DATA";
							else /* remove checksum */
								detected[detected.length-2] = '\0';
						}

						if(((string) detected).has_prefix("AMOUNT ")) {
							if(!check_code39_checksum((string) detected))
								return "SCANNER RETURNED INCORRECT DATA";
							else /* remove checksum */
								detected[detected.length-2] = '\0';
						}

						return ((string) detected);
					}
				}
			}
		}
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
