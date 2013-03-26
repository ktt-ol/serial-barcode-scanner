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

[DBus (name = "io.mainframe.shopsystem.Config")]
public class Cfg {

	private KeyFile file;

	public Cfg(string file) {
		try {
			this.file = new KeyFile();
			this.file.load_from_file(file, KeyFileFlags.NONE);
		} catch(Error e) {
			error("Could not load configuration file: %s", e.message);
		}
	}

	public bool has_group(string group_name) throws KeyFileError {
		return file.has_group(group_name);
	}

	public bool has_key(string group_name, string key) throws KeyFileError {
		return file.has_key(group_name, key);
	}

	public string get_string(string group_name, string key) throws KeyFileError {
		return file.get_string(group_name, key);
	}

	public bool get_boolean(string group_name, string key) throws KeyFileError {
		return file.get_boolean(group_name, key);
	}

	public int get_integer(string group_name, string key) throws KeyFileError {
		return file.get_integer(group_name, key);
	}

	public int64 get_int64(string group_name, string key) throws KeyFileError {
		return file.get_int64(group_name, key);
	}

	public uint64 get_uint64(string group_name, string key) throws KeyFileError {
		return file.get_uint64(group_name, key);
	}

	public double get_double(string group_name, string key) throws KeyFileError {
		return file.get_double(group_name, key);
	}

}
