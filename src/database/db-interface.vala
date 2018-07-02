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
	public abstract StockEntry[] get_stock() throws IOError;
	public abstract PriceEntry[] get_prices(uint64 product) throws IOError;
	public abstract RestockEntry[] get_restocks(uint64 product, bool descending) throws IOError;
	public abstract bool buy(int32 user, uint64 article) throws IOError, DatabaseError;
	public abstract string get_product_name(uint64 article) throws IOError, DatabaseError;
	public abstract string get_product_category(uint64 article) throws IOError, DatabaseError;
	public abstract int get_product_amount(uint64 article) throws IOError, DatabaseError;
	public abstract bool get_product_deprecated(uint64 article) throws IOError, DatabaseError;
	public abstract void product_deprecate(uint64 article, bool value) throws IOError, DatabaseError;
	public abstract Price get_product_price(int user, uint64 article) throws IOError, DatabaseError;
	public abstract string undo(int32 user) throws IOError, DatabaseError;
	public abstract void restock(int user, uint64 product, uint amount, uint price, int supplier, int64 best_before_date) throws IOError, DatabaseError;
	public abstract void new_product(uint64 id, string name, int category, int memberprice, int guestprice) throws IOError, DatabaseError;
	public abstract void new_price(uint64 product, int64 timestamp, int memberprice, int guestprice) throws IOError, DatabaseError;
	public abstract bool check_user_password(int32 user, string password) throws IOError;
	public abstract void set_user_password(int32 user, string password) throws IOError, DatabaseError;
	public abstract void set_sessionid(int user, string sessionid) throws IOError, DatabaseError;
	public abstract void set_userTheme(int user, string userTheme) throws IOError, DatabaseError;
	public abstract void set_userLanguage(int user, string language) throws IOError, DatabaseError;
	public abstract int get_user_by_sessionid(string sessionid) throws IOError, DatabaseError;
	public abstract UserInfo get_user_info(int user) throws IOError, DatabaseError;
	public abstract UserAuth get_user_auth(int user) throws IOError, DatabaseError;
	public abstract void set_user_auth(UserAuth auth) throws IOError, DatabaseError;
	public abstract string get_username(int user) throws IOError, DatabaseError;
	public abstract string get_user_theme(int user, string fallback) throws IOError, DatabaseError;
	public abstract string get_user_language(int user, string fallback) throws IOError, DatabaseError;
	public abstract InvoiceEntry[] get_invoice(int user, int64 from=0, int64 to=-1) throws IOError, DatabaseError;
	public abstract Sale[] get_sales(int64 from=0, int64 to=-1) throws IOError, DatabaseError;
	public abstract int64 get_first_purchase(int user) throws IOError;
	public abstract int64 get_last_purchase(int user) throws IOError;
	public abstract StatsInfo get_stats_info() throws IOError;
	public abstract int[] get_member_ids() throws IOError;
	public abstract void user_disable(int user, bool value) throws IOError, DatabaseError;
	public abstract void user_replace(UserInfo u) throws IOError, DatabaseError;
	public abstract bool user_is_disabled(int user) throws IOError, DatabaseError;
	public abstract bool user_exists(int user) throws IOError, DatabaseError;
	public abstract bool user_equals(UserInfo u) throws IOError, DatabaseError;
	public abstract int64 get_timestamp_of_last_purchase() throws IOError;
	public abstract Category[] get_category_list() throws IOError;
	public abstract Supplier[] get_supplier_list() throws IOError;
	public abstract Supplier get_supplier(int id) throws IOError;
	public abstract void add_supplier(string name, string postal_code, string city, string street, string phone, string website) throws IOError, DatabaseError;
	public abstract int[] get_users_with_sales(int64 timestamp_from, int64 timestamp_to) throws IOError;
	public abstract Price get_user_invoice_sum(int user, int64 timestamp_from, int64 timestamp_to);
	public abstract Price cashbox_status() throws IOError;
	public abstract void cashbox_add(int user, Price amount, int64 timestamp) throws IOError, DatabaseError;
	public abstract CashboxDiff[] cashbox_history() throws IOError;
	public abstract CashboxDiff[] cashbox_changes(int64 start, int64 stop) throws IOError;
	public abstract void ean_alias_add(uint64 ean, uint64 real_ean) throws IOError, DatabaseError;
	public abstract uint64 ean_alias_get(uint64 ean) throws IOError;
	public abstract EanAlias[] ean_alias_list() throws IOError;
	public abstract BestBeforeEntry[] bestbeforelist() throws IOError;
	public abstract Product get_product_for_ean(uint64 ean) throws IOError, DatabaseError;
	public abstract int get_userid_for_rfid(string rfid) throws IOError, DatabaseError;
	public abstract void addrfid(string rfid, int user) throws IOError, DatabaseError;
	public abstract void delete_rfid_for_user(int user) throws IOError, DatabaseError;
	public abstract StatisticProductsPerDay[] get_statistic_products_per_day() throws DatabaseError;
	public abstract StatisticProductsPerDay[] get_statistic_products_per_day_withDate(string date) throws DatabaseError;
	public abstract StatisticProductsPerMonth[] get_statistic_products_per_month() throws DatabaseError;
	public abstract StatisticProductsPerMonth[] get_statistic_products_per_month_withMonthYear(string month, string year) throws DatabaseError;
	public abstract StatisticProductsPerYear[] get_statistic_products_per_year() throws DatabaseError;
	public abstract StatisticProductsPerYear[] get_statistic_products_per_year_withYear(string year) throws DatabaseError;
	public abstract StatisticSalesPerDay[] get_statistic_sales_per_day() throws DatabaseError;
	public abstract StatisticSalesPerDay[] get_statistic_sales_per_day_withDate(string date) throws DatabaseError;
	public abstract StatisticSalesPerMonth[] get_statistic_sales_per_month() throws DatabaseError;
	public abstract StatisticSalesPerMonth[] get_statistic_sales_per_month_withMonthYear(string month, string year) throws DatabaseError;
	public abstract StatisticSalesPerYear[] get_statistic_sales_per_year() throws DatabaseError;
	public abstract StatisticSalesPerYear[] get_statistic_sales_per_year_withYear(string year) throws DatabaseError;
	public abstract void publish_mqtt_stock_info();
}

public struct Category {
	public int id;
	public string name;
}

public struct StockEntry {
	public string id;
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
	public string language;

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
		if(rfid.length != x.rfid.length) return false;

		bool foundinequals = false;
		foreach (string rowSource in rfid) {
			foundinequals = false;
			foreach (string rowEquals in x.rfid){
				if(rowSource == rowEquals){
					foundinequals = true;
					break;
				}
			}
			if(!foundinequals){
				return false;
			}
		}

		foreach (string rowEquals in x.rfid){
			foundinequals = false;
		  foreach (string rowSource in rfid) {
				if(rowSource == rowEquals){
					foundinequals = true;
					break;
				}
			}
			if(!foundinequals){
				return false;
			}
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
	public Price memberprice;
	public Price guestprice;
}

public struct InvoiceEntry {
	public int64 timestamp;
	Product product;
	Price price;
}

public struct Sale {
	public int64 timestamp;
	public uint64 ean;
	public string productname;
	public int userId;
	public string userFirstname;
	public string userLastname;
	public Price price;
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

public struct StatisticProductsPerDay {
	public string day;
	public int64 numOfProducts;
	public Price total;
	public string product;
	public uint64 productId;
	public string category;
}

public struct StatisticProductsPerMonth {
	public string month;
	public string year;
	public int64 numOfProducts;
	public Price total;
	public string product;
	public uint64 productId;
	public string category;
}

public struct StatisticProductsPerYear {
	public string year;
	public int64 numOfProducts;
	public Price total;
	public string product;
	public uint64 productId;
	public string category;
}

public struct StatisticSalesPerDay {
	public string day;
	public int64 numOfProducts;
	public Price total;
}

public struct StatisticSalesPerMonth {
	public string month;
	public string year;
	public int64 numOfProducts;
	public Price total;
}

public struct StatisticSalesPerYear {
	public string year;
	public int64 numOfProducts;
	public Price total;
}

public errordomain DatabaseError {
	INTERNAL_ERROR,
	PRODUCT_NOT_FOUND,
	SESSION_NOT_FOUND,
	USER_NOT_FOUND,
	CONSTRAINT_FAILED,
	RFID_NOT_FOUND,
}
