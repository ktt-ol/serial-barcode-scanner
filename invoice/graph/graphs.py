#!/usr/bin/python
# -*- coding: utf-8 -*-
import cairoplot, datetime, sqlite3, time

def TortendiagramUser():
	data = {}

	connection = sqlite3.connect('shop.db')
	c = connection.cursor()
	c.execute("SELECT users.id, SUM(prices.memberprice) FROM users, purchases, prices " +
			  "WHERE users.id = purchases.user AND purchases.product = prices.product GROUP BY users.id")
	for row in c:
		data["%d (%d.%d Euro)" %(row[0], row[1] / 100, row[1] % 100)] = row[1]
	c.close()

	cairoplot.pie_plot("tortendiagram", data, 640, 480)

def TortendiagramUserRanking():
	data = {}
	names = []

	connection = sqlite3.connect('shop.db')
	c = connection.cursor()
	c.execute("SELECT users.firstname, users.lastname, SUM(prices.memberprice) FROM users, purchases, prices " +
			  "WHERE users.id = purchases.user AND purchases.product = prices.product GROUP BY users.id")
	for row in c:
		data["%s %s (%d.%d Euro)" % (row[0], row[1], row[2] / 100, row[2] % 100)] = row[2]
	c.close()

	count=0
	sorted_data = []
	for key, value in sorted(data.iteritems(), key=lambda (k,v): (v,k), reverse=True):
		sorted_data.append(value)
		names.append(key)
		count+=1
		if count >= 10:
			break

	cairoplot.horizontal_bar_plot("ranking", sorted_data, 640, 480, y_labels = names, rounded_corners = True, grid = True)

def TortendiagramProduct():
	data = {}

	connection = sqlite3.connect('shop.db')
	c = connection.cursor()
	c.execute("SELECT products.name, SUM(1) FROM products, purchases " +
			  "WHERE products.id = purchases.product GROUP BY products.id")
	for row in c:
		data[row[0]] = row[1]
	c.close()

	cairoplot.pie_plot("tortendiagram2", data, 640, 480)

def Lagerbestand(category):
	data = {}
	translation = {}

	day = 24 * 60 * 60
	now = int(time.time())
	
	dates = []
	dt = datetime.datetime.fromtimestamp(now)
	dates.append("%04d-%02d-%02d" % (dt.year, dt.month, dt.day))

	colors = [
		"black",
		"red",
		"green",
		"blue",
		"orange",
		(117/255.0, 255/255.0, 20/255.0),
		(216/255.0, 20/255.0, 255/255.0),
		(204/255.0, 153/255.0, 0/255.0),
		(0/255.0, 204/255.0, 255/255.0),
		(153/255.0, 77/255.0, 0/255.0),
		(128/255.0, 0/255.0, 128/255.0),
		(204/255.0, 0/255.0, 0/255.0),
		(0/255.0, 0/255.0, 102/255.0),
		"yellow",
	]

	connection = sqlite3.connect('shop.db')
	c = connection.cursor()
	query = ""

	if category == "getraenke":
		query = "name LIKE '%Mate%' OR name LIKE '%Coca Cola%' OR name LIKE '%Vilsa%' OR name = 'Fanta' OR name = 'Sprite'"
	elif category == "haribo":
		query = "name LIKE '%Haribo%'"
	elif category == "riegel":
		query = "name LIKE '%KitKat%' OR name = 'Lion' OR name LIKE '%Snickers%' OR name = 'Mars' OR name = 'Twix' OR name = 'Duplo'"
	elif category == "other":
		query = "name LIKE '%Gouda%' OR name LIKE '%Chipsfrisch%' OR name LIKE '%Sesamsticks%'"
	elif category == "schoko":
		query = "name = 'Ü-Ei' OR name LIKE '%Tender%' OR name = 'Knoppers' OR name LIKE '%m&m%'"
	else:
		return

	c.execute("SELECT name, amount, id FROM products WHERE (%s) AND amount > 0" % query);

	for row in c:
		data[row[0]] = [int(row[1])]
		translation[row[2]] = row[0]
	
	current = now
	currentid = 1
	while current > (now - 21 * day):
		for k, v in data.iteritems():
			data[k].append(v[-1])

		dt = datetime.datetime.fromtimestamp(current - day)
		dates.append("%04d-%02d-%02d" % (dt.year, dt.month, dt.day))

		c.execute("SELECT name, SUM(restock.amount) FROM products, restock WHERE products.id = restock.product AND timestamp > ? AND timestamp < ? GROUP BY name", (current - day, current));
		for row in c:
			if row[0] in data:
				data[row[0]][currentid] -= row[1]
		c.execute("SELECT name, SUM(1) FROM products, purchases WHERE products.id = purchases.product AND timestamp > ? AND timestamp < ? GROUP BY name", (current - day, current));
		for row in c:
			if row[0] in data:
				data[row[0]][currentid] += row[1]

		current -= day
		currentid += 1
	
	for k, v in data.iteritems():
		data[k].reverse()
	dates.reverse()

	c.close()
	cairoplot.dot_line_plot("lagerbestand_%s" % category, data, 640, 480, series_colors = colors, x_labels = dates, y_title = "Anzahl", axis=True, grid=True, series_legend = True)


data = [ "getraenke", "haribo", "riegel", "other", "schoko" ]

TortendiagramUser()
TortendiagramProduct()
TortendiagramUserRanking()

for x in data:
	Lagerbestand(x)
