/* Copyright 2014, Sebastian Reichel <sre@ring0.de>
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

public class Code39 {
	Cairo.Context ctx;
	double width;
	double height;

	/* 0 = wide black, 1 = narrow black, 2 = wide white, 3 = narrow white */
	const uint32[] lookup_table = {
		0x1d8cd, 0xd9dc, 0x1c9dc, 0xc9dd, 0x1d8dc, 0xd8dd, 0x1c8dd, 0x1d9cc,
		0xd9cd, 0x1c9cd, 0xdd9c, 0x1cd9c, 0xcd9d, 0x1dc9c, 0xdc9d, 0x1cc9d,
		0x1dd8c, 0xdd8d, 0x1cd8d, 0x1dc8d, 0xddd8, 0x1cdd8, 0xcdd9, 0x1dcd8,
		0xdcd9, 0x1ccd9, 0x1ddc8, 0xddc9, 0x1cdc9, 0x1dcc9, 0x9ddc, 0x18ddc,
		0x8ddd, 0x19cdc, 0x9cdd, 0x18cdd, 0x19dcc, 0x9dcd, 0x18dcd, 0x1999d,
		0x199d9, 0x19d99, 0x1d999, 0x19ccd
	};

	public Code39(Cairo.Context ctx, double width, double height) {
		this.ctx = ctx;
		this.width = width;
		this.height = height;
	}

	private int lookup_index(char c) throws BarcodeError {
		if(c >= '0' && c <= '9')
			return c - '0';
		if(c >= 'A' && c <= 'Z')
			return c - 'A' + 10;
		switch (c) {
			case '-':
				return 36;
			case '.':
				return 37;
			case ' ':
				return 38;
			case '$':
				return 39;
			case '/':
				return 40;
			case '+':
				return 41;
			case '%':
				return 42;
			case '*':
				return 43;
			default:
				throw new BarcodeError.UNEXPECTED_CHARACTER("Character '%c' is not allowed in Code 39".printf(c));
		}
	}

	private uint32 lookup(char c) throws BarcodeError {
		return lookup_table[lookup_index(c)];
	}

	private void draw_line(bool black, double linewidth) {
		double x,y;

		if(black)
			ctx.set_source_rgb(0, 0, 0);
		else
			ctx.set_source_rgb(1, 1, 1);

		ctx.rel_line_to(0,height);
		ctx.rel_move_to(linewidth,-height);

		ctx.get_current_point(out x, out y);
		ctx.stroke();
		ctx.move_to(x,y);
	}

	public void draw(string code) throws BarcodeError {
		string mycode = code;

		if(!mycode.has_prefix("*"))
			mycode = "*" + mycode;
		if(!mycode.has_suffix("*"))
			mycode = mycode + "*";

		double linewidth = width / (mycode.length * 13.0);

		ctx.save();
		ctx.set_line_width(linewidth);
		ctx.move_to(0,0);
		ctx.rel_move_to(0.5*linewidth,0);

		for(int i=0; i<mycode.length; i++) {
			var format = lookup(mycode[i]);

			for(int j=8; j>=0; j--) {
				var line = (format >> (2*j)) & 0x3;

				switch(line) {
					case 0:
						draw_line(true, linewidth);
						draw_line(true, linewidth);
						break;
					case 1:
						draw_line(true, linewidth);
						break;
					case 2:
						draw_line(false, linewidth);
						draw_line(false, linewidth);
						break;
					default:
						draw_line(false, linewidth);
						break;
				}
			}

			draw_line(false, linewidth);
		}

		ctx.restore();
	}
}
