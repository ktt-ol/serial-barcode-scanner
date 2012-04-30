public class Web {
	private Soup.SessionAsync session;
	private static string server = "https://shop.kreativitaet-trifft-technik.de";
	uint64 user = 0;

	public Web() {
		session = new Soup.SessionAsync();
		var cookies = new Soup.CookieJar();
		session.add_feature(cookies);
	}

	public void login(uint64 id) {
		//stdout.printf("login: %llu\n", id);

		var message = new Soup.Message("POST", server+"/login");
		var post_data = "userid=%llu".printf(id);
		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, post_data.data);
		session.send_message(message);

		stdout.write(message.response_body.data);
		stdout.printf("\n");

		/* on success */
		this.user = id;
	}

	public void logout() {
		if(this.is_logged_in()) {
			//stdout.printf("logout\n", id);

			var message = new Soup.Message("GET", server+"/logout");
			session.send_message(message);

			stdout.write(message.response_body.data);
			stdout.printf("\n");

			this.user = 0;
		}
	}

	public void buy(uint64 article) {
		if(this.is_logged_in()) {
			//stdout.printf(" buy: %llu\n", article);

			var message = new Soup.Message("POST", server+"/buy");
			var post_data = "article=%llu".printf(article);
			message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, post_data.data);
			session.send_message(message);

			stdout.write(message.response_body.data);
			stdout.printf("\n");
		} else {
			/* not logged into the system */
		}
	}

	public bool is_logged_in() {
		return (user != 0);
	}
}
