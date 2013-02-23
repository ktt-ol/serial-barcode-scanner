#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import datetime, os, sys, subprocess, time, tempfile
from dbhelper import DB
from mailhelper import MAIL

from config import *

db = DB()
mailer = MAIL(SMTPSERVERNAME, SMTPSERVERPORT, SMTPSERVERUSER, SMTPSERVERPASS)

if sys.hexversion < 0x03000000:
	print("Please use Python 3.0 or newer!")
	sys.exit()

def get_timespan(type, timestamp = time.time()):
	requested = datetime.datetime.fromtimestamp(timestamp)

	if type == "previous day":
		# previous day, day from 08:00 - 7:59
		stop  = requested.replace(hour = 8, minute = 0, second = 0) - datetime.timedelta(seconds = 1)
		start = requested.replace(hour = 8, minute = 0, second = 0) - datetime.timedelta(days = 1)
		if stop > requested:
			stop  -= datetime.timedelta(days = 1)
			start -= datetime.timedelta(days = 1)
		return (start, stop)
	elif type == "previous month":
		# previous month, day from 00:00 - 23:59
		stop  = requested.replace(hour = 0, minute = 0, second = 0, day = 1) - datetime.timedelta(seconds = 1)
		start = stop.replace(day = 1, hour = 0, minute = 0, second = 0)
		return (start, stop)
	elif type == "current month":
		# current month, day from 00:00 - 23:59
		if requested.month == 12:
			stop = requested.replace(month = 0, year = requested.year + 1)
		else:
			stop = requested.replace(month = requested.month + 1)
		stop  = stop.replace(day = 1, hour = 0, minute = 0, second = 0) - datetime.timedelta(seconds = 1)
		start = requested.replace(day = 1, hour = 0, minute = 0, second = 0)
		return (start, stop)
	else:
		return None

def generate_pdf(data):
	rubber = subprocess.Popen("rubber-pipe -d", shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
	pdf, stderr = rubber.communicate(input=data.encode('utf-8'))
	return pdf

def generate_invoice_tex(user, title, subject, start=0, stop=0, temporary=False):
	userinfo = db.get_user_info(user)

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
	result += "\t\t\t\\begin{longtable}{|p{2cm}|p{1.8cm}|p{5cm}|p{2cm}|}\n"
	result += "\t\t\t\t\\hline\n"
	result += "\t\t\t\t\\textbf{Datum} & \\textbf{Uhrzeit}	& \\textbf{Artikel} & \\textbf{Preis}\\\\\n"
	result += "\t\t\t\t\\hline\n"
	result += "\\endhead\n"
	result += "\t\t\t\t\\hline\n"
	result += "\\endfoot\n"

	lastdate = ""
	total = 0
	for row in db.get_invoice_data(user, start, stop):
		total += row["price"]

		row["product"] = row["product"].replace("&", "\\&")

		if lastdate != row["date"]:
			result += "\t\t\t\t%s\t& %s\t& %s\t& \\EUR{%d,%02d}\\\\\n" % (row["date"], row["time"], row["product"], row["price"] / 100, row["price"] % 100)
			lastdate = row["date"]
		else:
			result += "\t\t\t\t%s\t& %s\t& %s\t& \\EUR{%d,%02d}\\\\\n" % ("           ", row["time"], row["product"], row["price"] / 100, row["price"] % 100)

	result += "\t\t\t\t\\hline\n"
	result += "\t\t\t\t\\multicolumn{3}{|l|}{Summe:} & \\EUR{%d,%02d}\\\\\n" % (total / 100, total % 100)
	result += "\t\t\t\\end{longtable}\n"
	result += "\t\t\\end{footnotesize}\n\n"

	result += "\t\tUmsatzsteuer wird nicht erhoben, da Kreativität trifft Technik e.V. als Kleinunternehmen\n"
	result += "\t\tder Regelung des § 19 Abs. 1 UStG unterfällt.\n\n"

	if temporary is True:
		result += "\t\tBei dieser Abrechnung handelt es sich lediglich um einen Zwischenstand. Die\n"
		result += "\t\tHauptrechnung wird einmal monatlich getrennt zugestellt und der Gesamtbetrag\n"
		result += "\t\twird dann vom angegebenen Bankkonto eingezogen.\n\n"
	else:
		result += "\t\tDer Gesamtbetrag wird in 10 Tagen von dem angegebenen Bankkonto\n"
		result += "\t\teingezogen.\n\n"

	result += "\t\t\\closing{Mit freundlichen Grüßen}\n\n"

	result += "\t\\end{letter}\n"
	result += "\\end{document}"

	return result

def generate_invoice_text(user, title, subject, start=0, stop=0, temporary=False):
	userinfo = db.get_user_info(user)
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
	for row in db.get_invoice_data(user, start, stop):
		if len(row["product"]) > namelength:
			namelength = len(row["product"])

	result += " +------------+----------+-" + namelength * "-" + "-+----------+\n"
	result += " | Datum      | Uhrzeit  | Artikel" + (namelength - len("Artikel")) * " " + " | Preis    |\n"
	result += " +------------+----------+-" + namelength * "-" + "-+----------+\n"
	for row in db.get_invoice_data(user, start, stop):
		total += row["price"]

		if lastdate != row["date"]:
			result += " | %s | %s | %s | %3d,%02d € |\n" % (row["date"], row["time"], row["product"] + (namelength - len(row["product"])) * " ", row["price"] / 100, row["price"] % 100)
			lastdate = row["date"]
		else:
			result += " | %s | %s | %s | %3d,%02d € |\n" % ("          ", row["time"], row["product"] + (namelength - len(row["product"])) * " ", row["price"] / 100, row["price"] % 100)
	result += " +------------+----------+-" + namelength * "-" + "-+----------+\n"
	result += " | Summe:                  " + namelength * " " + " | %3d,%02d € |\n" % (total / 100, total % 100)
	result += " +-------------------------" + namelength * "-" + "-+----------+\n\n"

	result += "Umsatzsteuer wird nicht erhoben, da Kreativität trifft Technik e.V. als Kleinunternehmen\n"
	result += "der Regelung des § 19 Abs. 1 UStG unterfällt.\n\n"

	if temporary is True:
		result += "Bei dieser Abrechnung handelt es sich lediglich um einen Zwischenstand. Die\n"
		result += "Hauptrechnung wird einmal monatlich getrennt zugestellt und der Gesamtbetrag\n"
		result += "wird dann vom angegebenen Bankkonto eingezogen.\n\n"

		dstop, dstart = get_timespan("current month")
		start         = int(dstop.strftime("%s"))
		stop          = int(dstart.strftime("%s"))
		monthprice    = db.get_invoice_amount(user, start, stop)

		result += "Der Gesamtbetrag für den aktuellen Monat beträgt bisher: %3d,%02d €\n\n" % (monthprice / 100, monthprice % 100)
	else:
		result += "Der Gesamtbetrag wird in 10 Tagen von dem angegebenen Bankkonto\n"
		result += "eingezogen.\n\n"

	return result

def daily(timestamp = time.time()):
	# timestamps for previous day
	dstart, dstop = get_timespan("previous day", timestamp)
	stop  = int(dstop.strftime("%s"))
	start = int(dstart.strftime("%s"))

	title = "Getränkerechnung %04d-%02d-%02d" % (dstart.year, dstart.month, dstart.day)
	subject = "Getränke-Zwischenstand %02d.%02d.%04d %02d:%02d Uhr bis %02d.%02d.%04d %02d:%02d Uhr" % (dstart.day, dstart.month, dstart.year, dstart.hour, dstart.minute, dstop.day, dstop.month, dstop.year, dstop.hour, dstop.minute)

	for user in db.get_users_with_purchases(start, stop):
		userinfo = db.get_user_info(user)
		if userinfo is not None:
			receiver = ("%s %s" % (userinfo["firstname"], userinfo["lastname"]), userinfo["email"])
			msg  = generate_invoice_text(user, title, subject, start, stop, True)
			mail = mailer.generate_mail(receiver, title, msg, None, timestamp)
			mailer.send_mail(mail, userinfo["email"])
		else:
			print("Can't send invoice for missing user with the following id:", user)

def monthly(timestamp = time.time()):
	# timestamps for previous month
	dstart, dstop = get_timespan("previous month", timestamp)
	stop   = int(dstop.strftime("%s"))
	start  = int(dstart.strftime("%s"))

	title = "Getränkerechnung %04d/%02d" % (dstart.year, dstart.month)
	number = 0

	invoices = {}
	invoicedata = []

	for user in db.get_users_with_purchases(start, stop):
		number += 1
		subject = "Rechnung Nr. %04d%02d5%03d" % (dstart.year, dstart.month, number)
		userinfo = db.get_user_info(user)
		if userinfo is not None:
			receiver = ("%s %s" % (userinfo["firstname"], userinfo["lastname"]), userinfo["email"])
			tex  = generate_invoice_tex(user, title, subject, start, stop, False)
			msg  = generate_invoice_text(user, title, subject, start, stop, False)
			pdf  = generate_pdf(tex)
			invoices["%04d%02d5%03d_%s_%s.pdf" % (dstart.year, dstart.month, number, userinfo["firstname"], userinfo["lastname"])] = pdf
			amount = db.get_invoice_amount(user, start, stop)
			invoicedata.append({"userid": user, "lastname": userinfo["lastname"], "firstname": userinfo["firstname"], "invoiceid": "%04d%02d5%03d" % (dstart.year, dstart.month, number), "amount": amount})
			mail = mailer.generate_mail(receiver, title, msg, pdf, timestamp)
			mailer.send_mail(mail, userinfo["email"])
			print("Sent invoice to", userinfo["firstname"], userinfo["lastname"])
		else:
			print("Can't send invoice for missing user with the following id:", user)

	csvinvoicedata = ""
	for entry in invoicedata:
		csvinvoicedata += "%d,%s,%s,%s,%d.%02d\n" % (entry["userid"], entry["lastname"], entry["firstname"], entry["invoiceid"], entry["amount"] / 100, entry["amount"] % 100)
	invoices["invoicedata.csv"] = csvinvoicedata

	mail = mailer.generate_mail(("Schatzmeister", "schatzmeister@kreativitaet-trifft-technik.de"),
		"Rechnungen %04d%02d" % (dstart.year, dstart.month),
		None, invoices, timestamp)
	mailer.send_mail(mail, "schatzmeister@kreativitaet-trifft-technik.de")

def backup():
	timestamp = time.time()
	dt = datetime.datetime.fromtimestamp(timestamp)

	receiver=("KtT-Shopsystem Backups", "shop-backup@kreativitaet-trifft-technik.de")
	subject="Backup KtT-Shopsystem %04d-%02d-%02d %02d:%02d" % (dt.year, dt.month, dt.day, dt.hour, dt.minute)
	message="You can find a backup of 'shop.db' attached to this mail."
	dbfile = open('shop.db', 'rb')
	attachments={"shop.db": dbfile.read()}
	dbfile.close()

	msg = mailer.generate_mail(receiver, subject, message, attachments, timestamp)
	mailer.send_mail(msg, "shop-backup@kreativitaet-trifft-technik.de")

if sys.argv[1] == "daily":
	daily()
	backup()
elif sys.argv[1] == "monthly":
	monthly()
else:
	print("not supported!")
