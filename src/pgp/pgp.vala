/* Copyright 2013, Sebastian Reichel <sre@ring0.de>
 * Copyright 2018, Johannes Rudolph <johannes.rudolph@gmx.com>
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

[DBus (name = "io.mainframe.shopsystem.PGP")]
public class PGPKeyArchive {
	private string keyring;
	private GPG.Context gpg;

	public PGPKeyArchive(string keyring) {
		/* check version (important!) */
		GPG.check_version();

		/* initialize default context */
		GPG.Context.Context(out gpg);

		/* TODO TODO TODO */
#if 0
		if(keyring.has_prefix("\"") && keyring.has_suffix("\""))
			this.keyring = keyring.substring(1,keyring.length-2);
#endif
		this.keyring = keyring;

		/* TODO: check existence of keyring */

		/* set home directory */
		var info = gpg.get_engine_info();
		gpg.set_engine_info(info.protocol, info.file_name, keyring);

		/* enable ascii armor */
		gpg.set_armor(true);
	}

	public string[] import_archive(uint8[] data) {
		string[] result = {};
		unowned Archive.Entry entry;
		var archive = new Archive.Read();

		/* support all formats & compression types */
		archive.support_filter_all();
		archive.support_format_all();

		/* load test archive for now */
		if(archive.open_memory(data, data.length) != Archive.Result.OK)
			return result;

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

				/* get result */
				unowned GPG.ImportResult importresult = gpg.op_import_result();

				/* add imported fingerprints to result */
				for(unowned GPG.ImportStatus st = importresult.imports; st != null; st = st.next) {
					if(!(st.fpr in result) && (st.status & GPG.ImportStatusFlags.NEW) != 0)
						result += st.fpr;
				}
			}
		}

		return result;
	}

	public string[] list_keys() {
		string[] result = {};
		GPG.Key key;

		gpg.op_keylist_start();

		while(gpg.op_keylist_next(out key) == GPGError.ErrorCode.NO_ERROR) {
			result += key.subkeys[0].fpr;
		}

		gpg.op_keylist_end();

		return result;
	}

	public string get_key(string fingerprint) {
		GPG.Data keydata;
		GPG.Data.create(out keydata);

		if(gpg.op_export(fingerprint, 0, keydata) == GPGError.ErrorCode.NO_ERROR) {
			long size = keydata.seek(0, Posix.FILE.SEEK_END);
			keydata.seek(0, Posix.FILE.SEEK_SET);
			stdout.printf("size: %ld\n", size);
			uint8[] data = new uint8[size];
			keydata.read(data);
			return (string) data;
		} else {
			stdout.printf("error!\n");
			return "";
		}
	}
}
