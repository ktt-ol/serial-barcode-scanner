public void init_ui() {
	init_restock_dialog();
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
		window.hide();
	});

	ok.clicked.connect(() => {
		var id = box.get_active_id();
		var product = (id != null) ? uint64.parse(id) : 0;
		var amount = (int) spinner.get_value();

		int64 timestamp = (new DateTime.now_utc()).to_unix();
		stdout.printf("[%lld] restock: %lld - %d\n", timestamp, product, amount);

		if(db.restock(product, amount))
			window.hide();
	});
}

public void show_restock_dialog() {
	(builder.get_object("restock_dialog") as Gtk.Window).show();
}
