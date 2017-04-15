/* Copyright 2013, Sebastian Reichel <sre@ring0.de>
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
	PDFInvoice invoice = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.InvoicePDF", "/io/mainframe/shopsystem/invoicepdf");

	InvoiceRecipient r = {
		"Max",
		"Mustermann",
		"Foobar Straße 42",
		"31337",
		"Entenhausen",
		"masculinum"
	};

	Product mate = {
		4029764001807,
		"Club Mate"
	};

	InvoiceEntry e1 = {
		1364271520,
		mate,
		2342
	};

	/* set invoice data */
	invoice.invoice_id = "TEST";
	invoice.invoice_date = 1364271524;
	invoice.invoice_recipient = r;
	invoice.invoice_entries = {e1};

	/* generate pdf */
	var pdfdata = invoice.generate();

	/* write pdf into file */
	FileUtils.set_contents("test.pdf", (string) pdfdata, pdfdata.length);

	return 0;
}
