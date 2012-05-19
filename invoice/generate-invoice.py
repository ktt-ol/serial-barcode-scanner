#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import datetime, sqlite3, sys

def invoice(user, title, subject, tofirstname, tolastname, toaddress, start=0, stop=0):
	connection = sqlite3.connect('shop.db')
	c = connection.cursor()
	startcondition = ""
	stopcondition = ""

	if start > 0:
		startcondition = " AND timestamp >= %d" % start
	if stop > 0:
		stopcondition = " AND timestamp <= %d" % stop
		

	result = "\\documentclass[ktt-template,12pt,pagesize=auto,enlargefirstpage=on,paper=a4]{scrlttr2}\n\n"
	result+= "\\title{%s}\n" % title
	result+= "\\author{Kreativität trifft Technik}\n"
	result+= "\\date{\\today}\n\n"

	result+= "\\setkomavar{subject}{%s}\n" % subject
	result+= "\\setkomavar{toname}{%s %s}\n" % (tofirstname, tolastname)
	result+= "\\setkomavar{toaddress}{%s}\n\n" % toaddress

	result+= "\\begin{document}\n"
	result+= "\t\\begin{letter}{}\n"
	result+= "\t\t\\opening{Sehr geehrter Herr %s,}\n\n" % tolastname

	result+= "\t\twir erlauben uns, Ihnen für den Verzehr von Speisen und Getränken wie folgt zu berechnen:\n\n"

	result += "\t\t\\begin{footnotesize}\n"
	result += "\t\t\t\\begin{longtable}{|l|l|l|}\n"
	result += "\t\t\t\t\\hline\n"
	result += "\t\t\t\tDatum		& Uhrzeit	& Artikel\\\\\n"
	result += "\t\t\t\t\\hline\n"

	c.execute("SELECT date(timestamp, 'unixepoch', 'localtime'), time(timestamp, 'unixepoch', 'localtime'), products.name FROM purchases, products WHERE user = ? AND products.id = purchases.product" + startcondition + stopcondition + " ORDER BY timestamp;", (user,))
	lastdate = ""
	for row in c:
		if lastdate != row[0]:
			result += "\t\t\t\t%s\t& %s\t& %s\\\\\n" % (row[0], row[1], row[2])
			lastdate = row[0]
		else:
			result += "\t\t\t\t%s\t& %s\t& %s\\\\\n" % ("           ", row[1], row[2])

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
start = int(datetime.datetime(2012, 5, 19, 0, 0, 0).strftime("%s"))
stop = int(datetime.datetime(2012, 5, 19, 23, 59, 59).strftime("%s"))
title = "Getränke Rechnung 05/2012" # TODO: autogen from supplied start/stop information
subject = "Rechnung Nr. 2012050001" # TODO: autogen somehow

tofirstname = "VORNAME" # TODO: autogen from user db
tolastname = "NACHNAME" # TODO: autogen from user db
toaddress = "ADDRESS" # TODO: autogen from user db

# this can be used to find users, which should get invoice
print("users:", get_users_with_purches(start, stop), file=sys.stderr)
print(invoice(user, title, subject, tofirstname, tolastname, toaddress, start, stop))
