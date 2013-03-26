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

public MainLoop loop;

public static int main(string[] args) {
	/* handle unix signals */
	Unix.signal_add(Posix.SIGTERM, handle_signals);
	Unix.signal_add(Posix.SIGINT,  handle_signals);

	AudioPlayer audio = Bus.get_proxy_sync(BusType.SESSION, "io.mainframe.shopsystem.AudioPlayer", "/io/mainframe/shopsystem/audio");

	var ui = new CursesUI();

	ui.log("KtT Shop System has been started");
	audio.play_system("startup.ogg");

	/* run mainloop */
	loop.run();

	ui.log("Stopping Shop System");
	audio.play_system("shutdown.ogg");

	/* we need to run the mainloop to play audio */
	audio.end_of_stream.connect(() => { loop.quit(); });
	loop.run();

	/* leave curses mode */
	ui.exit();

	return 0;
}

bool handle_signals() {
	loop.quit();
	return false;
}
