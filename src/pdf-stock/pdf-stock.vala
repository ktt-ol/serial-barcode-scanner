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

[DBus (name = "io.mainframe.shopsystem.StockPDF")]
public class StockPDF {
	/* A4 sizes (in points, 72 DPI) */
	private const double a4w = 595.27559; /* 210mm */
	private const double a4h = 841.88976; /* 297mm */

	private const double eanw = 100.0;
	private const double eanh =  15.0;

	private const double col1 =  40;
	private const double col2 = 145;
	private const double col3 = 400;
	private const double col4 = 480;
	private const double col5 = 550;

	private const double row0 =  50;
	private const double row1 =  65;

	private const double padding = 3;

	private int64 timestamp;
	uint page;
	double y;

	EAN ean;
	Cairo.Context ctx;
	Pango.Layout layout;
	StockEntry[] stock;

	/* pdf data */
	private uint8[] data;
	private uint useddatalength;

	private void render_page_header() {
		var dt = new DateTime.from_unix_local(timestamp);
		ctx.move_to(145, 25);
		ctx.set_font_size(15.0);
		var date = dt.format("%Y-%m-%d %H:%M:%S");
		ctx.show_text(@"Shopsystem Stock - State: $date");
	}

	private void render_page_footer() {
		ctx.move_to(277, 820);
		ctx.set_font_size(12.0);
		ctx.show_text(@"Page $page");
	}

	private void render_table_header() {
		ctx.save();

		/* border & font color */
		ctx.set_source_rgb(0, 0, 0);

		/* line width of the border */
		ctx.set_line_width(0.8);

		/* header font */
		ctx.select_font_face("LMSans10", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
		ctx.set_font_size(12);

		ctx.move_to(col1, row0);
		ctx.line_to(col5, row0);
		ctx.line_to(col5, row1);
		ctx.line_to(col1, row1);
		ctx.line_to(col1, row0);
		ctx.move_to(col2, row0);
		ctx.line_to(col2, row1);
		ctx.move_to(col3, row0);
		ctx.line_to(col3, row1);
		ctx.move_to(col4, row0);
		ctx.line_to(col4, row1);
		ctx.stroke();

		/* header text */
		ctx.move_to(col1 + padding, row1 - padding);
		ctx.show_text("EAN");
		ctx.move_to(col2 + padding, row1 - padding);
		ctx.show_text("Produkt");
		ctx.move_to(col3 + padding, row1 - padding);
		ctx.show_text("Anzahl");
		ctx.move_to(col4 + padding, row1 - padding);
		ctx.show_text("Zählung");

		ctx.restore();
	}

	private void render_table_row(StockEntry product) throws BarcodeError {
		ctx.set_line_width(0.8);

		/* borders */
		ctx.move_to(col1, y);
		ctx.line_to(col1, y + eanh + 2*padding);
		ctx.line_to(col5, y + eanh + 2*padding);
		ctx.line_to(col5, y);
		ctx.move_to(col2, y);
		ctx.line_to(col2, y + eanh + 2*padding);
		ctx.move_to(col3, y);
		ctx.line_to(col3, y + eanh + 2*padding);
		ctx.move_to(col4, y);
		ctx.line_to(col4, y + eanh + 2*padding);
		ctx.stroke();

		/* EAN */
		ctx.move_to(col1 + padding, y + padding);
		ean.draw(product.id);

		/* Product Name */
		ctx.move_to(col2 + padding, y);
		layout.set_alignment(Pango.Alignment.LEFT);
		layout.set_wrap(Pango.WrapMode.WORD_CHAR);
		layout.set_spacing((int) (-padding * Pango.SCALE));
		layout.set_width((int) (col3-col2) * Pango.SCALE);
		var text = @"$(product.id)\n$(product.name)";
		layout.set_text(text, text.length);
		Pango.cairo_update_layout(ctx, layout);
		Pango.cairo_show_layout(ctx, layout);

		/* Amount */
		ctx.set_font_size(16.0);
		ctx.move_to(col3 + padding, y + eanh + 1);
		ctx.show_text(@"$(product.amount)");
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

	public uint8[] generate() {
		data = null;

		var surface = new Cairo.PdfSurface.for_stream(pdf_write, a4w, a4h);
		ctx = new Cairo.Context(surface);
		ean = new EAN(ctx, eanw, eanh);
		layout = Pango.cairo_create_layout(ctx);

		var font = new Pango.FontDescription();
		font.set_family("LMRoman8");
		font.set_size((int) 6.0 * Pango.SCALE);
		layout.set_font_description(font);

		/* get stock */
		try {
			Database db = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Database", "/io/mainframe/shopsystem/database");
			stock = db.get_stock();
			timestamp = new DateTime.now_local().to_unix();
		} catch(IOError e) {
			return data;
		}

		/* render pdf */
		ctx.select_font_face("LMSans10", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);

		try {
			y = row1;
			page = 1;

			render_page_header();
			render_table_header();

			foreach(var p in stock) {
				render_table_row(p);
				y += eanh + 6;

				if(y > 780) {
					y = row1;
					render_page_footer();
					ctx.show_page();
					page++;
					render_page_header();
					render_table_header();
				}
			}
			render_page_footer();
		} catch(BarcodeError e) {
			stderr.printf(e.message + "\n");
		}

		surface.finish();
		surface.flush();

		/* cleanup */
		ean = null;
		ctx = null;
		surface = null;

		return data;
	}

}
