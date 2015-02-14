/* Copyright 2012, Sebastian Reichel <sre@ring0.de>
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

public errordomain TemplateError {
	NOT_FOUND,
	NOT_LOADABLE,
	NOT_ALLOWED,
}

public class WebTemplate {
	private string template;
	public uint8[] data { get { return template.data; } }

	public WebTemplate(string file, WebSession login) throws TemplateError {
		var b = File.new_for_path(templatedir+"base.html");
		var m = File.new_for_path(templatedir+"menu.html");
		var f = File.new_for_path(templatedir+file);
		File fauth;

		if(login.logged_in)
			fauth = File.new_for_path(templatedir+"menu_logout.html");
		else
			fauth = File.new_for_path(templatedir+"menu_login.html");

		uint8[] basis, menu, template, auth;

		if(!b.query_exists())
			throw new TemplateError.NOT_FOUND(templatedir+"base.html not found!");

		if(!m.query_exists())
			throw new TemplateError.NOT_FOUND(templatedir+"menu.html not found!");

		if(!fauth.query_exists())
			throw new TemplateError.NOT_FOUND(fauth.get_path()+" not found!");

		if(!f.query_exists())
			throw new TemplateError.NOT_FOUND(templatedir+file+" not found!");

		try {
			if(!b.load_contents(null, out basis, null))
				throw new TemplateError.NOT_LOADABLE(templatedir+"base.html could not be loaded!");
			if(!m.load_contents(null, out menu, null))
				throw new TemplateError.NOT_LOADABLE(templatedir+"menu.html could not be loaded!");
			if(!fauth.load_contents(null, out auth, null))
				throw new TemplateError.NOT_LOADABLE(fauth.get_path()+" could not be loaded!");
			if(!f.load_contents(null, out template, null))
				throw new TemplateError.NOT_LOADABLE(templatedir+file+" could not be loaded!");
		} catch(Error e) {
			throw new TemplateError.NOT_LOADABLE("could not load templates!");
		}

		this.template = ((string) basis).replace("{{{NAVBAR}}}", ((string) menu));
		this.template = this.template.replace("{{{AUTH}}}", ((string) auth));
		this.template = this.template.replace("{{{CONTENT}}}", ((string) template));
		this.template = this.template.replace("{{{USERNAME}}}", login.name);
		this.template = this.template.replace("{{{USERID}}}", "%d".printf(login.user));
		this.template = this.template.replace("{{{AUTH_USERS}}}", (login.superuser || login.auth_users) ? "" : "hidden");
		this.template = this.template.replace("{{{AUTH_CASHBOX}}}", (login.superuser || login.auth_cashbox) ? "" : "hidden");
	}

	public WebTemplate.DATA(string file) throws TemplateError {
		var f = File.new_for_path(templatedir+file);
		uint8[] template;

		if(!f.query_exists())
			throw new TemplateError.NOT_FOUND(templatedir+file+" not found!");

		try {
			if(!f.load_contents(null, out template, null))
				throw new TemplateError.NOT_LOADABLE(templatedir+file+" could not be loaded!");
		} catch(Error e) {
			throw new TemplateError.NOT_LOADABLE("could not load templates!");
		}

		this.template = (string) template;
	}

	public void replace(string key, string value) {
		template = template.replace("{{{"+key+"}}}", value);
	}

	public void menu_set_active(string key) {
		try {
			var regex_active = new Regex("{{{MENU\\."+key+"}}}");
			var regex_other = new Regex("{{{MENU\\..*}}}");

			template = regex_active.replace(template, -1, 0, "active");
			template = regex_other.replace(template, -1, 0, "");
		} catch(RegexError e) {
			warning ("%s", e.message);
		}
	}
}
