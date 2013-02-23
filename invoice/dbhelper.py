#!/usr/bin/env python3
#-*- coding: utf-8 -*-

import sqlite3

class DB(object):
	def __init__(self, dbfile='shop.db'):
		self.__connection = sqlite3.connect(dbfile)
	
	def get_user_info(self, userid):
		c = self.__connection.cursor()
		c.execute("SELECT id, email, firstname, lastname, gender, street, plz, city FROM users WHERE id = ?;", (userid,))
		row = c.fetchone()
		c.close()

		if row is None:
			return None
		else:
			return {
				"id": row[0],
				"email": row[1],
				"firstname": row[2],
				"lastname": row[3],
				"gender": row[4],
				"street": row[5],
				"plz": row[6],
				"city": row[7]
			}

	def get_invoice_data(self, user, start=0, stop=0):
		c = self.__connection.cursor()
		startcondition = ""
		stopcondition = ""

		if start > 0:
			startcondition = " AND timestamp >= %d" % start
		if stop > 0:
			stopcondition = " AND timestamp <= %d" % stop

		c.execute("SELECT date(timestamp, 'unixepoch', 'localtime'), time(timestamp, 'unixepoch', 'localtime'), productname, price FROM invoice WHERE user = ?" + startcondition + stopcondition + " ORDER BY timestamp;", (user,))

		result = []
		for row in c:
			result.append({
				"date": row[0],
				"time": row[1],
				"product": row[2],
				"price": row[3],
			})

		c.close()

		return result

	def get_invoice_amount(self, user, start=0, stop=0):
		query = "SELECT SUM(price) FROM invoice WHERE user = ? AND timestamp >= ? AND timestamp <= ?";
		amount = 0

		c = self.__connection.cursor()
		c.execute(query, (user, start, stop))

		for row in c:
			amount += row[0]

		c.close()
		return amount

	def get_users_with_purchases(self, start, stop):
		result = []

		c = self.__connection.cursor()

		c.execute("SELECT user FROM sales WHERE timestamp >= ? AND timestamp <= ? GROUP BY user ORDER BY user;", (start,stop))

		for row in c:
			result.append(row[0])

		c.close()

		return result
