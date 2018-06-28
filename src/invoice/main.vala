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

InvoiceImplementation invoice;

public static void help(string name) {
	stderr.printf(_("Usage: %s <temporary> [timestamp]\n"), name);
	stderr.printf(_("Possible values for <temporary>: temporary, final\n"));
}

public static int main(string[] args) {
	Intl.setlocale(LocaleCategory.ALL, "");
	Intl.textdomain("shopsystem");

	bool temporary = false;
	int64 timestamp = new DateTime.now_local().to_unix();

	if(args.length < 2) {
		help(args[0]);
		return 1;
	}

	if(args[1] == "temporary") {
		temporary = true;
	} else if(args[1] == "final") {
		temporary = false;
	} else {
		help(args[0]);
		return 1;
	}

	if(args.length >= 3) {
		timestamp = int64.parse(args[2]);
	}

	try {
		invoice = new InvoiceImplementation();
	} catch(Error e) {
		stderr.printf(_("Error: %s\n"), e.message);
		return 1;
	}

	try {
		invoice.send_invoices(temporary, timestamp);
	} catch(Error e) {
		stderr.printf(_("Error: %s\n"), e.message);
		return 1;
	}

	return 0;
}
