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

public class AudioPlayer {
	private dynamic Gst.Element p;

	public signal void end_of_stream();

	private bool bus_callback(Gst.Bus bus, Gst.Message message) {
		switch (message.type) {
			case Gst.MessageType.EOS:
				end_of_stream();
				break;
		}

		return true;
	}

	public AudioPlayer() {
		p = Gst.ElementFactory.make("playbin", "play");
		p.get_bus().add_watch(bus_callback);
	}

	public void play(string file) {
		p.set_state(Gst.State.NULL);
		p.uri = "file://"+Environment.get_current_dir()+"/sounds/"+file;
		p.set_state(Gst.State.PLAYING);
	}
}
