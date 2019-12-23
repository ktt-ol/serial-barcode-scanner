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

[DBus (name = "io.mainframe.shopsystem.ScannerSession")]
public interface ScannerSession : Object {
	public abstract signal void msg(MessageType type, string message);
	public abstract signal void msg_overlay(string title, string message);
}

public enum MessageType {
	INFO,
	WARNING,
	ERROR
}

public enum ScannerSessionCodeType {
	USER,
	GUEST,
	UNDO,
	LOGOUT,
	EAN,
	RFIDEM4100,
	USERINFO,
	UNKNOWN
}

public enum ScannerSessionState {
	READY,
	USER
}

public struct ScannerResult {
	public MessageType type;
	public string message;
	public AudioType audioType;
	public string nextScannerdata;
}
