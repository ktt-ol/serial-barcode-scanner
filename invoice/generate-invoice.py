#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import datetime, sqlite3, sys

def get_user_info(userid):
	result = {
		"id": userid,
		"username": "",
		"email": "",
		"firstname": "",
		"lastname": "",
		"street": "",
		"city": ""
	}

	connection = sqlite3.connect('shop.db')
	c = connection.cursor()

	c.execute("SELECT id, username, email, firstname, lastname, street, city FROM users WHERE id = ?;", (userid,))

	for row in c:
		result["id"] = row[0]
		result["username"] = row[1]
		result["email"] = row[2]
		result["firstname"] = row[3]
		result["lastname"] = row[4]
		result["street"] = row[5]
		result["city"] = row[6]

	c.close()

	return result

def get_price_info(product, timestamp, member = True):
	result = 0
	connection = sqlite3.connect('shop.db')
	c = connection.cursor()

	field = "memberprice"
	if not member:
		field = "guestprice"

	c.execute("SELECT "+ field +" FROM prices WHERE product = ? AND valid_from <= ? ORDER BY valid_from ASC LIMIT 1;", (product,timestamp,))

	for row in c:
		result = int(row[0])

	c.close()

	return result

def invoice(user, title, subject, start=0, stop=0):
	connection = sqlite3.connect('shop.db')
	c = connection.cursor()
	startcondition = ""
	stopcondition = ""

	if start > 0:
		startcondition = " AND timestamp >= %d" % start
	if stop > 0:
		stopcondition = " AND timestamp <= %d" % stop
	
	userinfo = get_user_info(user)

	result = "\\documentclass[ktt-template,12pt,pagesize=auto,enlargefirstpage=on,paper=a4]{scrlttr2}\n\n"
	result+= "\\title{%s}\n" % title
	result+= "\\author{Kreativität trifft Technik}\n"
	result+= "\\date{\\today}\n\n"

	result+= "\\setkomavar{subject}{%s}\n" % subject
	result+= "\\setkomavar{toname}{%s %s}\n" % (userinfo["firstname"], userinfo["lastname"])
	result+= "\\setkomavar{toaddress}{%s\\newline\\newline\\textbf{%s}}\n\n" % (userinfo["street"], userinfo["city"])

	result+= "\\begin{document}\n"
	result+= "\t\\begin{letter}{}\n"
	result+= "\t\t\\opening{Sehr geehrter Herr %s,}\n\n" % userinfo["lastname"]

	result+= "\t\twir erlauben uns, Ihnen für den Verzehr von Speisen und Getränken wie folgt zu berechnen:\n\n"

	result += "\t\t\\begin{footnotesize}\n"
	result += "\t\t\t\\begin{longtable}{|l|l|l|l|}\n"
	result += "\t\t\t\t\\hline\n"
	result += "\t\t\t\tDatum		& Uhrzeit	& Artikel	& Preis\\\\\n"
	result += "\t\t\t\t\\hline\n"

	c.execute("SELECT date(timestamp, 'unixepoch', 'localtime'), time(timestamp, 'unixepoch', 'localtime'), products.name, purchases.product, purchases.timestamp FROM purchases, products WHERE user = ? AND products.id = purchases.product" + startcondition + stopcondition + " ORDER BY timestamp;", (user,))
	lastdate = ""
	total = 0
	for row in c:
		price = get_price_info(row[3], row[4], user != 0)
		total += price

		if lastdate != row[0]:
			result += "\t\t\t\t%s\t& %s\t& %s\t& %d,%d Euro\\\\\n" % (row[0], row[1], row[2], price / 100, price % 100)
			lastdate = row[0]
		else:
			result += "\t\t\t\t%s\t& %s\t& %s\t& %d,%d Euro\\\\\n" % ("           ", row[1], row[2], price / 100, price % 100)

	result += "\t\t\t\t\\hline\n"
	result += "\t\t\t\t\\multicolumn{3}{|l|}{Summe:} & %d,%d Euro\\\\\n" % (total / 100, total % 100)
	result += "\t\t\t\t\\hline\n"
	result += "\t\t\t\\end{longtable}\n"
	result += "\t\t\\end{footnotesize}\n\n"

	result += "\t\tUmsatzsteuer wird nicht erhoben, da Kreativität trifft Technik e.V. als Kleinunternehmen\n"
	result += "\t\tder Regelung des § 19 Abs. 1 UStG unterfällt.\n\n"

	result += "\t\t\\closing{Mit freundlichen Grüßen}\n\n"

	result += "\t\\end{letter}\n"
	result += "\\end{document}"

	c.close()

	return result

def get_users_with_purches(start, stop):
	result = []

	connection = sqlite3.connect('shop.db')
	c = connection.cursor()

	c.execute("SELECT user FROM purchases WHERE timestamp >= ? AND timestamp <= ? GROUP BY user ORDER BY user;", (start,stop))

	for row in c:
		result.append(row[0])

	c.close()

	return result


##############################
# User Code
##############################

user = 2342
start = int(datetime.datetime(2012, 5, 1, 0, 0, 0).strftime("%s"))
stop = int(datetime.datetime(2012, 5, 31, 23, 59, 59).strftime("%s"))

# TODO: autogenerate title and subject
title = "Getränke Rechnung 05/2012"
subject = "Rechnung Nr. 2012050001"

# this can be used to find users, which should get an invoice in a specified time slice
#print("users:", get_users_with_purches(start, stop), file=sys.stderr)

print(invoice(user, title, subject, start, stop))
