#!/usr/bin/env python3
#-*- coding: utf-8 -*-
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication
from email.mime.text import MIMEText
from email.header import Header

import time, email.utils, smtplib

class MAIL(object):
	def __init__(self, server, port, username, password):
		self.__server = server
		self.__port = port
		self.__username = username
		self.__password = password
		pass

	def generate_mail(self, receiver, subject, message, attachments = None, timestamp=time.time(), cc = None):
		msg = MIMEMultipart()
		msg["From"] = "KtT-Shopsystem <shop@kreativitaet-trifft-technik.de>"
		msg["Date"] = email.utils.formatdate(timestamp, True)

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
