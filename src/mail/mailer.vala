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
public class MailerImplementation {
	Smtp.Session session;
	bool messagecb_done = false;
	uint mailcounter = 0;

	struct MailEntry {
		uint registration_id;
		MailImplementation mail;
	}

	Queue<MailImplementation> send_queue;
	HashTable<string,MailEntry?> mails;
	MailImplementation? current_mail;

	string server;
	string username;
	string password;
	bool starttls;

	unowned string? callback(out string? buf, int *len) {
		buf = null;

		if(len != null && !messagecb_done) {
			buf = current_mail.generate();
			*len = buf.length;
			messagecb_done = true;
		}

		return buf;
	}

	int auth_interaction(Smtp.AuthClientRequest[] requests, char** result) {
		for(int i=0; i < requests.length; i++) {
			if(Smtp.AuthType.USER in requests[i].flags) {
				*(result+i) = username;
			} else if(Smtp.AuthType.PASS in requests[i].flags) {
				*(result+i) = password;
			}
		}
		return 1;
	}

	public MailerImplementation() throws IOError {
		int result;

		GMime.init(0);

		Smtp.auth_client_init();
		session = Smtp.Session();
		mails = new HashTable<string,MailEntry?>(str_hash, str_equal);
		send_queue = new Queue<MailImplementation>();

		/* ignore SIGPIPE, as suggested by libESMTP */
		Posix.signal(Posix.SIGPIPE, Posix.SIG_IGN);

		/* get configuration */
		Config config = Bus.get_proxy_sync(BusType.SESSION, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
		try {
			var cfgserv = config.get_string("MAIL", "server");
			var cfgport	= config.get_integer("MAIL", "port");
			server   = @"$cfgserv:$cfgport";
		} catch(KeyFileError e) {
			throw new IOError.FAILED("server or port configuration is missing");
		}

		try {
			username = config.get_string("MAIL", "username");
			password = config.get_string("MAIL", "password");
		} catch(KeyFileError e) {
			username = "";
			password = "";
		}

		try {
			starttls = config.get_boolean("MAIL", "starttls");
		} catch(KeyFileError e) {
			starttls = true;
		}

		/* setup server */
		result = session.set_server(server);
		if(result == 0)
			throw new IOError.FAILED("could not setup server");

		/* Use TLS if possible */
		if (starttls)
			result = session.starttls_enable(Smtp.StartTlsOption.ENABLED);
		else
			result = session.starttls_enable(Smtp.StartTlsOption.DISABLED);
		if(result == 0)
			throw new IOError.FAILED("could not configure STARTTLS");

		/* setup authentication */
		if(username != "") {
			var auth = Smtp.auth_create_context();
			auth.set_mechanism_flags(Smtp.AUTH_PLUGIN_PLAIN, 0);
			auth.set_interact_cb(auth_interaction);
			session.auth_set_context(auth);
		}
	}

	~MailerImplementation() {
		Smtp.auth_client_exit();
		GMime.shutdown();
	}

	public string create_mail() throws IOError {
		string path = @"/io/mainframe/shopsystem/mail/$mailcounter";

		var mail = new MailImplementation();

		MailEntry entry = {
			mail_bus.register_object(path, mail),
			mail
		};

		mails[path] = entry;
		mailcounter++;

		return path;
	}

	public void delete_mail(string path) throws IOError {
		if(!(path in mails))
			throw new IOError.NOT_FOUND("No such mail");

		mail_bus.unregister_object(mails[path].registration_id);
		mails.remove(path);
	}

	public void send_mail(string path) throws IOError {
		if(!(path in mails))
			throw new IOError.NOT_FOUND("No such mail");

		send_queue.push_tail(mails[path].mail);
		delete_mail(path);

		Idle.add(send_mail_background);

	}

	private bool send_mail_background() {
		current_mail = send_queue.pop_head();

		if(current_mail == null)
			return false;

		var message = session.add_message();

		messagecb_done = false;
		message.set_messagecb(callback);

		foreach(var recipient in current_mail.get_recipients()) {
			message.add_recipient(recipient);
		}
		message.set_reverse_path(current_mail.get_reverse_path());

		int result = session.start_session();
		if(result == 0)
			throw new IOError.FAILED("eSMTP: Start Session failed!");

		unowned Smtp.Status status = message.transfer_status();
		if(status.code < 200 || status.code >= 300)
			throw new IOError.FAILED("Reply from SMTP-Server: %s", status.text);

		current_mail = null;

		/* call method again, queue may not be empty */
		return true;
	}
}
