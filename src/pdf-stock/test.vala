/* Copyright 2015, Sebastian Reichel <sre@ring0.de>
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

public static int main(string args[]) {
	try {
		PDFStock stock = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.StockPDF", "/io/mainframe/shopsystem/stockpdf");
		var pdfdata = stock.generate();
		FileUtils.set_contents("test.pdf", (string) pdfdata, pdfdata.length);
	} catch(IOError e) {
		error("IOError: %s", e.message);
	} catch(FileError e) {
		error("FileError: %s", e.message);
	}

	return 0;
}
