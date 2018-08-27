/* Copyright 2013, Sebastian Reichel <sre@ring0.de>
 * Copyright 2017-2018, Johannes Rudolph <johannes.rudolph@gmx.com>
 * Copyright 2018, Malte Modler <malte@malte-modler.de>
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
