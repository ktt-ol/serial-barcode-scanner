#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import datetime, sqlite3, os, sys, smtplib, subprocess, time, tempfile
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication
from email.mime.text import MIMEText
from email.header import Header

from config import *

def get_user_info(userid):
	connection = sqlite3.connect('shop.db')
	c = connection.cursor()
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

def get_invoice_data(user, start=0, stop=0):
	connection = sqlite3.connect('shop.db')
	c = connection.cursor()
	startcondition = ""
	stopcondition = ""

	if start > 0:
		startcondition = " AND timestamp >= %d" % start
	if stop > 0:
		stopcondition = " AND timestamp <= %d" % stop

	c.execute("SELECT date(timestamp, 'unixepoch', 'localtime'), time(timestamp, 'unixepoch', 'localtime'), products.name, purchases.product, purchases.timestamp FROM purchases, products WHERE user = ? AND products.id = purchases.product" + startcondition + stopcondition + " ORDER BY timestamp;", (user,))

	result = []
	for row in c:
		result.append({
			"date": row[0],
			"time": row[1],
			"product": row[2],
			"price": int(get_price_info(row[3], row[4], user != 0)),
		})

	c.close()

	return result

def generate_invoice_tex(user, title, subject, start=0, stop=0):
	userinfo = get_user_info(user)

	result = "\\documentclass[ktt-template,12pt,pagesize=auto,enlargefirstpage=on,paper=a4]{scrlttr2}\n\n"
	result+= "\\title{%s}\n" % title
	result+= "\\author{Kreativität trifft Technik}\n"
	result+= "\\date{\\today}\n\n"

	result+= "\\setkomavar{subject}{%s}\n" % subject
	result+= "\\setkomavar{toname}{%s %s}\n" % (userinfo["firstname"], userinfo["lastname"])
	result+= "\\setkomavar{toaddress}{%s\\newline\\newline\\textbf{%d %s}}\n\n" % (userinfo["street"], userinfo["plz"], userinfo["city"])

	result+= "\\begin{document}\n"
	result+= "\t\\begin{letter}{}\n"

	if userinfo["gender"] == "masculinum":
		result+= "\t\t\\opening{Sehr geehrter Herr %s,}\n\n" % userinfo["lastname"]
	elif userinfo["gender"] == "femininum":
		result+= "\t\t\\opening{Sehr geehrte Frau %s,}\n\n" % userinfo["lastname"]
	else:
		result+= "\t\t\\opening{Sehr geehrte/r Frau/Herr %s,}\n\n" % userinfo["lastname"]

	result+= "\t\twir erlauben uns, Ihnen für den Verzehr von Speisen und Getränken wie folgt zu berechnen:\n\n"

	result += "\t\t\\begin{footnotesize}\n"
	result += "\t\t\t\\begin{longtable}{|l|l|l|l|}\n"
	result += "\t\t\t\t\\hline\n"
	result += "\t\t\t\tDatum		& Uhrzeit	& Artikel	& Preis\\\\\n"
	result += "\t\t\t\t\\hline\n"

	lastdate = ""
	total = 0
	for row in get_invoice_data(user, start, stop):
		total += row["price"]

		if lastdate != row["date"]:
			result += "\t\t\t\t%s\t& %s\t& %s\t& %d,%02d Euro\\\\\n" % (row["date"], row["time"], row["product"], row["price"] / 100, row["price"] % 100)
			lastdate = row["date"]
		else:
			result += "\t\t\t\t%s\t& %s\t& %s\t& %d,%02d Euro\\\\\n" % ("           ", row["time"], row["product"], row["price"] / 100, row["price"] % 100)

	result += "\t\t\t\t\\hline\n"
	result += "\t\t\t\t\\multicolumn{3}{|l|}{Summe:} & %d,%02d Euro\\\\\n" % (total / 100, total % 100)
	result += "\t\t\t\t\\hline\n"
	result += "\t\t\t\\end{longtable}\n"
	result += "\t\t\\end{footnotesize}\n\n"

	result += "\t\tUmsatzsteuer wird nicht erhoben, da Kreativität trifft Technik e.V. als Kleinunternehmen\n"
	result += "\t\tder Regelung des § 19 Abs. 1 UStG unterfällt.\n\n"

	result += "\t\t\\closing{Mit freundlichen Grüßen}\n\n"

	result += "\t\\end{letter}\n"
	result += "\\end{document}"

	return result

def generate_invoice_text(user, title, subject, start=0, stop=0):
	userinfo = get_user_info(user)
	result = ""

	if userinfo["gender"] == "masculinum":
		result+= "Sehr geehrter Herr %s,\n\n" % userinfo["lastname"]
	elif userinfo["gender"] == "femininum":
		result+= "Sehr geehrte Frau %s,\n\n" % userinfo["lastname"]
	else:
		result+= "Sehr geehrte/r Frau/Herr %s,\n\n" % userinfo["lastname"]

	result+= "wir erlauben uns, Ihnen für den Verzehr von Speisen und Getränken wie folgt zu berechnen:\n\n"

	lastdate = ""
	total = 0
	namelength = 0
	for row in get_invoice_data(user, start, stop):
		if len(row["product"]) > namelength:
			namelength = len(row["product"])

	result += "+------------+----------+-" + namelength * "-" + "-+----------+\n"
	result += "| Datum      | Uhrzeit  | Artikel" + (namelength - len("Artikel")) * " " + " | Preis    |\n"
	result += "+------------+----------+-" + namelength * "-" + "-+----------+\n"
	for row in get_invoice_data(user, start, stop):
		total += row["price"]

		if lastdate != row["date"]:
			result += "| %s | %s | %s | %3d,%02d € |\n" % (row["date"], row["time"], row["product"] + (namelength - len(row["product"])) * " ", row["price"] / 100, row["price"] % 100)
			lastdate = row["date"]
		else:
			result += "| %s | %s | %s | %3d,%02d € |\n" % ("          ", row["time"], row["product"] + (namelength - len(row["product"])) * " ", row["price"] / 100, row["price"] % 100)
	result += "+------------+----------+-" + namelength * "-" + "-+----------+\n"
	result += "| Summe:                  " + namelength * " " + " | %3d,%02d € |\n" % (total / 100, total % 100)
	result += "+-------------------------" + namelength * "-" + "-+----------+\n\n"

	result += "Umsatzsteuer wird nicht erhoben, da Kreativität trifft Technik e.V. als Kleinunternehmen\n"
	result += "der Regelung des § 19 Abs. 1 UStG unterfällt.\n\n"

	return result

def generate_mail(receiver, subject, message, pdfdata, cc = None):
	msg = MIMEMultipart()
	msg["From"] = "KtT Shop System <shop@kreativitaet-trifft-technik.de>"

	try:
		if receiver.encode("ascii"):
			msg["To"] = receiver
	except UnicodeError:
		msg["To"] = Header(receiver, 'utf-8')

	if cc != None:
		msg["Cc"] = cc
	msg["Subject"] = Header(subject, 'utf-8')
	msg.preamble = "Please use a MIME aware email client!"

	msg.attach(MIMEText(message, 'plain', 'utf-8'))

	if pdfdata is not None:
		pdf = MIMEApplication(pdfdata, 'pdf')
		pdf.add_header('Content-Disposition', 'attachment', filename = 'rechnung.pdf')
		msg.attach(pdf)

	return msg

def generate_pdf(data):
	rubber = subprocess.Popen("rubber-pipe -d", shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
	pdf, stderr = rubber.communicate(input=data.encode('utf-8'))
	return pdf

def send_mail(mail, receiver):
	server = smtplib.SMTP(SMTPSERVERNAME, SMTPSERVERPORT)
	server.starttls()
	server.login(SMTPSERVERUSER, SMTPSERVERPASS)
	maildata = mail.as_string()
	server.sendmail(mail["From"], receiver, maildata)
	server.quit()

def get_users_with_purches(start, stop):
	result = []

	connection = sqlite3.connect('shop.db')
	c = connection.cursor()

	c.execute("SELECT user FROM purchases WHERE timestamp >= ? AND timestamp <= ? GROUP BY user ORDER BY user;", (start,stop))

	for row in c:
		result.append(row[0])

	c.close()

	return result

def daily(timestamp = time.time()):
	requested = datetime.datetime.fromtimestamp(timestamp)

	# timestamps for previous day
	dstop = requested.replace(hour = 8, minute = 0, second = 0) - datetime.timedelta(seconds = 1)
	dstart = requested.replace(hour = 8, minute = 0, second = 0) - datetime.timedelta(days = 1)
	if dstop > requested:
		dstop -= datetime.timedelta(days = 1)
		dstart -= datetime.timedelta(days = 1)
	stop = int(dstop.strftime("%s"))
	start = int(dstart.strftime("%s"))

	title = "Getränke Rechnung %04d-%02d-%02d" % (dstart.year, dstart.month, dstart.day)
	subject = "Getränke Zwischenstand %02d.%02d.%04d %02d:%02d Uhr bis %02d.%02d.%04d %02d:%02d Uhr" % (dstart.day, dstart.month, dstart.year, dstart.hour, dstart.minute, dstop.day, dstop.month, dstop.year, dstop.hour, dstop.minute)

	for user in get_users_with_purches(start, stop):
		userinfo = get_user_info(user)
		if userinfo is not None:
			receiver = "%s %s <%s>" % (userinfo["firstname"], userinfo["lastname"], userinfo["email"])
			tex  = generate_invoice_tex(user, title, subject, start, stop)
			msg  = generate_invoice_text(user, title, subject, start, stop)
			pdf  = generate_pdf(tex)
			mail = generate_mail(receiver, title, msg, pdf)
			send_mail(mail, userinfo["email"])
			print("Sent invoice to", userinfo["firstname"], userinfo["lastname"])
		else:
			print("Can't send invoice for missing user with the following id:", user)

def monthly(timestamp = time.time()):
	print("monthly invoice()")

def backup(timestamp = time.time()):
	print("backup()")

def get_stock_data():
	connection = sqlite3.connect('shop.db')
	c = connection.cursor()
	result = []

	c.execute("SELECT name,amount FROM products")

	for row in c:
		result.append((row[0],row[1]))

	c.close()

	return result

def gen_stock_asciitable():
	stock = get_stock_data()
	longest_name = 0
	longest_amount = 0
	asciitable = ""
	for element in stock:
		if len(element[0]) > longest_name:
			longest_name = len(element[0])
		if len(str(element[1])) > longest_amount:
			longest_amount = len(str(element[1]))

	asciitable = "+-" + longest_name * "-" + "-+-" + longest_amount * "-" + "-+\n"
	asciitable += "| " + "Produkt" + (longest_name - len("Produkt")) * " " + " | " + (longest_amount - 1) * " " + "#" + " |\n"
	asciitable += "+-" + longest_name * "-" + "-+-" + longest_amount * "-" + "-+\n"
	for product in stock:
		asciitable += "| " + product[0] + (longest_name - len(product[0])) * " " + " | " + (longest_amount - len(str(product[1]))) * " " + str(product[1]) + " |\n"
	asciitable += "+-" + longest_name * "-" + "-+-" + longest_amount * "-" + "-+\n"

	return asciitable

def gen_stock_mail():
	msg = MIMEMultipart()
	msg["From"] = "KtT Shop System <shop@kreativitaet-trifft-technik.de>"
	msg["To"] = "KtT Einkaufsteam <einkauf@kreativitaet-trifft-technik.de>"
	msg["Subject"] = Header("Aktueller Warenbestand", 'utf-8')
	msg.preamble = "Please use a MIME aware email client!"
	msg.attach(MIMEText(gen_stock_asciitable(), 'plain', 'utf-8'))
	return msg

def weekly():
	send_mail(gen_stock_mail(), "einkauf@kreativitaet-trifft-technik.de")

def backup():
	pass # TODO

if sys.argv[1] == "daily":
	daily()
elif sys.argv[1] == "weekly":
	weekly()
elif sys.argv[1] == "monthly":
	print("TODO: not yet implemented")
else:
	print("not supported!")
