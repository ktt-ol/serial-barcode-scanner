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

[DBus (name = "io.mainframe.shopsystem.InvoicePDF")]
public class InvoicePDF {

	Config cfg;

	/* A4 sizes (in points, 72 DPI) */
	private const double width = 595.27559;  /* 210mm */
	private const double height = 841.88976; /* 297mm */

	/* invoice content, which should appear in the PDF */
	public string invoice_id { set; owned get; default = ""; }
	public int64  invoice_date { set; get; default = 0; }
	public InvoiceEntry[] invoice_entries { set; owned get; default = null; }
	public InvoiceRecipient invoice_recipient {
		set;
		owned get;
		default = InvoiceRecipient() {
			firstname = "",
			lastname = "",
			street = "",
			postal_code = "",
			city = "",
			gender = ""
		};
	}

	/* pdf data */
	private uint8[] data;
	private uint useddatalength;

	/* internal helper */
	private DateTime previous_tm;

	private string datadir;

	private const string[] calendermonths = {
		"Januar",
		"Februar",
		"März",
		"April",
		"Mai",
		"Juni",
		"Juli",
		"August",
		"September",
		"Oktober",
		"November",
		"Dezember"
	};

	string longname;
	string umsatzsteuer;
	string umsatzsteuerNoText;
  string dateFormat;
  string dateTimeFormat;
  string timeFormat;

	public InvoicePDF(string datadir) {
		try{
			this.datadir = datadir;
			cfg = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
			longname = cfg.get_string("GENERAL", "longname");
			umsatzsteuer = cfg.get_string("INVOICE", "umsatzsteuer");
			umsatzsteuerNoText = cfg.get_string("INVOICE", "umsatzsteuerNoText");
	    dateFormat = cfg.get_string("DATE-FORMAT", "format");
	    dateTimeFormat = cfg.get_string("DATE-FORMAT", "formatDateTime");
	    timeFormat = cfg.get_string("DATE-FORMAT", "formatTime");
		} catch(Error e){
			error("Error: %s\n", e.message);
		}
	}

	private void render_svg(Cairo.Context ctx, string file) {
		try {
			var svg = new Rsvg.Handle.from_file(file);
			svg.render_cairo(ctx);
		} catch(Error e) {
			error("Could not load SVG: %s\n", e.message);
		}
	}

	private bool svg_file_exists(string file) {
                try {
                        new Rsvg.Handle.from_file(file);
                        return true;
                } catch(Error e) {
                        return false;
                }
        }

	private void draw_footer(Cairo.Context ctx) {
		ctx.save();
		ctx.translate(-20, 818);
		ctx.scale(1.42, 1.42);
		if(svg_file_exists(datadir + "/../myfooter-line.svg")){
               		render_svg(ctx, datadir + "/../myfooter-line.svg");
                }
                else {
                	render_svg(ctx, datadir + "/footer-line.svg");
		}
		ctx.restore();
	}

	private void draw_logo(Cairo.Context ctx) {
		ctx.save();
		ctx.translate(366,25);
		if(svg_file_exists(datadir + "/../mylogo.svg")){
               		render_svg(ctx, datadir + "/../mylogo.svg");
                }
                else {
                	render_svg(ctx, datadir + "/logo.svg");
		}
		ctx.restore();
	}

	private void draw_address(Cairo.Context ctx) {
		ctx.save();
		ctx.set_source_rgb(0, 0, 0);
		ctx.set_line_width(1.0);

		/* upper fold mark (20 mm left, 85 mm width, 51.5 mm top) */
		ctx.move_to(56.69, 146);
		ctx.line_to(297.59, 146);
		ctx.stroke();

		/* actually LMSans8 */
		ctx.set_source_rgb(0, 0, 0);
		ctx.select_font_face("LMSans10", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
		ctx.set_font_size(8.45);

		string adressrow = "";
		try{
			adressrow = cfg.get_string("INVOICE", "adressrow");
		} catch(Error e){
			adressrow = " ";
		}
		ctx.move_to(56.5, 142);
		ctx.show_text(adressrow);

		/* actually LMRoman12 */
		ctx.select_font_face("LMSans10", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
		ctx.set_font_size(12.3);

		ctx.move_to(56.5, 184);
		ctx.show_text(invoice_recipient.firstname + " " + invoice_recipient.lastname);

		ctx.move_to(56.5, 198);
		ctx.show_text(invoice_recipient.street);

		/* actually LMRoman12 */
		ctx.select_font_face("LMSans10", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
		ctx.move_to(56.5, 227);
		ctx.show_text(invoice_recipient.postal_code + " " + invoice_recipient.city);

		ctx.restore();
	}

	private void draw_folding_marks(Cairo.Context ctx) {
		ctx.save();
		ctx.set_source_rgb(0, 0, 0);
		ctx.set_line_width(1.0);

		/* upper fold mark (105 mm) */
		ctx.move_to(10, 297.65);
		ctx.line_to(15, 297.65);
		ctx.stroke();

		/* middle fold mark (148.5 mm)*/
		ctx.move_to(10, 420.912);
		ctx.line_to(23, 420.912);
		ctx.stroke();

		/* lower fold mark (210 mm)*/
		ctx.move_to(10, 595.3);
		ctx.line_to(15, 595.3);
		ctx.stroke();

		ctx.restore();
	}

	private void draw_date(Cairo.Context ctx) {
		ctx.save();
		ctx.move_to(56.5, 280.0);
		ctx.set_source_rgb(0, 0, 0);

		/* get pango layout */
		var layout = Pango.cairo_create_layout(ctx);

		/* setup font */
		var font = new Pango.FontDescription();
		font.set_family("LMSans10");
		font.set_size((int) 9.0 * Pango.SCALE);
		layout.set_font_description(font);

		/* right alignment */
		layout.set_alignment(Pango.Alignment.RIGHT);
		layout.set_wrap(Pango.WrapMode.WORD_CHAR);

		/* set page width */
		layout.set_width((int) 446 * Pango.SCALE);

		/* write invoice date */
		var invdate = new DateTime.from_unix_local(invoice_date);
		var day = "%d".printf(invdate.get_day_of_month());
		var month = invdate.get_month();
		var year = "%d".printf(invdate.get_year());
		var date = day + ". " + calendermonths[month-1] + " " + year;
		layout.set_text(date, date.length);

		/* render text */
		Pango.cairo_update_layout(ctx, layout);
		Pango.cairo_show_layout(ctx, layout);

		ctx.restore();
	}

	private void draw_title(Cairo.Context ctx) {
		ctx.save();

		/* actually LMRoman12 */
		ctx.set_source_rgb(0, 0, 0);
		ctx.select_font_face("LMSans10", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
		ctx.set_font_size(12.9);

		ctx.move_to(56.5, 323);

		ctx.show_text(@"Rechnung Nr. $invoice_id");

		ctx.restore();
	}

	private void draw_footer_text_left(Cairo.Context ctx) {
		ctx.save();
		ctx.move_to(64.0, 742.0);
		ctx.set_source_rgb(0, 0, 0);

		/* get pango layout */
		var layout = Pango.cairo_create_layout(ctx);

		/* setup font */
		var font = new Pango.FontDescription();
		font.set_family("LMRoman8");
		font.set_size((int) 6.0 * Pango.SCALE);
		layout.set_font_description(font);

		/* left alignment */
		layout.set_alignment(Pango.Alignment.LEFT);
		layout.set_wrap(Pango.WrapMode.WORD_CHAR);

		/* set line spacing */
		layout.set_spacing((int) (-2.0 * Pango.SCALE));

		/* set page width */
		layout.set_width((int) 140 * Pango.SCALE);

		string text = "";
		try{
			text = cfg.get_string("INVOICE", "footer1");
		} catch(Error e){
			text = " ";
		}

		/* write invoice date */
		layout.set_markup(text, text.length);

		/* render text */
		Pango.cairo_update_layout(ctx, layout);
		Pango.cairo_show_layout(ctx, layout);

		ctx.restore();
	}

	private void draw_footer_text_middle(Cairo.Context ctx) {
		ctx.save();
		ctx.move_to(216.5, 742.0);
		ctx.set_source_rgb(0, 0, 0);

		/* get pango layout */
		var layout = Pango.cairo_create_layout(ctx);

		/* setup font */
		var font = new Pango.FontDescription();
		font.set_family("LMRoman8");
		font.set_size((int) 6.0 * Pango.SCALE);
		layout.set_font_description(font);

		/* left alignment */
		layout.set_alignment(Pango.Alignment.LEFT);
		layout.set_wrap(Pango.WrapMode.WORD_CHAR);

		/* set line spacing */
		layout.set_spacing((int) (-2.0 * Pango.SCALE));

		/* set page width */
		layout.set_width((int) 190 * Pango.SCALE);

		string text = "";
		try{
			text = cfg.get_string("INVOICE", "footer2");
		} catch(Error e){
			text = " ";
		}

		/* write invoice date */
		layout.set_markup(text, text.length);

		/* render text */
		Pango.cairo_update_layout(ctx, layout);
		Pango.cairo_show_layout(ctx, layout);

		ctx.restore();
	}

	private void draw_footer_text_right(Cairo.Context ctx) {
		ctx.save();
		ctx.move_to(410.0, 742.0);
		ctx.set_source_rgb(0, 0, 0);

		/* get pango layout */
		var layout = Pango.cairo_create_layout(ctx);

		/* setup font */
		var font = new Pango.FontDescription();
		font.set_family("LMRoman8");
		font.set_size((int) 6.0 * Pango.SCALE);
		layout.set_font_description(font);

		/* left alignment */
		layout.set_alignment(Pango.Alignment.LEFT);
		layout.set_wrap(Pango.WrapMode.WORD_CHAR);

		/* set line spacing */
		layout.set_spacing((int) (-2.0 * Pango.SCALE));

		/* set page width */
		layout.set_width((int) 150 * Pango.SCALE);

		string text = "";
		try{
			text = cfg.get_string("INVOICE", "footer3");
		} catch(Error e){
			text = " ";
		}

		/* write invoice date */
		layout.set_markup(text, text.length);

		/* render text */
		Pango.cairo_update_layout(ctx, layout);
		Pango.cairo_show_layout(ctx, layout);

		ctx.restore();
	}

	private Price get_sum() {
		Price sum = 0;
		foreach(var e in invoice_entries) {
			sum += e.price;
		}
		return sum;
	}

	private string get_address() {
		if(invoice_recipient.gender == "masculinum")
			return "Sehr geehrter Herr";
		else if(invoice_recipient.gender == "femininum")
			return "Sehr geehrte Frau";
		else
			return "Moin";
	}

	private void draw_first_page_text(Cairo.Context ctx) {
		ctx.save();
		ctx.move_to(56.5, 352.5);
		ctx.set_source_rgb(0, 0, 0);

		/* get pango layout */
		var layout = Pango.cairo_create_layout(ctx);

		/* setup font */
		var font = new Pango.FontDescription();
		font.set_family("LMRoman12");
		font.set_size((int) 9.0 * Pango.SCALE);
		layout.set_font_description(font);

		/* left alignment */
		layout.set_alignment(Pango.Alignment.LEFT);
		layout.set_wrap(Pango.WrapMode.WORD_CHAR);

		/* set line spacing */
		layout.set_spacing((int) (-2.1 * Pango.SCALE));

		/* set page width */
		layout.set_width((int) 446 * Pango.SCALE);

		string address = get_address();
		Price sum = get_sum();

		/* load text template */
		try {
			var text = "";
			FileUtils.get_contents(datadir + "/pdf-template.txt", out text);
			text = text.replace("{{{ADDRESS}}}", address);
			text = text.replace("{{{LASTNAME}}}", invoice_recipient.lastname);
			text = text.replace("{{{SUM}}}", @"$sum");
			text = text.replace("{{{VEREINSNAME}}}", longname);

			if(umsatzsteuer == "yes") {
				text = text.replace("{{{UMSATZSTEUER}}}", "");
			}
			else {
				text = text.replace("{{{UMSATZSTEUER}}}", umsatzsteuerNoText);
			}

			layout.set_markup(text, text.length);
		} catch(GLib.FileError e) {
			error("File Error: %s\n", e.message);
		}

		/* render text */
		Pango.cairo_update_layout(ctx, layout);
		Pango.cairo_show_layout(ctx, layout);

		ctx.restore();
	}

	private void draw_invoice_table_header(Cairo.Context ctx) {
		ctx.save();

		/* border & font color */
		ctx.set_source_rgb(0, 0, 0);

		/* line width of the border */
		ctx.set_line_width(0.8);

		/* header font */
		ctx.select_font_face("LMSans10", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
		ctx.set_font_size(12);

		/* borders */
		ctx.move_to(58, 50);
		ctx.line_to(530, 50);
		ctx.line_to(530, 65);
		ctx.line_to(58, 65);
		ctx.line_to(58, 50);
		ctx.move_to(120, 50);
		ctx.line_to(120, 65);
		ctx.move_to(180, 50);
		ctx.line_to(180, 65);
		ctx.move_to(480, 50);
		ctx.line_to(480, 65);
		ctx.stroke();

		/* header text */
		ctx.move_to(62, 61.5);
		ctx.show_text("Datum");
		ctx.move_to(124, 61.5);
		ctx.show_text("Uhrzeit");
		ctx.move_to(184, 61.5);
		ctx.show_text("Artikel");
		ctx.move_to(484, 61.5);
		ctx.show_text("Preis");

		ctx.restore();
	}

	private void draw_invoice_table_footer(Cairo.Context ctx, double y) {
		ctx.save();

		/* border & font color */
		ctx.set_source_rgb(0, 0, 0);

		/* line width of the border */
		ctx.set_line_width(0.8);

		/* end of table is just a line */
		ctx.move_to(58, y);
		ctx.line_to(530, y);
		ctx.stroke();

		ctx.restore();
	}

	private bool draw_invoice_table_entry(Cairo.Context ctx, double y, InvoiceEntry e, out double newy) throws InvoicePDFError {
		ctx.save();

		/* border & font color */
		ctx.set_source_rgb(0, 0, 0);

		/* y remains the same by default */
		newy = y;

		/* generate strings for InvoiceEntry */
		var tm = new DateTime.from_unix_local(e.timestamp);
		var date = tm.format(dateFormat);
                var time = tm.format(timeFormat);
		var article = e.product.name;
		var price = @"$(e.price)€".replace(".", ",");

		if(e.price > 999999) {
			throw new InvoicePDFError.PRICE_TOO_HIGH("Prices > 9999.99€ are not supported!");
		}

		if(tm.get_year() > 9999) {
			throw new InvoicePDFError.TOO_FAR_IN_THE_FUTURE("Years after 9999 are not supported!");
		}

		/* if date remains the same do not add it again */
		if(previous_tm != null &&
		   previous_tm.get_year() == tm.get_year() &&
		   previous_tm.get_month() == tm.get_month() &&
		   previous_tm.get_day_of_month() == tm.get_day_of_month()) {
			date = "";
		}

		/* move to position for article text */
		ctx.move_to(184, y);

		/* get pango layout */
		var layout = Pango.cairo_create_layout(ctx);

		/* setup font */
		var font = new Pango.FontDescription();
		font.set_family("LMSans10");
		font.set_size((int) 8 * Pango.SCALE);
		layout.set_font_description(font);

		/* left alignment */
		layout.set_alignment(Pango.Alignment.LEFT);
		layout.set_wrap(Pango.WrapMode.WORD_CHAR);

		/* set line spacing */
		layout.set_spacing((int) (-2.0 * Pango.SCALE));

		/* set page width */
		layout.set_width((int) 290 * Pango.SCALE);

		/* write invoice date */
		layout.set_text(article, article.length);

		/* get height of text */
		int w,h;
		layout.get_size(out w, out h);
		double height = h/Pango.SCALE;

		/* verify that the text fits on the page */
		if(750 < y + height)
			return false;

		/* render article text */
		Pango.cairo_update_layout(ctx, layout);
		Pango.cairo_show_layout(ctx, layout);

		/* render date, time (toy font api uses different y than pango) */
		ctx.select_font_face("LMSans10", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
		ctx.set_font_size(11);
		ctx.move_to(62, y+12.0);
		ctx.show_text(date);
		ctx.move_to(124, y+12.0);
		ctx.show_text(time);

		/* render price */
		ctx.move_to(484, y);
		var pricelayout = Pango.cairo_create_layout(ctx);
		pricelayout.set_font_description(font);
		pricelayout.set_alignment(Pango.Alignment.RIGHT);
		pricelayout.set_width((int) 42 * Pango.SCALE);
		pricelayout.set_text(price, price.length);
		Pango.cairo_update_layout(ctx, pricelayout);
		Pango.cairo_show_layout(ctx, pricelayout);

		/* add borders */
		ctx.set_line_width(0.8);
		ctx.move_to(58, y);
		ctx.line_to(58, y+height);
		ctx.move_to(120, y);
		ctx.line_to(120, y+height);
		ctx.move_to(180, y);
		ctx.line_to(180, y+height);
		ctx.move_to(480, y);
		ctx.line_to(480, y+height);
		ctx.move_to(530, y);
		ctx.line_to(530, y+height);
		ctx.stroke();

		ctx.restore();

		newy += height;
		previous_tm = tm;

		return true;
	}

	private void draw_invoice_table(Cairo.Context ctx) throws InvoicePDFError {
		ctx.save();

		draw_footer(ctx);
		draw_invoice_table_header(ctx);

		/* initial position for entries */
		double y = 65;

		foreach(var entry in invoice_entries) {
			if(!draw_invoice_table_entry(ctx, y, entry, out y)) {
				/* entry could not be added, because end of page has been reached */
				draw_invoice_table_footer(ctx, y);
				ctx.show_page();

				/* draw page footer & table header on new page */
				draw_footer(ctx);
				draw_invoice_table_header(ctx);

				/* reset position */
				y = 65;

				/* always print date on new pages */
				previous_tm = null;

				/* retry adding the entry */
				if(!draw_invoice_table_entry(ctx, y, entry, out y)) {
					throw new InvoicePDFError.ARTICLE_NAME_TOO_LONG("Article name \"%s\" does not fit on a single page!", entry.product.name);
				}
			}
		}

		draw_invoice_table_footer(ctx, y);
		ctx.show_page();

		ctx.restore();
	}

	private Cairo.Status pdf_write(uchar[] newdata) {
		if(data == null) {
			data = newdata;
			useddatalength = newdata.length;
		} else {
			if(useddatalength + newdata.length > data.length) {
				uint8[] alldata = new uint8[data.length + newdata.length + 512];
				Posix.memcpy(alldata, data, data.length);
				data = alldata;
			}

			Posix.memcpy((uint8*) data + useddatalength, newdata, newdata.length);
			useddatalength += newdata.length;
		}

		return Cairo.Status.SUCCESS;
	}

	public uint8[] generate() throws InvoicePDFError {
		data = null;

		var document = new Cairo.PdfSurface.for_stream(pdf_write, width, height);

		var ctx = new Cairo.Context(document);

		if(invoice_id == "")
			throw new InvoicePDFError.NO_INVOICE_ID("No invoice ID given!");

		if(invoice_entries == null)
			throw new InvoicePDFError.NO_INVOICE_DATA("No invoice data given!");

		if(invoice_date == 0)
			throw new InvoicePDFError.NO_INVOICE_DATE("No invoice date given!");

		if(invoice_recipient.firstname == "" && invoice_recipient.lastname == "")
			throw new InvoicePDFError.NO_INVOICE_RECIPIENT("No invoice recipient given!");

		/* first page */
		draw_logo(ctx);
		draw_address(ctx);
		draw_folding_marks(ctx);
		draw_footer(ctx);
		draw_footer_text_left(ctx);
		draw_footer_text_middle(ctx);
		draw_footer_text_right(ctx);
		draw_date(ctx);
		draw_title(ctx);
		draw_first_page_text(ctx);
		ctx.show_page();

		/* following pages: invoice table */
		draw_invoice_table(ctx);

		document.finish();
		document.flush();

		return data;
	}

	public void clear() {
		invoice_date                  = 0;
		invoice_id                    = "";
		invoice_recipient.firstname   = "";
		invoice_recipient.lastname    = "";
		invoice_recipient.street      = "";
		invoice_recipient.postal_code = "";
		invoice_recipient.city        = "";
		invoice_recipient.gender      = "";

		invoice_entries               = null;
	}
}
