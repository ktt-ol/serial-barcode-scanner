This is the Shop System of Oldenburg's Hackspace Mainframe.

The software has been developed as a credit based system for members of the
hackspace. The system depends on a cheap serial barcode scanner, which is used
to establish user sessions (by scanning CODE39 based user codes) and buying
products (by scanning their EAN). The members receive an invoice at the end of
the month, which is also send to the hackspace's treasurer for further processing.

Since the user barcodes do not contain any advanced authentication mechanism,
security is established by sending daily mails in addition to the monthly
invoice mail. The daily mail (which is only sent if something has been bought)
lists all products bought by the member on this day and the current total sum
for the month.

The system provides the following features:
 * time shifted daily mails (08:00-07:59 of the following day), so that there
   is a lower chance of purchases from one visit being split over two mails.
 * native rendering of PDF invoices using Cairo (fast & lightweight)
 * invoice mails are sent using text/plain and text/html
 * support for sending a database backup to a mail address
 * curses based user interface
 * basic audio support

The system administration is done using a simple web interface, which provides
support for the following tasks:
 * adding information about new products
 * restocking products
 * changing selling prices of products
 * updating the user database by importing a userlist.csv
   (regularly generated by our treasurer)

The system consists of multiple daemons written in Vala, which communicate
with each other using DBus.

Build Dependencies:
 * apt install build-essential valac libesmtp-dev libgpgme11-dev libncursesw5-dev libncurses5-dev libgee-0.8-dev libgmime-2.6-dev libarchive-dev libgstreamer1.0-dev libgtk2.0-dev librsvg2-dev libsoup2.4-dev libsqlite3-dev libpango1.0-dev libssl-dev dbus-x11 mdbus2 policykit-1

Additional runtime dependencies:
 * apt install fonts-lmodern gstreamer1.0-alsa gstreamer1.0-plugins-base

Suggested runtime dependencies:
 * apt install sqlite3

== Installation ==

You can install to different location or use a different username,
but you need to modify a few things.

=== Git Setup ===

 * adduser "shop" with homedir in /home/shop
 * clone git repository into /home/shop/serial-barcode-scanner

=== Build the Software ===

 * ./configure
 * make shop.db
 * make

=== DBus Configuration ===

 * cd dbus
 * make
 * sudo make install

=== Systemd ===

 * cd systemd
 * sudo make install

=== Configuration ===

 * mv example.cfg config.cfg
 * edit config.cfg

=== Database ===

 * Create user
 `sqlite3 shop.db "INSERT INTO users (id, email, firstname, lastname) VALUES (-1, 'vorstand@diyww.de', 'Vorstand', 'DIYWW');"`
  `sqlite3 shop.db "INSERT INTO users (id, email, firstname, lastname) VALUES (0, 'shop-gast@diyww.de', 'GAST', 'GAST');"`
  `sqlite3 shop.db "INSERT INTO users (id, email, firstname, lastname) VALUES (1, 'test@tester', 'Firstname', 'Lastname');"`
 * Setup user password
   `mdbus2 -s io.mainframe.shopsystem.Database /io/mainframe/shopsystem/database io.mainframe.shopsystem.Database.SetUserPassword 1 "password"`
   `sqlite3 shop.db "UPDATE authentication set superuser = 1,auth_users = 1, auth_products = 1,auth_cashbox = 1 where user = 1";`
 * Demo Data
 `sqlite3 shop.db "INSERT INTO categories (name) VALUES ('Getränke')";`
 `sqlite3 shop.db "INSERT INTO supplier (name,city,postal_code,street,phone,website) VALUES ('Demo Lieferant','Musterstadt','12345','Musterstraße 5','+49 1234 56789','https://www.ktt.de')";`

== Customize Your Shop ==

Edit the Logo in the logo.txt File.
A helpful tool you will found here [http://patorjk.com/software/taag/](http://patorjk.com/software/taag/)
