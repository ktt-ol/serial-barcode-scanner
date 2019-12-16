<a href="https://travis-ci.org/ktt-ol/serial-barcode-scanner">
	<img align="right" alt="Build Status" src="https://travis-ci.org/ktt-ol/serial-barcode-scanner.svg?branch=master" />
</a>

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

# Building dependencies

 * sudo apt install build-essential

# Runtime dependencies

 * sudo apt install mosquitto-clients vbetool alsaplayer-text alsa-utils

# Building

 * Install dependencies listed by `dpkg-checkbuilddeps` via `sudo apt install`
 * Build the package with `dpkg-buildpackage -b --no-sign`

# Install

 * `apt install ../shopsystem_0.x_arch.deb`

# Configuration

 * Edit as root: `/etc/shopsystem/config.ini`

# Database

To use the web interface, you need add a super user first. Further
user can then be imported using the web interface. Creation of the
initial super user is done with the following commands:

 * `sudo busctl --system call io.mainframe.shopsystem.Database /io/mainframe/shopsystem/database io.mainframe.shopsystem.Database UserReplace "(issssssssxbbsas)" "<userid>" "<firstname>" "<lastname>" "<email>" "<gender>" "<street>" "<postcode>" "<city>" "" 0 0 0 "" 0`
 * `sudo busctl --system call io.mainframe.shopsystem.Database /io/mainframe/shopsystem/database io.mainframe.shopsystem.Database SetUserPassword "is" "<userid>" "<password>"`
 * `sudo busctl --system call io.mainframe.shopsystem.Database /io/mainframe/shopsystem/database io.mainframe.shopsystem.Database SetUserAuth "(ibbbb)" "<userid>" 1 1 1 1`

Unfortunately the web interface does not yet allow do add categories
or suppliers. You can use the following queries to add this before
adding products:

 * `sudo busctl --system call io.mainframe.shopsystem.Database /io/mainframe/shopsystem/database io.mainframe.shopsystem.Database AddCategory "s" "Getränke"`
 * `sudo busctl --system call io.mainframe.shopsystem.Database /io/mainframe/shopsystem/database io.mainframe.shopsystem.Database AddSupplier "ssssss" "Demo Lieferant" "12345" "Musterstadt" "Musterstr. 5" "+49 1234 56789" "https://www.example.org"`

It's also possible to directly access the database. While there are
some triggers to keep the database in a sensible state, please be
careful with direct database transactions. For accessing the database
in write mode, you need to kill the shopsystem database process first.
It will be restarted by any process, that needs the database DBus API.

 * `sudo pkill -15 shop-database`
 * `sqlite3 /path/to/shopsystem.db` - use `sudo` if necessary

# Display on / off via MQTT

You can control display power via MQTT by configuring the MQTT settings (i.e. BROKER, TOPIC) in the config file.

# Customize Your Shop

Edit the Logo in the logo.txt File.
Add sounds to `/usr/share/shopsystem/sounds`
A helpful tool you will found here [http://patorjk.com/software/taag/](http://patorjk.com/software/taag/)

# Some Vala resources

* https://wiki.gnome.org/Projects/Vala/ValaForJavaProgrammers
* https://valadoc.org/
* https://getbootstrap.com/2.3.2/
