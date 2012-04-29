public static int main(string[] args) {
	if(args.length < 2) {
		stderr.printf("%s <device>\n", args[0]);
		return 1;
	}

	var s = new Serial(args[1], 9600, 8, 1);

	char[] detected = {};

	while(true) {
		uint8 buf[64];
		int size = (int) Posix.read(s.fd, buf, 64);

		for(int i = 0; i < size; i++)
			if(buf[i] != '\r' && buf[i] != '\n') {
				detected += (char) buf[i];
			} else {
				if(detected.length > 0) {
					detected += '\0';
					interpret((string) detected);
				}
				detected = {};
			}
	}
}

public static void interpret(string data) {
	if(data.has_prefix("USER ")) {
		string str_id = data.substring(5);
		uint64 id = uint64.parse(str_id);
		stdout.printf("login: %llu\n", id);
	} else {
		stdout.printf(" product: %s\n", data);
	}
}
