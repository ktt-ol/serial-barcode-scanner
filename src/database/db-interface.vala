/* Copyright 2013, Sebastian Reichel <sre@ring0.de>
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

[DBus (name = "io.mainframe.shopsystem.Database")]
public interface Database : Object {
	public abstract DetailedProduct[] get_stock() throws DBusError, IOError;
	public abstract DetailedProduct get_product_for_ean(uint64 ean) throws DBusError, IOError, DatabaseError;
	public abstract PriceEntry[] get_prices(uint64 product) throws DBusError, IOError;
	public abstract RestockEntry[] get_restocks(uint64 product, bool descending) throws DBusError, IOError;
	public abstract bool buy(int32 user, uint64 article) throws DBusError, IOError, DatabaseError;
	public abstract string get_product_name(uint64 article) throws DBusError, IOError, DatabaseError;
	public abstract uint64[] get_product_aliases(uint64 article) throws DBusError, IOError, DatabaseError;
	public abstract string get_product_category(uint64 article) throws DBusError, IOError, DatabaseError;
	public abstract int get_product_amount(uint64 article) throws DBusError, IOError, DatabaseError;
	public abstract bool get_product_deprecated(uint64 article) throws DBusError, IOError, DatabaseError;
	public abstract void product_deprecate(uint64 article, bool value) throws DBusError, IOError, DatabaseError;
	public abstract Price get_product_price(int user, uint64 article) throws DBusError, IOError, DatabaseError;
	public abstract string undo(int32 user) throws DBusError, IOError, DatabaseError;
	public abstract void restock(int user, uint64 product, uint amount, uint price, int supplier, int64 best_before_date) throws DBusError, IOError, DatabaseError;
	public abstract void new_product(uint64 id, string name, int category, int memberprice, int guestprice) throws DBusError, IOError, DatabaseError;
	public abstract void new_price(uint64 product, int64 timestamp, int memberprice, int guestprice) throws DBusError, IOError, DatabaseError;
	public abstract bool check_user_password(int32 user, string password) throws DBusError, IOError;
	public abstract void set_user_password(int32 user, string password) throws DBusError, IOError, DatabaseError;
	public abstract void set_sessionid(int user, string sessionid) throws DBusError, IOError, DatabaseError;
	public abstract void set_userTheme(int user, string userTheme) throws DBusError, IOError, DatabaseError;
	public abstract int get_user_by_sessionid(string sessionid) throws DBusError, IOError, DatabaseError;
	public abstract UserInfo get_user_info(int user) throws DBusError, IOError, DatabaseError;
	public abstract UserAuth get_user_auth(int user) throws DBusError, IOError, DatabaseError;
	public abstract void set_user_auth(UserAuth auth) throws DBusError, IOError, DatabaseError;
	public abstract string get_username(int user) throws DBusError, IOError, DatabaseError;
	public abstract string get_user_theme(int user, string fallback) throws DBusError, IOError, DatabaseError;
	public abstract InvoiceEntry[] get_invoice(int user, int64 from=0, int64 to=-1) throws DBusError, IOError, DatabaseError;
	public abstract int64 get_first_purchase(int user) throws DBusError, IOError;
	public abstract int64 get_last_purchase(int user) throws DBusError, IOError;
	public abstract StatsInfo get_stats_info() throws DBusError, IOError;
	public abstract int[] get_member_ids() throws DBusError, IOError, DatabaseError;
	public abstract int[] get_system_member_ids() throws DBusError, IOError, DatabaseError;
	public abstract void user_disable(int user, bool value) throws DBusError, IOError, DatabaseError;
	public abstract void user_replace(UserInfo u) throws DBusError, IOError, DatabaseError;
	public abstract bool user_is_disabled(int user) throws DBusError, IOError, DatabaseError;
	public abstract bool user_exists(int user) throws DBusError, IOError, DatabaseError;
	public abstract bool user_equals(UserInfo u) throws DBusError, IOError, DatabaseError;
	public abstract int64 get_timestamp_of_last_purchase() throws DBusError, IOError;
	public abstract Category[] get_category_list() throws DBusError, IOError, DatabaseError;
	public abstract int add_category(string name) throws DBusError, IOError, DatabaseError;
	public abstract Supplier[] get_supplier_list() throws DBusError, IOError;
	public abstract Supplier get_supplier(int id) throws DBusError, IOError;
	public abstract void add_supplier(string name, string postal_code, string city, string street, string phone, string website) throws DBusError, IOError, DatabaseError;
	public abstract int[] get_users_with_sales(int64 timestamp_from, int64 timestamp_to) throws DBusError, IOError;
	public abstract Price get_user_invoice_sum(int user, int64 timestamp_from, int64 timestamp_to) throws DBusError, IOError;
	public abstract Price cashbox_status() throws DBusError, IOError;
	public abstract void cashbox_add(int user, Price amount, int64 timestamp) throws DBusError, IOError, DatabaseError;
	public abstract CashboxDiff[] cashbox_history() throws DBusError, IOError;
	public abstract CashboxDiff[] cashbox_changes(int64 start, int64 stop) throws DBusError, IOError;
	public abstract void ean_alias_add(uint64 ean, uint64 real_ean) throws DBusError, IOError, DatabaseError;
	public abstract uint64 ean_alias_get(uint64 ean) throws DBusError, IOError;
	public abstract EanAlias[] ean_alias_list() throws DBusError, IOError;
	public abstract BestBeforeEntry[] bestbeforelist() throws DBusError, IOError;
	public abstract int get_userid_for_rfid(string rfid) throws DBusError, IOError, DatabaseError;
	public abstract void addrfid(string rfid, int user) throws DBusError, IOError, DatabaseError;
	public abstract void delete_rfid_for_user(int user) throws DBusError, IOError, DatabaseError;
}

public struct Category {
	public int id;
	public string name;
}

public struct DetailedProduct {
	public uint64 ean;
	public string name;
	public string category;
	public int amount;
	public Price memberprice;
	public Price guestprice;
}

public struct PriceEntry {
	public int64 valid_from;
	public Price memberprice;
	public Price guestprice;
}

public struct RestockEntry {
	public int64 timestamp;
	public int amount;
	public string price;
	public int supplier;
	public int64 best_before_date;
}

public struct BestBeforeEntry {
	public uint64 ean;
	public string name;
	public int amount;
	public int64 best_before_date;
}

public struct Supplier {
	public int64 id;
	public string name;
	public string postal_code;
	public string city;
	public string street;
	public string phone;
	public string website;
}

public struct UserInfo {
	public int id;
	public string firstname;
	public string lastname;
	public string email;
	public string gender;
	public string street;
	public string postcode;
	public string city;
	public string pgp;
	public int64 joined_at;
	public bool disabled;
	public bool hidden;
	public string soundTheme;
	public string[] rfid;

	public bool equals(UserInfo x) {
		if(id != x.id) return false;
		if(firstname != x.firstname) return false;
		if(lastname != x.lastname) return false;
		if(email != x.email) return false;
		if(gender != x.gender) return false;
		if(street != x.street) return false;
		if(postcode != x.postcode) return false;
		if(city != x.city) return false;
		if(pgp != x.pgp) return false;
		if(joined_at != x.joined_at) return false;
		if(disabled != x.disabled) return false;
		if(hidden != x.hidden) return false;

		/* check if both objects contain the same RFIDs */
		foreach(var id in rfid) {
			if(!(id in x.rfid))
				return false;
		}
		foreach(var id in x.rfid) {
			if(!(id in rfid))
				return false;
		}

		return true;
	}
}

public struct UserAuth {
	public int id;
	public bool superuser;
	public bool auth_cashbox;
	public bool auth_products;
	public bool auth_users;
}

public struct Product {
	public uint64 ean;
	public string name;
}

public struct InvoiceEntry {
	public int64 timestamp;
	Product product;
	Price price;
}

public struct CashboxDiff {
	public int user;
	public Price amount;
	public int64 timestamp;
}

public struct EanAlias {
	public uint64 ean;
	public uint64 real_ean;
}

public struct StatsInfo {
	public int count_articles;
	public int count_users;
	public Price stock_value;
	public Price sales_total;
	public Price profit_total;
	public Price sales_today;
	public Price profit_today;
	public Price sales_this_month;
	public Price profit_this_month;
	public Price sales_per_day;
	public Price profit_per_day;
	public Price sales_per_month;
	public Price profit_per_month;
}

public errordomain DatabaseError {
	INTERNAL_ERROR,
	PRODUCT_NOT_FOUND,
	SESSION_NOT_FOUND,
	USER_NOT_FOUND,
	CONSTRAINT_FAILED,
	RFID_NOT_FOUND,
}
