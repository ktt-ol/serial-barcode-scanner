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

[DBus (name = "io.mainframe.shopsystem.Mailer")]
public interface Mailer : Object {
	public abstract string create_mail() throws IOError;
	public abstract void delete_mail(string path) throws IOError;
	public abstract void send_mail(string path) throws IOError;
}

[DBus (name = "io.mainframe.shopsystem.Mail")]
public interface Mail : Object {
	public abstract MailContact from { set; }
	public abstract string subject { owned get; set; }
	public abstract string message_id { owned get; set; }
	public abstract string reply_to { owned get; set; }
	public abstract MailDate date { owned get; set; }

	public abstract void add_recipient(MailContact contact, GMime.RecipientType type = GMime.RecipientType.TO) throws IOError;
	public abstract void set_main_part(string text, MessageType type = MessageType.PLAIN) throws IOError;
	public abstract void add_attachment(string filename, string content_type, uint8[] data) throws IOError;
}

public struct MailAttachment {
	public string filename;
	public string filetype;
	public uint8[] data;
}

public struct MailRecipient {
	public string name;
	public string email;
}

public struct MailContact {
	string name;
	string email;
}

public struct MailDate {
	uint64 date;
	int tz_offset;
}

public enum MessageType {
	PLAIN,
	HTML
}
