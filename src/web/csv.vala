/* Copyright 2012, Sebastian Reichel <sre@ring0.de>
 * Copyright 2017-2018, Johannes Rudolph <johannes.rudolph@gmx.com>
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

	public Gee.List<int> missing_unblocked_members() throws DatabaseError, IOError {
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
			if(linedata.length >= 12) {
				var m = UserInfo();
				m.id = int.parse(csv_value(linedata[0]));
				m.email = csv_value(linedata[1]);
				m.firstname = csv_value(linedata[2]);
				m.lastname = csv_value(linedata[3]);
				m.street = csv_value(linedata[4]);
				m.postcode = csv_value(linedata[5]);
				m.city = csv_value(linedata[6]);
				m.gender = csv_value(linedata[7]) == "m" ? "masculinum" : csv_value(linedata[7]) == "w" ? "femininum" : "unknown";
				m.joined_at = int.parse(csv_value(linedata[8]));
				m.pgp = csv_value(linedata[9]);
				m.hidden = int.parse(csv_value(linedata[10])) != 0;
				m.disabled = int.parse(csv_value(linedata[11])) != 0;
				string[] rfid = {};
                                if(csv_value(linedata[12]) != "")
                                       rfid += csv_value(linedata[12]);
             			if(csv_value(linedata[13]) != "")
                                       rfid += csv_value(linedata[13]);
        			if(csv_value(linedata[14]) != "")
                                       rfid += csv_value(linedata[14]);
        			m.rfid = rfid;
 
                                m.soundTheme = "";
                                m.language = "";
				if(csv_value(linedata[0]) != "EXTERNEMITGLIEDSNUMMER")
					members += m;
			}
		}
	}

	public UserInfo[] get_members() {
		return members;
	}
}
