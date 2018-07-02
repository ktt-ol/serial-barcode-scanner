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
public interface Config : Object {
	public abstract bool has_group(string group_name) throws KeyFileError;
	public abstract bool has_key(string group_name, string key) throws KeyFileError;
	public abstract string get_string(string group_name, string key) throws KeyFileError;
	public abstract bool get_boolean(string group_name, string key) throws KeyFileError;
	public abstract int get_integer(string group_name, string key) throws KeyFileError;
	public abstract int64 get_int64(string group_name, string key) throws KeyFileError;
	public abstract uint64 get_uint64(string group_name, string key) throws KeyFileError;
	public abstract double get_double(string group_name, string key) throws KeyFileError;
}
