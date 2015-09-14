### Build System
 * update Makefiles to use config.mk
 * create VAPI file for config.h
 * support "make install"

#### CORE
 * disallow buying for disabled users
 * support user discounts
 * remove hardcoded stuff from invoice and pdf-invoice
 * drop to user rights in all daemons if started as root user
  - [old code](https://github.com/ktt-ol/serial-barcode-scanner/commit/504cefec4a93a9b52fa9d25d6f353a4676485c43)

### frontend
 * add auto-logout

#### USERLIST-PDF
 * write new vala process, which generates a user list pdf using libcairobarcode

#### PRODUCTLIST-PDF
 * write new vala process, which generates a product list pdf using libcairobarcode
  - Version 1: EAN, Barcode, Name, Amount, Buying-Price
  - Version 2: EAN, Barcode, Name, Member-Price, Guest-Price

#### MAIL
 * add PGP support in mail script

#### MAIL-SERVICE
 * IMAP client, which is parsing incoming mails from shop@ktt-ol
 * interpret commands similar to the Debian Bug Tracker
 * authentication is done using PGP, only signed mails are accepted
 * support help command, which lists all supported commands
 * support restocking via mail
 * support requesting invoice data for own user
 * support requesting personal data
 * support password setup

#### WEB
 * Improve error message when adding an already existing EAN
 * Reimplement statistics, add cache (?)
 * Implement User Statistics
 * Support renaming products
 * Admin: support to disable/enable users
 * Admin: support to delete sales
 * Admin: support to add sales
 * Admin: support listing/adding/editing suppliers
 * Support generating a barcode userlist (USERLIST-PDF)
 * Support generating product price list (PRODUCTLIST-PDF)
 * Support generating shopping list (PRODUCTLIST-PDF)
 * Implement a more fine-grained authentication system
 * OpenID based login

#### LOG
 * implement log daemon
 * get logfile destination from config

#### DATABASE
 * check sqlite WAL mode
  - http://www.sqlite.org/wal.html
  - checkpoint operation for fsync

#### BACKUP
 * Git based backup service
  - using libgit2-glib
  - one commit per local session (login/logout)
  - one commit per web interface operation
  - uses name + email of the operating person
  - commit database
  - use diff textconv hook in the git repo

#### SQL
 * DISCOUNT table:
  - userid
  - start
  - stop
  - percent
 * USER_SETTINGS table
  - mail_mode (text, html or both)
  - audio_theme
 * REMOVED_SALES table
  - userid
  - product
  - sale_time
  - remover
  - removal_time
 * PRODUCT_NUTRITION_DATA table
  - product id
  - energy
  - sugar
  - ...
 * PRODUCT_DEPOSIT table
  - product id
  - deposit (0.08€, 0.15€)
 * PRODUCT_GROUPS table
  - group id
  - group name
 * PRODUCT_AMOUNT_TYPE table
  - amount type id
  - amount type name (Liter, Gramm, Kilogramm, ...)
 * PRODUCTS table
  - add group field referencing PRODUCT_GROUPS
  - add amount field (integer)
  - add amount type field (reference)
