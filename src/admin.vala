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

public class CSVMemberFile {
	private UserInfo[] members;

	public Gee.List<int> missing_unblocked_members() {
		var result = new Gee.ArrayList<int>();
		var dbusers = db.get_member_ids();

		foreach(var u in dbusers) {
			bool found=false;
			foreach(var m in members) {
				if(u == m.id) {
					found=true;
					break;
				}
			}

			if(!found) {
				if(!db.user_is_disabled(u))
					result.add(u);
			}
		}

		return result;
	}

	private string[] csv_split(string line) {
		return /;(?=(?:[^\"]*\"[^\"]*\")*(?![^\"]*\"))/.split(line);
	}

	private string csv_value(string value) {
		if(value[0] == '"' && value[value.length-1] == '"')
			return value.substring(1,value.length-2);
		else
			return value;
	}

	public CSVMemberFile(string data) {
		foreach(var line in data.split("\n")) {
			var linedata = csv_split(line);
			if(linedata.length >= 9) {
				var m = UserInfo();
				m.id = int.parse(csv_value(linedata[0]));
				m.email = csv_value(linedata[1]);
				m.firstname = csv_value(linedata[2]);
				m.lastname = csv_value(linedata[3]);
				m.street = csv_value(linedata[4]);
				m.postcode = int.parse(csv_value(linedata[5]));
				m.city = csv_value(linedata[6]);
				m.gender = csv_value(linedata[7]) == "m" ? "masculinum" : csv_value(linedata[7]) == "w" ? "femininum" : "unknown";
				m.pgp = csv_value(linedata[8]);
				if(csv_value(linedata[0]) != "EXTERNEMITGLIEDSNUMMER")
					members += m;
			}
		}
	}

	public UserInfo[] get_members() {
		return members;
	}
}

public class PGPKeyArchive {
	private string keyring;
	private GPG.Context gpg;

	public PGPKeyArchive(KeyFile config) {
		/* check version (important!) */
		GPG.check_version();

		/* initialize default context */
		GPG.Context.Context(out gpg);

		try {
			keyring = config.get_string("PGP", "keyring");

			/* remove quotes */
			if(keyring.has_prefix("\"") && keyring.has_suffix("\""))
				keyring = keyring.substring(1,keyring.length-2);
		} catch(KeyFileError e) {
			write_to_log("KeyFileError: %s", e.message);
			return;
		}

		/* TODO: check existence of keyring */

		/* set home directory */
		var info = gpg.get_engine_info();
		gpg.set_engine_info(info.protocol, info.file_name, keyring);
	}

	public void read() {
		unowned Archive.Entry entry;
		var archive = new Archive.Read();

		/* support all formats & compression types */
		archive.support_compression_all();
		archive.support_format_all();

		/* load test archive for now */
		/* TODO: use archive.open_memory(void *buffer, size_t size) */
		if(archive.open_filename("pgp-test.tar.gz", 4096) != Archive.Result.OK)
			return;

		while(archive.next_header(out entry) == Archive.Result.OK) {
			var name = entry.pathname();
			var size = entry.size();
			var content = new uint8[size];

			/* skip entries, which contain a slash */
			if(name.contains("/"))
				continue;

			/* skip files, which are big (probably not a minimal pgp key) */
			if(size > 50000)
				continue;

			if(archive.read_data((void*) content, (ssize_t) size) == size) {
				if(!((string) content).has_prefix("-----BEGIN PGP PUBLIC KEY BLOCK-----"))
					continue;

				/* put byte data into GPG.Data object */
				GPG.Data gpgdata;
				GPG.Data.create_from_memory(out gpgdata, content, false);

				/* import keys */
				gpg.op_import(gpgdata);
			}
		}
	}

	/* TODO: implement method, which list all keys available in the gpg keyring */

	/* TODO: implement method, which gets a key by keyid from gpg keyring */

	/* TODO: implement method, which signs a message */

	/* TODO: implement method, which signs & encrypts a message */
}
