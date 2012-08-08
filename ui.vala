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

[PrintfFormat]
public void write_to_log(string format, ...) {
	var arguments = va_list();
	var message = format.vprintf(arguments);
	var time = new DateTime.now_local();

	var view = builder.get_object("logview") as Gtk.TextView;
	view.buffer.insert_at_cursor(time.format("[%Y-%m-%d %H:%M:%S] ") + message + "\n", -1);
	view.scroll_to_mark(view.buffer.get_insert(), 0.0, true, 0.0, 1.0);
}
