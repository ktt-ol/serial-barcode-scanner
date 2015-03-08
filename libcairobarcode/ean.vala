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

public class EAN {
	Cairo.Context ctx;
	double width;
	double height;
	const double marker_length_diff = 10.0;
	double basex;
	double basey;

	static const uint8[] C = { 0x00, 0x0b, 0x0d, 0x0e, 0x13, 0x19, 0x1c, 0x15, 0x16, 0x1a };

	static uint8[,] lookup = {
		{ 0x0d, 0x19, 0x13, 0x3d, 0x23, 0x31, 0x2f, 0x3b, 0x37, 0x0b }, /* L */
		{ 0x27, 0x33, 0x1b, 0x21, 0x1d, 0x39, 0x05, 0x11, 0x09, 0x17 }, /* G */
		{ 0x72, 0x66, 0x6c, 0x42, 0x5c, 0x4e, 0x50, 0x44, 0x48, 0x74 }  /* R */
	};

	public EAN(Cairo.Context ctx, double width, double height) {
		this.ctx = ctx;
		this.width = width / 95.0;
		this.height = height;
	}

	private void draw_line(bool black) {
		double x,y;

		if(black)
			ctx.set_source_rgb(0, 0, 0);
		else
			ctx.set_source_rgb(1, 1, 1);

		ctx.rel_line_to(0,height);
		ctx.rel_move_to(width,-height);

		ctx.get_current_point(out x, out y);
		ctx.stroke();
		ctx.move_to(x,y);
	}

	private void draw_startstop() {
		draw_line(true);
		draw_line(false);
		draw_line(true);
	}

	private void draw_middle() {
		draw_line(false);
		draw_line(true);
		draw_line(false);
		draw_line(true);
		draw_line(false);
	}

	private void draw_number_text(uint8 number) {
		double x, y;
		ctx.get_current_point(out x, out y);
		ctx.set_source_rgb(0, 0, 0);

		ctx.stroke();
		ctx.move_to(x,y);
	}

	private void draw_number(uint8 number, uint8 type) {
		draw_number_text(number);

		for(int i=6; i>=0; i--) {
			var bit = (lookup[type,number] >> i) & 1;
			draw_line(bit == 1);
		}
	}

	private uint8 get_number(string ean, int pos) {
		return (uint8) int.parse("%c".printf(ean[pos]));
	}

	private void draw13(string ean) {
		/* need some extra space for the checksum */
		width = (width * 95.0) / 102.0;

		uint8 LG = C[get_number(ean, 0)];

		draw_startstop();
		for(int i=1, x = 5; i<7; i++, x--) {
			uint8 type = (uint8) (LG >> x) & 1;
			draw_number(get_number(ean,i), type);
		}
		draw_middle();
		for(int i=7; i<13; i++)
			draw_number(get_number(ean,i), 2);
		draw_startstop();

		/* remove extra space for the checksum */
		width = (width * 102.0) / 95.0;

	}

	private void draw8(string ean) {
		draw_startstop();
		for(int i=0; i<4; i++)
			draw_number(get_number(ean,i), 0);
		draw_middle();
		for(int i=4; i<8; i++)
			draw_number(get_number(ean,i), 2);
		draw_startstop();
	}

	public void draw(string ean) throws BarcodeError {
		ctx.save();
		ctx.set_line_width(width);
		ctx.get_current_point(out basex, out basey);
		ctx.rel_move_to(0.5*width,0);

		for(int i=0; i<ean.length; i++) {
			if(ean[i] < '0' || ean[i] > '9') {
				throw new BarcodeError.UNEXPECTED_CHARACTER("Character '%c' is not allowed in EAN".printf(ean[i]));
			}
		}

		if(ean.length == 13)
			draw13(ean);
		else if(ean.length == 8)
			draw8(ean);
		else
			throw new BarcodeError.UNEXPECTED_LENGTH("length of EAN is incorrect (must be 8 or 13)");

		ctx.restore();
	}
}
