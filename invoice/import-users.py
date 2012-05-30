#!/usr/bin/env python3
import csv, sqlite3, sys

title_to_gender = {
	"Herr": "masculinum",
	"Frau": "femininum"
}

data = csv.reader(open(sys.argv[1], 'r', encoding='iso-8859-1'), delimiter=';', quotechar='"')
connection = sqlite3.connect('shop.db')
c = connection.cursor()

# skip header line
data.__next__()

for row in data:
	print(row)
	gender = title_to_gender.get(row[2], "unknown")
	t = (int(row[0]), row[1], row[3], row[4], gender, row[5], int(row[6]), row[7])
	c.execute("INSERT OR REPLACE INTO users ('id', 'email', 'firstname', 'lastname', 'gender', 'street', 'plz', 'city') VALUES (?, ?, ?, ?, ?, ?, ?, ?);", t)

connection.commit()
c.close()
