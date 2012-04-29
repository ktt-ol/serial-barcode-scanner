public class Web {
	private Soup.SessionAsync session;
	private static string server = "https://shop.kreativitaet-trifft-technik.de";
	uint64 user = 0;

	public Web() {
		session = new Soup.SessionAsync ();
	}

	public void login(uint64 id) {
		var message = new Soup.Message ("GET", server+"/login");
		session.send_message (message);

		stdout.printf("login: %llu\n", id);

		/* on success */
		this.user = id;
	}

	public void logout() {
		if(this.user != 0) {
			var message = new Soup.Message ("GET", server+"/logout");
			session.send_message (message);

			stdout.printf("logout: %llu\n", this.user);

			this.user = 0;
		}
	}

	public void buy(uint64 article) {
		if(this.user > 0) {
			var message = new Soup.Message ("GET", server+"/buy");
			session.send_message (message);

			stdout.printf(" product: %llu\n", article);
		} else {
			/* not logged into the system */
		}
	}

	public bool is_logged_in() {
		return (user != 0);
	}
}
