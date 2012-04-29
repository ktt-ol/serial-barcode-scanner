public class Web {
	private Soup.SessionAsync session;
	private static string server = "https://shop.kreativitaet-trifft-technik.de";
	int user = -1;

	public Web() {
		session = new Soup.SessionAsync ();
	}

	public void login(int id) {
		var message = new Soup.Message ("GET", server+"/login");
		session.send_message (message);

		/* on success */
		this.user = id;
	}

	public void logout() {
		if(this.user != -1) {
			var message = new Soup.Message ("GET", server+"/logout");
			session.send_message (message);

			this.user = -1;
		}
	}

	public void add(string article) {
		if(this.user >= 0) {
			var message = new Soup.Message ("GET", server+"/buy");
			session.send_message (message);
		} else {
			/* not logged into the system */
		}
	}

	public bool is_logged_in() {
		return (user != -1);
	}
}
