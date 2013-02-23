#!/usr/bin/env python3
#-*- coding: utf-8 -*-
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication
from email.mime.text import MIMEText
from email.header import Header

import time, email.utils, smtplib

import sys

class MAIL(object):
	def __init__(self, server, port, username, password):
		self.__server = server
		self.__port = port
		self.__username = username
		self.__password = password
		pass

	def __format_addresses(self, addresses, header_name=None, charset=None):
		header=email.header.Header(charset=charset, header_name=header_name)
		for i, (name, addr) in enumerate(addresses):
			if i!=0:
				# add separator between addresses
				header.append(',', charset='us-ascii')
			# check if address name is a unicode or byte string in "pure" us-ascii
			try:
				# check id byte string contains only us-ascii chars
				name.encode('us-ascii')
			except UnicodeError:
				# Header will use "RFC2047" to encode the address name
				# if name is byte string, charset will be used to decode it first
				header.append(name, charset='utf-8')
				# here us-ascii must be used and not default 'charset'
				header.append('<%s>' % (addr,), charset='us-ascii')
			else:
				# name is a us-ascii byte string, i can use formataddr
				formated_addr=email.utils.formataddr((name, addr))
				# us-ascii must be used and not default 'charset'
				header.append(formated_addr, charset='us-ascii')
		return header

	def generate_mail(self, receiver, subject, message, attachments = None, timestamp=time.time(), cc = None):
		msg = MIMEMultipart()
		msg["From"] = "KtT-Shopsystem <shop@kreativitaet-trifft-technik.de>"
		msg["Date"] = email.utils.formatdate(timestamp, True)

		try:
			if receiver[0].encode("ascii"):
				msg["To"] = receiver[0] + " <" + receiver[1] + ">"
		except UnicodeError:
			msg["To"] = self.__format_addresses([receiver])

		if cc != None:
			msg["Cc"] = cc
		msg["Subject"] = Header(subject, 'utf-8')
		msg.preamble = "Please use a MIME aware email client!"

		msg.attach(MIMEText(message, 'plain', 'utf-8'))

		if isinstance(attachments, dict):
			for name, data in attachments.items():
				if name.endswith("pdf"):
					pdf = MIMEApplication(data, 'pdf')
					pdf.add_header('Content-Disposition', 'attachment', filename = name)
					msg.attach(pdf)
				if name.endswith("db"):
					file = MIMEApplication(data)
					file.add_header('Content-Disposition', 'attachment', filename = name)
					msg.attach(file)
				else:
					txt = MIMEText(data, 'plain', 'utf-8')
					txt.add_header('Content-Disposition', 'attachment', filename = name)
					msg.attach(txt)
		elif attachments is not None:
			pdf = MIMEApplication(attachments, 'pdf')
			pdf.add_header('Content-Disposition', 'attachment', filename = 'rechnung.pdf')
			msg.attach(pdf)

		return msg

	def send_mail(self, mail, receiver):
		server = smtplib.SMTP(self.__server, self.__port)
		server.starttls()
		if self.__username != "":
			server.login(self.__username, self.__password)
		maildata = mail.as_string()
		server.sendmail(mail["From"], receiver, maildata)
		server.quit()
