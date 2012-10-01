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

public class stock {
	public class product {
		public struct subitem {
			public uint64 timestamp;
			public int amount;

			public string json {
				owned get {
					return "[%llu, %d]".printf(timestamp*1000, amount);
				}
			}
		}

		public uint64 id;
		public string name;
		subitem[] data;

		public product(uint64 id, string name) {
			this.id = id;
			this.name = name;
			this.data = null;
		}

		public void add(uint64 timestamp, int amount) {
			subitem newitem = {timestamp, amount};
			this.data += newitem;
		}

		public string json {
			owned get {
				var data_array = "[";
				if(data != null) {
					for(int i=0; i < data.length-1; i++)
						data_array += data[i].json + ", ";
					data_array += data[data.length-1].json;
				}
				data_array += "]";

				return "{label: \"%s\", data: %s}".printf(name, data_array);
			}
		}
	}

	Gee.HashMap<uint64?,product> data;

	public stock() {
		data = new Gee.HashMap<uint64?,product>();
	}

	public void add(product i) {
		data[i.id] = i;
	}

	public product get_product(uint64 id) {
		return data[id];
	}

	public string json {
		owned get {
			var result = "{";
			foreach(var entry in data.entries) {
				uint64? id = entry.key;
				string pdata = entry.value.json;
				result += @"\"product_$id\": $pdata, ";
			}
			result = result.substring(0, result.length-2);
			result += "}";
			return result;
		}
	}
}

public class profit_per_day {
	public struct subitem {
		public uint64 timestamp;
		public Price amount;

		public string json {
			owned get {
				return @"[$(timestamp*1000), $amount]";
			}
		}
	}

	private subitem[] profit_data;
	private subitem[] sales_data;

	public void add_profit(uint64 timestamp, int amount) {
		subitem newitem = {timestamp, amount};
		this.profit_data += newitem;
	}

	public void add_sales(uint64 timestamp, int amount) {
		subitem newitem = {timestamp, amount};
		this.sales_data += newitem;
	}

	public string json {
		owned get {
			var result = "{\"profit\": {label: \"Profit\", data: [";
			if(profit_data != null) {
				for(int i=0; i < profit_data.length-1; i++)
					result += profit_data[i].json + ", ";
				result += profit_data[profit_data.length-1].json;
			}
			result += "]},\"sales\": {label: \"Sales\", data:[";
			if(sales_data != null) {
				for(int i=0; i < sales_data.length-1; i++)
					result += sales_data[i].json + ", ";
				result += sales_data[sales_data.length-1].json;
			}
			result += "]}}";

			return result;
		}
	}
}

public class profit_per_weekday {
	public Price[] day = new Price[7];

	public profit_per_weekday() {
		for(int i=0; i<day.length; i++)
			day[i] = 0;
	}

	public string json {
		owned get {
			var result = "[";
			result += @"{ label: \"Monday\", data: $(day[0]) },";
			result += @"{ label: \"Tuesday\", data: $(day[1]) },";
			result += @"{ label: \"Wednesday\", data: $(day[2]) },";
			result += @"{ label: \"Thursday\", data: $(day[3]) },";
			result += @"{ label: \"Friday\", data: $(day[4]) },";
			result += @"{ label: \"Saturday\", data: $(day[5]) },";
			result += @"{ label: \"Sunday\", data: $(day[6]) }";
			result += "]";
			return result;
		}
	}
}

public class profit_per_product {
	Gee.HashMap<string,int> data;

	public profit_per_product() {
		data = new Gee.HashMap<string,int>();
	}

	public void add(string product, int amount) {
		if(data.has_key(product))
			data[product] = data[product] + amount;
		else
			data[product] = amount;
	}

	public string json {
		owned get {
			var result = "[";
			foreach(var e in data.entries) {
				result += @"{ label: \"$(e.key)\", data: $((Price) e.value) },";
			}
			if(result.length > 1) {
				result = result.substring(0, result.length-1);
			}
			result += "]";
			return result;
		}
	}
}
