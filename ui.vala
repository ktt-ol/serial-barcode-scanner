/* Copyright 2012, Sebastian Reichel <sre@ring0.de>
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

public void init_ui() {
	init_restock_dialog();
	init_main_window();
}

public void init_main_window() {
	var window = builder.get_object("main") as Gtk.Window;

	window.destroy.connect(() => {
		Gtk.main_quit();
	});
}

public void init_restock_dialog() {
	var window = builder.get_object("restock_dialog") as Gtk.Window;

	/* product combobox */
	var box = builder.get_object("comboboxtext1") as Gtk.ComboBoxText;
	foreach(var entry in db.get_products().entries) {
		box.append(entry.key, entry.value);
	}

	/* spinner button */
	var spinner = builder.get_object("spinbutton1") as Gtk.SpinButton;

	/* dialog buttons */
	var cancel = builder.get_object("button-restock-cancel") as Gtk.Button;
	var ok = builder.get_object("button-restock-add") as Gtk.Button;

	cancel.clicked.connect(() => {
		spinner.value = 0.0;
		box.active = -1;
		window.hide();
	});

	ok.clicked.connect(() => {
		var id = box.get_active_id();
		var product = (id != null) ? uint64.parse(id) : 0;
		var amount = (int) spinner.get_value();

		write_to_log("restock: %lld - %d\n", product, amount);

		if(db.restock(product, amount)) {
			spinner.value = 0.0;
			box.active = -1;
			window.hide();
		}
	});
}

public void show_restock_dialog() {
	(builder.get_object("restock-dialog") as Gtk.Window).show();
}

public void show_about_dialog() {
	(builder.get_object("about-dialog") as Gtk.Window).show();
}

public void show_main_window() {
	(builder.get_object("main") as Gtk.Window).show();
}

public void show_stock_dialog() {
	var liststore = builder.get_object("stock-store") as Gtk.ListStore;
	liststore.clear();

	Gtk.TreeIter iter;
	foreach(var item in db.get_stock()) {
		liststore.append(out iter);
		liststore.set(iter, 0, item.id, 1, item.name, 2, item.amount, 3, item.memberprice, 4, item.guestprice, -1);
	}

	(builder.get_object("stock-dialog") as Gtk.Window).show();
}

public void stock_dialog_handle_response(Gtk.Dialog dialog, int responseid) {
	if(responseid == 1) {
		stock_dialog_print(dialog);
	} else {
		dialog.hide();
	}
}

public void stock_dialog_print(Gtk.Window parentw) {
	var operation = new Gtk.PrintOperation();

	operation.n_pages = 1; // FIXME: implement correct paging
	operation.draw_page.connect(draw_page);

	try {
		operation.run(Gtk.PrintOperationAction.PRINT_DIALOG, parentw);
	} catch(Error e) {
		error("error while printing: %s\n", e.message);
	}
}

public void draw_page(Gtk.PrintContext context, int nr) {
	uint8 HEADER_HEIGHT = 100;
	uint8 LEFT_MARGIN   = 25;

	var cr = context.get_cairo_context();
	int height, x, y = HEADER_HEIGHT;
	Value value;
	Gdk.Rectangle rect;
	var layout = context.create_pango_layout();
	var desc = Pango.FontDescription.from_string("Monospace");
	desc.set_size(10 * Pango.SCALE);
	layout.set_font_description(desc);
	layout.set_text("Current KtT Shop Stock", -1);
	layout.set_width(-1);
	layout.set_alignment(Pango.Alignment.LEFT);
	layout.get_size(null, out height);
	var text_height = height / Pango.SCALE;

	cr.move_to(LEFT_MARGIN, (HEADER_HEIGHT - text_height) / 2);
	Pango.cairo_show_layout(cr, layout);

	var view = builder.get_object("stock-view") as Gtk.TreeView;
	var model = view.get_model();
	Gtk.TreeIter iter = {};
	Gtk.TreeViewColumn column;
	var path = new Gtk.TreePath.first(); // keep the same for the whole document
	string text = "";

	for(int i = 0; i < 100 && model.get_iter(out iter, path); i++) {
		x = LEFT_MARGIN;

		for(int col_num=0; col_num < model.get_n_columns(); col_num++) {
			column = view.get_column(col_num);

			if(column.visible) {
				model.get_value(iter,col_num,out value);

				if(value.holds(typeof(string))) {
					text = value.get_string();
					if(text == null) text = "";
				} else if(value.holds(typeof(int))) {
					text = "%d".printf(value.get_int());
				} else {
					text = "";
				}

				value.unset();
			}

			view.get_background_area(path,column,out rect);

			layout.set_text(text, -1);

			layout.set_width(rect.width * Pango.SCALE);
			layout.set_wrap(Pango.WrapMode.CHAR);
			layout.set_ellipsize(Pango.EllipsizeMode.END);
			cr.move_to(x, y);
			Pango.cairo_show_layout(cr, layout);

			x += (rect.width+3);
		}

		y += text_height;
		path.next();
	}
}

[PrintfFormat]
public void write_to_log(string format, ...) {
	var arguments = va_list();
	var message = format.vprintf(arguments);
	var time = new DateTime.now_local();
	Gtk.TextIter iter;

	var view = builder.get_object("logview") as Gtk.TextView;

	/* insert text */
	view.buffer.get_iter_at_offset(out iter, -1);
	view.buffer.insert(ref iter, time.format("[%Y-%m-%d %H:%M:%S] ") + message + "\n", -1);

	/* scroll to end of text */
	view.buffer.get_iter_at_offset(out iter, -1);
	view.buffer.place_cursor(iter);
	view.scroll_to_mark(view.buffer.get_insert(), 0.0, true, 0.0, 1.0);
}
