#!/usr/bin/env python3
import csv, sqlite3, sys

title_to_gender = {
	"m": "masculinum",
	"w": "femininum"
}

data = csv.reader(open(sys.argv[1], 'r', encoding='utf-8'), delimiter=';', quotechar='"')
connection = sqlite3.connect('shop.db')
c = connection.cursor()

# skip header line
data.__next__()

for row in data:
	print(row)
	gender = title_to_gender.get(row[7], "unknown")
	t = (int(row[0]), row[1], row[2], row[3], gender, row[4], int(row[5]), row[6])
	c.execute("INSERT OR REPLACE INTO users ('id', 'email', 'firstname', 'lastname', 'gender', 'street', 'plz', 'city') VALUES (?, ?, ?, ?, ?, ?, ?, ?);", t)

connection.commit()
c.close()
