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

public const int day_in_seconds = 60*60*24;

public struct Timespan {
	int64 from;
	int64 to;
}

public struct InvoiceData {
	string pdffilename;
	uint8[] pdfdata;
	string plain;
	string html;
}

public class InvoiceImplementation {
	Mailer mailer;
	Database db;
	PDFInvoice pdf;
	string datadir;
	string jvereinmitgliedsnummern;

	public InvoiceImplementation() throws IOError, KeyFileError {
		mailer = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Mail", "/io/mainframe/shopsystem/mailer");
		db = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Database", "/io/mainframe/shopsystem/database");
		pdf = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.InvoicePDF", "/io/mainframe/shopsystem/invoicepdf");
		Config cfg = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
		datadir = cfg.get_string("INVOICE", "datadir");
		jvereinmitgliedsnummern = cfg.get_string("JVEREIN", "mitgliedsnummern");
	}

	public void send_invoice(bool temporary, int64 timestamp, int user) throws IOError, InvoicePDFError, DatabaseError {
		int64 prevtimestamp = timestamp - day_in_seconds;

		if(!temporary)
			prevtimestamp = new DateTime.from_unix_local(timestamp).add_months(-1).to_unix();

		Timespan ts = get_timespan(temporary, prevtimestamp);
		Timespan tst = get_timespan(false, prevtimestamp);
		int number = 0;


		var start = new DateTime.from_unix_local(ts.from);
		var stop  = new DateTime.from_unix_local(ts.to);
		var startstring = start.format("%d.%m.%Y %H:%M:%S");
		var stopstring  = stop.format("%d.%m.%Y %H:%M:%S");

		/* title */
		string mailtitle = temporary ? "Getränkezwischenstand" : "Getränkerechnung";
		mailtitle += @" $startstring - $stopstring";

		stdout.printf(mailtitle + "\n\n");

		var users = db.get_users_with_sales(ts.from, ts.to);

		string treasurer_path  = mailer.create_mail();
		Mail treasurer_mail    = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Mail", treasurer_path);
		treasurer_mail.from    = {"KtT Shopsystem", "shop@kreativitaet-trifft-technik.de"};
		treasurer_mail.subject = mailtitle;
		treasurer_mail.add_recipient({"Schatzmeister", "shop-einzug@kreativitaet-trifft-technik.de"}, RecipientType.TO);
		var csvinvoicedata     = "";

		foreach(var userid in users) {
			number++;
			string invoiceid = "SH" + start.format("%Y%m") + "5" + "%03d".printf(number);
			var userdata = db.get_user_info(userid);
			var total_sum = db.get_user_invoice_sum(userid, tst.from, tst.to);

			if(userid == user) {
				var invoicedata = generate_invoice(temporary, timestamp, userid, invoiceid);
				string mail_path = mailer.create_mail();
				Mail mail = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Mail", mail_path);
				mail.from = {"KtT Shopsystem", "shop@kreativitaet-trifft-technik.de"};
				mail.subject = mailtitle;
				mail.add_recipient({@"$(userdata.firstname) $(userdata.lastname)", userdata.email}, RecipientType.TO);

				if(!temporary) {
					mail.add_attachment(invoicedata.pdffilename, "application/pdf", invoicedata.pdfdata);
					treasurer_mail.add_attachment(invoicedata.pdffilename, "application/pdf", invoicedata.pdfdata);
				}

				mail.set_main_part(invoicedata.plain, MessageType.PLAIN);
				mail.set_main_part(invoicedata.html, MessageType.HTML);

				mailer.send_mail(mail_path);
			}

			if(!temporary) {
				csvinvoicedata += @"$(userdata.id),$(userdata.lastname),$(userdata.firstname),$invoiceid,$total_sum\n";
			}
		}

		if(!temporary) {
			treasurer_mail.set_main_part(get_treasurer_text(), MessageType.PLAIN);
			treasurer_mail.add_attachment("invoice.csv", "text/csv; charset=utf-8", csvinvoicedata.data);
			mailer.send_mail(treasurer_path);
		}
	}

	public void send_invoices(bool temporary, int64 timestamp) throws IOError, InvoicePDFError, DatabaseError {
		int64 prevtimestamp = timestamp - day_in_seconds;
		string faelligkeitsdatumstring = "";

		if(!temporary){
			prevtimestamp = new DateTime.from_unix_local(timestamp).add_months(-1).to_unix();
			int64 faelligkeitsdatum = new DateTime.from_unix_local(timestamp).add_days(10).to_unix();
			faelligkeitsdatumstring = faelligkeitsdatum.format("%d.%m.%Y");
		}

		Timespan ts = get_timespan(temporary, prevtimestamp);
		Timespan tst = get_timespan(false, prevtimestamp);
		int number = 0;


		var start = new DateTime.from_unix_local(ts.from);
		var stop  = new DateTime.from_unix_local(ts.to);
		var startstring = start.format("%d.%m.%Y %H:%M:%S");
		var stopstring  = stop.format("%d.%m.%Y %H:%M:%S");

		/* title */
		string mailtitle = temporary ? "Getränkezwischenstand" : "Getränkerechnung";
		mailtitle += @" $startstring - $stopstring";

		stdout.printf(mailtitle + "\n\n");

		var users = db.get_users_with_sales(ts.from, ts.to);

		string treasurer_path  = mailer.create_mail();
		Mail treasurer_mail    = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Mail", treasurer_path);
		treasurer_mail.from    = {"KtT Shopsystem", "shop@kreativitaet-trifft-technik.de"};
		treasurer_mail.subject = mailtitle;
		treasurer_mail.add_recipient({"Schatzmeister", "shop-einzug@kreativitaet-trifft-technik.de"}, RecipientType.TO);
		var csvinvoicedata     = "";
		var csvjvereininvoicedata = "";
		if(jvereinmitgliedsnummern == "extern"){
			csvjvereininvoicedata = "Ext_Mitglieds_Nr;Betrag;Buchungstext;Fälligkeit;Intervall;Endedatum";
		}
		else {
			csvjvereininvoicedata = "Mitglieds_Nr;Betrag;Buchungstext;Fälligkeit;Intervall;Endedatum";
		}

		foreach(var userid in users) {
			number++;
			string invoiceid = "SH" + start.format("%Y%m") + "5" + "%03d".printf(number);
			var invoicedata = generate_invoice(temporary, timestamp, userid, invoiceid);
			var userdata = db.get_user_info(userid);
			var total_sum = db.get_user_invoice_sum(userid, tst.from, tst.to);

			string mail_path = mailer.create_mail();
			Mail mail = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Mail", mail_path);
			mail.from = {"KtT Shopsystem", "shop@kreativitaet-trifft-technik.de"};
			mail.subject = mailtitle;
			mail.add_recipient({@"$(userdata.firstname) $(userdata.lastname)", userdata.email}, RecipientType.TO);

			if(!temporary)
				mail.add_attachment(invoicedata.pdffilename, "application/pdf", invoicedata.pdfdata);

			mail.set_main_part(invoicedata.plain, MessageType.PLAIN);

			mail.set_main_part(invoicedata.html, MessageType.HTML);

			mailer.send_mail(mail_path);

			if(!temporary) {
				treasurer_mail.add_attachment(invoicedata.pdffilename, "application/pdf", invoicedata.pdfdata);
				csvinvoicedata += @"$(userdata.id),$(userdata.lastname),$(userdata.firstname),$invoiceid,$total_sum\n";
				csvjvereininvoicedata += @"$(userdata.id);$total_sum;Shopsystem Rechnung Nummer $invoiceid;$faelligkeitsdatumstring;0;$faelligkeitsdatumstring\n";
			}
		}

		if(!temporary) {
			treasurer_mail.set_main_part(get_treasurer_text(), MessageType.PLAIN);
			treasurer_mail.add_attachment("invoice.csv", "text/csv; charset=utf-8", csvinvoicedata.data);
			treasurer_mail.add_attachment("jvereininvoice.csv", "text/csv; charset=utf-8", csvjvereininvoicedata.data);
			mailer.send_mail(treasurer_path);
		}
	}

	public InvoiceData generate_invoice(bool temporary, int64 timestamp, int userid, string invoiceid) throws IOError, InvoicePDFError, DatabaseError {
			int64 prevtimestamp = timestamp - day_in_seconds;
			if(!temporary)
				prevtimestamp = new DateTime.from_unix_local(timestamp).add_months(-1).to_unix();

			var userdata = db.get_user_info(userid);

			InvoiceData result = InvoiceData();

			stdout.printf("%d (%s %s)...\n", userdata.id, userdata.firstname, userdata.lastname);

			Timespan ts = get_timespan(temporary, prevtimestamp);
			Timespan tst = get_timespan(false, prevtimestamp);

			var invoiceentries = db.get_invoice(userid, ts.from, ts.to);
			var total_sum = db.get_user_invoice_sum(userid, tst.from, tst.to);

			/* invoice id */
			result.pdffilename = invoiceid + @"_$(userdata.firstname)_$(userdata.lastname).pdf";

			/* pdf generation */
			if(!temporary) {
				pdf.invoice_id = invoiceid;
				pdf.invoice_date = timestamp;
				pdf.invoice_recipient = {
					userdata.firstname,
					userdata.lastname,
					userdata.street,
					userdata.postcode,
					userdata.city,
					userdata.gender
				};
				pdf.invoice_entries = invoiceentries;
				result.pdfdata = pdf.generate();
				pdf.clear();
			}

			result.plain = generate_invoice_message(MessageType.PLAIN, temporary, get_address(userdata.gender), userdata.lastname, invoiceentries, total_sum);
			result.html = generate_invoice_message(MessageType.HTML, temporary, get_address(userdata.gender), userdata.lastname, invoiceentries, total_sum);

			return result;
	}

	private string get_treasurer_text() throws IOError {
		string text;

		try {
			FileUtils.get_contents(datadir + "/treasurer.mail.txt", out text);
		} catch(GLib.FileError e) {
			throw new IOError.FAILED("Could not open invoice template: %s", e.message);
		}

		return text;
	}

	private Timespan get_timespan(bool temporary, int64 timestamp) throws IOError {
		var time = new DateTime.from_unix_local(timestamp);
		Timespan ts = {};

		if(temporary) {
			var start = new DateTime.local(time.get_year(), time.get_month(), time.get_day_of_month(), 8, 0, 0);
			if(start.compare(time) > 0)
				start.add_days(-1);
			var stop = start.add_days(1).add_seconds(-1);

			ts.from = start.to_unix();
			ts.to = stop.to_unix();
		} else {
			var start = new DateTime.local(time.get_year(), time.get_month(), 1, 0, 0, 0);
			var stop = start.add_months(1).add_seconds(-1);

			ts.from = start.to_unix();
			ts.to = stop.to_unix();
		}

		return ts;
	}

	private string get_address(string gender) {
		switch(gender) {
			case "masculinum":
				return "Sehr geehrter Herr";
			case "femininum":
				return "Sehr geehrte Frau";
			default:
				return "Moin";
		}
	}

	private string generate_invoice_message(MessageType type, bool temporary, string address, string name, InvoiceEntry[] entries, Price total_sum) throws IOError {
		string filename = "";
		string table = "";
		string text;

		if(type == MessageType.HTML && temporary)
			filename = "invoice.temporary.html";
		else if(type == MessageType.HTML)
			filename = "invoice.final.html";
		else if(type == MessageType.PLAIN && temporary)
			filename = "invoice.temporary.txt";
		else if(type == MessageType.PLAIN)
			filename = "invoice.final.txt";

		if(type == MessageType.PLAIN)
			table = generate_invoice_table_text(entries);
		else if(type == MessageType.HTML)
			table = generate_invoice_table_html(entries);

		if(filename == "")
			throw new IOError.FAILED("Unknown MessageType");

		try {
			FileUtils.get_contents(datadir + "/" + filename, out text);
		} catch(GLib.FileError e) {
			throw new IOError.FAILED("Could not open invoice template: %s", e.message);
		}

		text = text.replace("{{{ADDRESS}}}", address);
		text = text.replace("{{{LASTNAME}}}", name);
		text = text.replace("{{{INVOICE_TABLE}}}", table);
		text = text.replace("{{{SUM_MONTH}}}", "%d,%02d".printf(total_sum / 100, total_sum % 100));

		return text;
	}

	private string generate_invoice_table_text(InvoiceEntry[] entries) {
		string result = "";

		/* 7 == "Artikel".char_count() */
		const int article_minsize = 7;

		/* no articles bought */
		if(entries.length == 0)
			return result;

		/* get length of longest name + invoice sum */
		int namelength = 0;
		int total = 0;
		foreach(var entry in entries) {
			if(namelength < entry.product.name.char_count())
				namelength = entry.product.name.char_count();
			total += entry.price;
		}

		/* better safe than sorry */
		if(namelength < article_minsize)
			namelength = article_minsize;

		/* generate table header */
		result += " +------------+----------+-" + string.nfill(namelength, '-') + "-+----------+\n";
		result += " | Datum      | Uhrzeit  | Artikel" + string.nfill(namelength - article_minsize, ' ') + " | Preis    |\n";
		result += " +------------+----------+-" + string.nfill(namelength, '-') + "-+----------+\n";

		/* generate table data */
		string lastdate = "";
		foreach(var entry in entries) {
			var dt = new DateTime.from_unix_local(entry.timestamp);
			string newdate = dt.format("%Y-%m-%d");
			string date = (lastdate == newdate) ? "          " : newdate;
			result += " | %s | %s | %s%s | %3d,%02d € |\n".printf(date, dt.format("%H:%M:%S"), entry.product.name, string.nfill(namelength-entry.product.name.char_count(), ' '), entry.price / 100, entry.price % 100);
			lastdate = newdate;
		}

		/* generate table footer */
		result += " +------------+----------+-" + string.nfill(namelength, '-') + "-+----------+\n";
		result += " | Summe:                  " + string.nfill(namelength, ' ') + " | %3d,%02d € |\n".printf(total / 100, total % 100);
		result += " +-------------------------" + string.nfill(namelength, '-') + "-+----------+\n";

		return result;
	}

	private string generate_invoice_table_html(InvoiceEntry[] entries) {
		string result = "";

		result += "<table cellpadding=\"5\" style=\"border-collapse:collapse;\">\n";
		result += "\t<tr><th style=\"border: 1px solid black;\">Datum</th><th style=\"border: 1px solid black;\">Zeit</th><th style=\"border: 1px solid black;\">Artikel</th><th style=\"border: 1px solid black;\">Preis</th></tr>\n";

		string lastdate = "";
		int total = 0;
		foreach(var entry in entries) {
			var dt = new DateTime.from_unix_local(entry.timestamp);
			string newdate = dt.format("%Y-%m-%d");
			string time = dt.format("%H:%M:%S");
			string date = (lastdate == newdate) ? "" : newdate;
			total += entry.price;

			result += "\t<tr><td style=\"border: 1px solid black;\">%s</td><td style=\"border: 1px solid black;\">%s</td><td style=\"border: 1px solid black;\">%s</td><td style=\"border: 1px solid black;\" align=\"right\"><tt>%d,%02d €</tt></td></tr>\n".printf(date, time, entry.product.name, entry.price / 100, entry.price % 100);
			lastdate = newdate;
		}

		result += "\t<tr><th style=\"border: 1px solid black;\" colspan=\"3\" align=\"left\">Summe:</th><td style=\"border: 1px solid black;\" align=\"right\"><tt>%d,%02d €</tt></td></tr>\n".printf(total / 100, total % 100);

		result += "</table>\n";

		return result;
	}
}
