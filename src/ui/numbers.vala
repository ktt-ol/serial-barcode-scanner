public class AsciiNumbers {

	public string[] zero = {
		" _ ",
		"/ \\",
		"\\_/"
	};

	public string[] one = {
		"   ",
		" /|",
		"  |"
	};

	public string[] two = {
		"__ ",
		" _)",
		"(__"
	};

	public string[] three = {
		"__ ",
		" _)",
		"__)"
	};

	public string[] four = {
		"   ",
		"|_|",
		"  |"
	};

	public string[] five = {
		" __",
		"|_ ",
		"__)"
	};

	public string[] six = {
		" _ ",
		"/_ ",
		"\\_)"
	};

	public string[] seven = {
		"___",
		"  /",
		" / "
	};

	public string[] eight = {
		" _ ",
		"(_)",
		"(_)"
	};

	public string[] nine = {
		" _ ",
		"(_\\",
		" _/"
	};

	public string[] colon = {
		"   ",
		" o ",
		" o "
	};

	public string[] get(char c) {
		switch(c) {
			case '0':
				return zero;
			case '1':
				return one;
			case '2':
				return two;
			case '3':
				return three;
			case '4':
				return four;
			case '5':
				return five;
			case '6':
				return six;
			case '7':
				return seven;
			case '8':
				return eight;
			case '9':
				return nine;
			case ':':
				return colon;
			default:
				return {};
		}
	}

}
