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

[DBus (name = "io.mainframe.shopsystem.Mail")]
public class MailImplementation {
	private GMime.Message m;
	private GMime.Part? main_text = null;
	private GMime.Part? main_html = null;
	private GMime.Part[] attachments;

	private GMime.FilterCRLF filter;

	private string[] recipients;
	private string? reversepath;

	public MailContact from { set {
		string sender = value.name + " " + "<" + value.email + ">";
		reversepath = value.email;
		m.set_sender(sender);
	}}

	public string subject {
		owned get {
			var result = m.get_subject();
			return (result == null) ? "" : result;
		}
		set {
			m.set_subject(value);
		}
	}

	public string message_id {
		owned get {
			var result = m.get_message_id();
			return (result == null) ? "" : result;
		}
		set {
			m.set_message_id(value);
		}
	}

	public string reply_to {
		owned get {
			var result = m.get_reply_to();
			return (result == null) ? "" : result;
		}
		set {
			m.set_reply_to(value);
		}
	}

	public MailDate date {
		owned get {
			MailDate result = {};
			m.get_date(out result.date, out result.tz_offset);
			return result;
		}
		set {
			m.set_date((ulong) value.date, value.tz_offset);
		}
	}

	public MailImplementation() {
		m = new GMime.Message(true);
		m.set_header("X-Mailer", "KtT Shopsystem");
		attachments = new GMime.Part[0];
		filter = new GMime.FilterCRLF(true, true);
		recipients = new string[0];
	}

#if 0
	public void set_from(MailContact contact) {
		string sender = contact.name + " " + "<" + contact.email + ">";
		m.set_sender(sender);
	}

	public void set_subject(string subject) {
		m.set_subject(subject);
	}

	public void set_date(uint64 date, int tz_offset) {
		m.set_date((ulong) date, tz_offset);
	}
#endif

	public void add_recipient(MailContact contact, GMime.RecipientType type) {
		m.add_recipient(type, contact.name, contact.email);
		recipients += contact.email;
	}

	public void set_main_part(string text, MessageType type) {
		GMime.DataWrapper content = new GMime.DataWrapper.with_stream(
			new GMime.StreamMem.with_buffer(text.data),
			GMime.ContentEncoding.DEFAULT);

		GMime.Part? part = new GMime.Part();
		part.set_content_object(content);

		switch(type) {
			case MessageType.HTML:
				part.set_content_type(new GMime.ContentType.from_string("text/html; charset=utf-8"));
				part.set_content_encoding(part.get_best_content_encoding(GMime.EncodingConstraint.7BIT));
				main_html = part;
				break;
			case MessageType.PLAIN:
			default:
				part.set_content_type(new GMime.ContentType.from_string("text/plain; charset=utf-8; format=flowed"));
				part.set_content_encoding(part.get_best_content_encoding(GMime.EncodingConstraint.7BIT));
				main_text = part;
				break;
		}
	}

	public void add_attachment(string filename, string content_type, uint8[] data) {
		GMime.Part part = new GMime.Part();

		GMime.DataWrapper content = new GMime.DataWrapper.with_stream(
			new GMime.StreamMem.with_buffer(data),
			GMime.ContentEncoding.BINARY);

		/* configure part */
		part.set_disposition("attachment");
		part.set_filename(filename);
		part.set_content_type(new GMime.ContentType.from_string(content_type));
		part.set_content_object(content);
		part.set_content_encoding(part.get_best_content_encoding(GMime.EncodingConstraint.7BIT));

		attachments += part;
	}

	private GMime.Object? generate_main() {
		if(main_text != null && main_html != null) {
			var result = new GMime.Multipart.with_subtype("alternative");
			result.add(main_text);
			result.add(main_html);
			return result;
		} else if(main_text != null) {
			return main_text;
		} else if(main_html != null) {
			return main_html;
		}

		return null;
	}

	private GMime.Object? generate_attachments() {
		if(attachments.length == 1) {
			return attachments[0];
		} else if(attachments.length > 1) {
			var multipart = new GMime.Multipart.with_subtype("mixed");
			foreach(var attachment in attachments)
				multipart.add(attachment);
			return multipart;
		}

		return null;
	}

	private void update_mime_part() {
		GMime.Object? main = generate_main();
		GMime.Object? attachments = generate_attachments();
		GMime.Object? mime_message = null;

		if(main != null && attachments != null) {
			var multipart = new GMime.Multipart.with_subtype("mixed");
			multipart.add(main);
			multipart.add(attachments);
			mime_message = multipart;
		} else if(main != null) {
			mime_message = main;
		} else if(attachments != null) {
			mime_message = attachments;
		}

		m.set_mime_part(mime_message);
	}

	[DBus (visible = false)]
	public string generate() {
		update_mime_part();
		string result = m.to_string();
		uint8[] crlfdata;
		size_t prespace;
		filter.filter(result.data, 0, out crlfdata, out prespace);
		return (string) crlfdata;
	}

	[DBus (visible = false)]
	public unowned string[] get_recipients() {
		return recipients;
	}

	[DBus (visible = false)]
	public string get_reverse_path() {
		return reversepath;
	}
}
