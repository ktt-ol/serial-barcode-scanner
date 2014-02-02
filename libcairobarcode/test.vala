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

public static int main(string[] args) {
	double width  = 190.0;
	double height =  40.0;

	var surface = new Cairo.SvgSurface("test.svg", width, height);
	var ctx = new Cairo.Context(surface);
	var ean = new EAN(ctx, width, height);
	var code39 = new Code39(ctx, width, height);

	if(args.length < 3) {
		stderr.printf("Usage: %s <ean|code39> <message>\n", args[0]);
		return 1;
	}

	try {
		switch(args[1]) {
			case "ean":
				ean.draw(args[2]);
				break;
			case "code39":
				code39.draw(args[2]);
				break;
			default:
				stderr.printf("Usage: %s <ean|code39> <message>\n", args[0]);
				return 1;
		}
	} catch (BarcodeError e) {
		stderr.printf(e.message + "\n");
	}

	/* cleanup */
	code39 = null;
	ean = null;
	ctx = null;
	surface = null;

	return 0;
 }
