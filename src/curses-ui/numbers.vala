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

	string binarylocation;

	public AsciiNumbers(string binarylocation){
		this.binarylocation = binarylocation;
	}

	private string[] readNumber(string fileName){
		var file = File.new_for_path(binarylocation + "/numbers/" + fileName);
		var dis = new DataInputStream(file.read());
		string line;
		string[] number;
		while((line = dis.read_line(null)) != null){
			number += line;
		}
		return number;
	}


	public string[] get(char c) {
		switch(c) {
			case '0':
				return readNumber("0.txt");
			case '1':
				return readNumber("1.txt");
			case '2':
				return readNumber("2.txt");
			case '3':
				return readNumber("3.txt");
			case '4':
				return readNumber("4.txt");
			case '5':
				return readNumber("5.txt");
			case '6':
				return readNumber("6.txt");
			case '7':
				return readNumber("7.txt");
			case '8':
				return readNumber("8.txt");
			case '9':
				return readNumber("9.txt");
			case ':':
				return readNumber("colon.txt");
			default:
				return {};
		}
	}

}
