public class Web {
	private Soup.SessionAsync session;
	private static string server = "https://shop.kreativitaet-trifft-technik.de";

	public Web() {
		session = new Soup.SessionAsync ();
	}

	public void login() {
		var message = new Soup.Message ("GET", server+"/login");
		session.send_message (message);
	}

	public void logout() {
		var message = new Soup.Message ("GET", server+"/logout");
		session.send_message (message);
	}

	public void add(string article) {
		var message = new Soup.Message ("GET", server+"/buy");
		session.send_message (message);
	}
}
