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

public Device dev;
public Database db;
public AudioPlayer audio;
public CSVMemberFile csvimport;
public ScannerSession localsession;
public MainLoop loop;
public PGPKeyArchive pgp;
public KeyFile cfg;
public CursesUI ui;

const OptionEntry[] option_entries = {
	{ "version", 'v', OptionFlags.IN_MAIN, OptionArg.NONE, ref opt_version, "output version information and exit", null },
	{ "", 0, 0, OptionArg.FILENAME_ARRAY, ref files, "serial device", "DEVICE" },
	{null}
};

/* parameters */
static string[] files;
static bool opt_version;

public static int main(string[] args) {
	/* parse parameters from shell */
	var context = new OptionContext("- KtT Shop System");
	context.set_help_enabled(true);
	context.add_main_entries(option_entries, "shop");
	context.add_group(Gst.init_get_option_group());

	try {
		context.parse(ref args);
	} catch(OptionError e) {
		stderr.puts(e.message + "\n");
		return 1;
	}

	if(opt_version) {
		stdout.puts("Ktt Shop System 0.1\n");
		return 0;
	}

	if(files == null || files[0] == null) {
		stderr.puts("Please specify serial device!\n");
		return 1;
	}

	/* handle unix signals */
	Unix.signal_add(Posix.SIGTERM, handle_signals);
	Unix.signal_add(Posix.SIGINT,  handle_signals);

	dev   = new Device(files[0], 9600, 8, 1);
	db    = new Database("shop.db");
	audio = new AudioPlayer();
	loop  = new MainLoop();
	localsession = new ScannerSession();

	try {
		cfg = new KeyFile();
		cfg.load_from_file("ktt-shopsystem.cfg", KeyFileFlags.NONE);
	} catch(Error e) {
		error("Could not load configuration file: %s", e.message);
	}

	pgp = new PGPKeyArchive(cfg);

	dev.received_barcode.connect((data) => {
		if(localsession.interpret(data))
			dev.blink(10);
	});

	ui = new CursesUI();

	while(!check_valid_time()) {
		write_to_log("Invalid System Time! Retry in 1 minute...");
		Posix.sleep(60);
	}

	write_to_log("KtT Shop System has been started");
	audio.play_system("startup.ogg");

	/* attach webserver to mainloop */
	new WebServer();

	/* run mainloop */
	loop.run();

	write_to_log("Stopping Shop System");
	audio.play_system("shutdown.ogg");

	/* we need to run the mainloop to play audio */
	audio.end_of_stream.connect(() => { loop.quit(); });
	loop.run();

	/* explicitly call destructors */
	dev   = null;
	db    = null;
	audio = null;
	ui.exit();

	return 0;
}

public bool check_valid_time() {
	return time_t() > db.get_timestamp_of_last_purchase();
}

public void write_to_log(string format, ...) {
	var arguments = va_list();
	var message = format.vprintf(arguments);

	ui.log(message);
}

bool handle_signals() {
	loop.quit();
	return false;
}
