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
		var bf = Path.build_filename(templatedir, "base.html");
		var b = File.new_for_path(bf);
		var mf = Path.build_filename(templatedir, "menu.html");
		var m = File.new_for_path(mf);
		var ff = Path.build_filename(templatedir, file);
		var f = File.new_for_path(ff);
		File fauth;

		if(login.logged_in)
			fauth = File.new_for_path(Path.build_filename(templatedir, "menu_logout.html"));
		else
			fauth = File.new_for_path(Path.build_filename(templatedir, "menu_login.html"));

		uint8[] basis, menu, template, auth;

		if(!b.query_exists())
			throw new TemplateError.NOT_FOUND(_("%s not found!").printf(bf));

		if(!m.query_exists())
			throw new TemplateError.NOT_FOUND(_("%s not found!").printf(mf));

		if(!fauth.query_exists())
			throw new TemplateError.NOT_FOUND(_("%s not found!").printf(fauth.get_path()));

		if(!f.query_exists())
			throw new TemplateError.NOT_FOUND(_("%s not found!").printf(ff));

		try {
			if(!b.load_contents(null, out basis, null))
				throw new TemplateError.NOT_LOADABLE(_("%s could not be loaded!").printf(bf));
			if(!m.load_contents(null, out menu, null))
				throw new TemplateError.NOT_LOADABLE(_("%s could not be loaded!").printf(mf));
			if(!fauth.load_contents(null, out auth, null))
				throw new TemplateError.NOT_LOADABLE(_("%s could not be loaded!").printf(fauth.get_path()));
			if(!f.load_contents(null, out template, null))
				throw new TemplateError.NOT_LOADABLE(_("%s could not be loaded!").printf(ff));
		} catch(Error e) {
			throw new TemplateError.NOT_LOADABLE(_("could not load templates!"));
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
		var ff = Path.build_filename(templatedir, file);
		var f = File.new_for_path(ff);
		uint8[] template;

		if(!f.query_exists())
			throw new TemplateError.NOT_FOUND(_("%s not found!").printf(ff));

		try {
			if(!f.load_contents(null, out template, null))
				throw new TemplateError.NOT_LOADABLE(_("%s could not be loaded!").printf(ff));
		} catch(Error e) {
			throw new TemplateError.NOT_LOADABLE(_("could not load templates!"));
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
