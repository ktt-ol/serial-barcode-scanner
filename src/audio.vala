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
	string path;

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
		path = Environment.get_current_dir()+"/sounds/";
		p = Gst.ElementFactory.make("playbin", "play");
		p.get_bus().add_watch(bus_callback);
	}

	public void play_system(string file) {
		p.set_state(Gst.State.NULL);
		p.uri = "file://" + path + "system/"+file;
		p.set_state(Gst.State.PLAYING);
	}

	private string[] get_files(string dir) {
		try {
			var directory = File.new_for_path(dir);
			var enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME, 0);
			string[] result = {};

			FileInfo file_info;
			while ((file_info = enumerator.next_file ()) != null) {
				result += file_info.get_name();
			}

			return result;
		} catch (Error e) {
			write_to_log("Error: %s\n", e.message);
			return {};
		}
	}

	private string get_random_file(string dir) {
		var files = get_files(dir);
		var index = Random.int_range(0, files.length);
		return files[index];
	}

	public string get_random_user_theme() {
		return get_random_file(path + "user/");
	}

	public void play_user(string theme, string type) {
		p.set_state(Gst.State.NULL);
		var file = get_random_file(path + "user/" + theme+ "/" + type);
		p.uri = "file://" + path + "user/" + theme+ "/" + type + "/" + file;
		p.set_state(Gst.State.PLAYING);
	}
}
