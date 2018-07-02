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

public MainLoop loop;
public AudioPlayer audio;
public ScannerSession scanner;
public CursesUI ui;
public Config config;

private static void play(string file) {
	try {
		audio.play_system(file);
	} catch(IOError e) {
		ui.log(MessageType.WARNING, "could not play audio: %s".printf(e.message));
	}
}

public void msg_handler(MessageType type, string message) {
	ui.log(type, message);
}

public void msg_overlay_handler(string title, string message) {
	ui.log_overlay(title, message, 5);
}

public void privacy_handler(bool mode) {
        ui.setPrivacyMode(mode);
}

public void log_handler(string? log_domain, LogLevelFlags flags, string message) {
	ui.log(MessageType.INFO, message);
}

public static int main(string[] args) {
	loop = new MainLoop();

	/* handle unix signals */
	Unix.signal_add(Posix.SIGTERM, handle_signals);
	Unix.signal_add(Posix.SIGINT,  handle_signals);

	try {
		audio = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.AudioPlayer", "/io/mainframe/shopsystem/audio");
		scanner = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.ScannerSession", "/io/mainframe/shopsystem/scanner_session");
		config = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
	} catch(IOError e) {
		error("IOError: %s\n", e.message);
	}

  string binarylocation = File.new_for_path(args[0]).get_parent().get_path();

	ui = new CursesUI(binarylocation);

	Log.set_default_handler(log_handler);

	scanner.msg.connect(msg_handler);
	scanner.msg_overlay.connect(msg_overlay_handler);
	scanner.set_privacy_mode.connect(privacy_handler);

  /* get configuration */
  var shopname = config.get_string("GENERAL", "longname");

	ui.log(MessageType.INFO, @"$shopname Shop System has been started");
	play("startup.ogg");

	/* run mainloop */
	loop.run();

	ui.log(MessageType.INFO, "Stopping Shop System");
	play("shutdown.ogg");

	/* leave curses mode */
	ui.exit();

	return 0;
}

bool handle_signals() {
	loop.quit();
	return false;
}
