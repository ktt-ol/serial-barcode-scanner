/* Copyright 2012-2013, Sebastian Reichel <sre@ring0.de>
 * Copyright 2017-2018, Johannes Rudolph <johannes.rudolph@gmx.com>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

[DBus (name = "io.mainframe.shopsystem.ScannerSession")]
public class ScannerSessionImplementation {
  private int user = 0;
  private string name = _("Guest");
  private bool logged_in = false;
  private bool disabled = false;
  private string theme = "beep";

  private Database db;
  private AudioPlayer audio;
  private InputDevice devScanner;
  private InputDevice devRfid;
  private Cli cli;

  private ScannerSessionState state = ScannerSessionState.READY;
  private DetailedProduct[] shoppingCart = {};

  public signal void msg(MessageType type, string message);
  public signal void msg_overlay(string title, string message);

  public ScannerSessionImplementation() {
    try {
      db       = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Database", "/io/mainframe/shopsystem/database");
      devScanner = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.InputDevice", "/io/mainframe/shopsystem/device/scanner");
      devRfid = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.InputDevice", "/io/mainframe/shopsystem/device/rfid");
      cli      = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Cli", "/io/mainframe/shopsystem/cli");
      audio    = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.AudioPlayer", "/io/mainframe/shopsystem/audio");

      devScanner.received_barcode.connect(handle_barcode);
      devRfid.received_barcode.connect(handle_barcode);
      cli.received_barcode.connect(handle_barcode);
    } catch(IOError e) {
      error(_("IO Error: %s\n"), e.message);
    }
  }

  private void send_message(MessageType type, string format, ...) {
    var arguments = va_list();
    var message = format.vprintf(arguments);

    msg(type, message);
  }

  private bool login(int user) throws DBusError, IOError {
    this.user      = user;
    if (user != 0) {
      try {
        this.name      = db.get_username(user);
        this.disabled  = db.user_is_disabled(user);
      } catch(DatabaseError e) {
        send_message(MessageType.ERROR, _("Error (user=%d): %s"), user, e.message);
        return false;
      }
    } else {
      this.name = _("Guest");
      this.disabled = false;
    }

    this.logged_in = true;

    try {
      this.theme = db.get_user_theme(user, "");
      if (this.theme == "") {
        this.theme = audio.get_random_user_theme();
      }
    } catch(DatabaseError e) {
      this.theme = "beep";
    }

    return true;
  }

  private ScannerSessionCodeType getCodeType(string scannerdata) {
    if(scannerdata.has_prefix("USER ")){
      return ScannerSessionCodeType.USER;
    } else if(scannerdata == "GUEST") {
      return ScannerSessionCodeType.GUEST;
    } else if(scannerdata == "UNDO") {
      return ScannerSessionCodeType.UNDO;
    } else if(scannerdata == "LOGOUT") {
      return ScannerSessionCodeType.LOGOUT;
    } else if(scannerdata.length == 10) {
      return ScannerSessionCodeType.RFIDEM4100;
    } else if(scannerdata == "USERINFO") {
      return ScannerSessionCodeType.USERINFO;
    } else {
      //Handle EAN Code
      uint64 id = 0;
      scannerdata.scanf("%llu", out id);

      /* check if scannerdata has valid format */
      if(scannerdata != "%llu".printf(id) && scannerdata != "%08llu".printf(id) && scannerdata != "%013llu".printf(id)) {
        return ScannerSessionCodeType.UNKNOWN;
      }
      return ScannerSessionCodeType.EAN;
    }
  }

  private void play_audio(AudioType audioType) throws DBusError, IOError {
    switch (audioType) {
      case AudioType.ERROR:
        audio.play_system("error.ogg");
        break;
      case AudioType.LOGIN:
        audio.play_user(theme, "login");
        break;
      case AudioType.LOGOUT:
        audio.play_user(theme, "logout");
        break;
      case AudioType.PURCHASE:
        audio.play_user(theme, "purchase");
        break;
      case AudioType.INFO:
        audio.play_user(theme, "login");
        break;
    }
  }

  private ScannerResult handleReadyState(string scannerdata) throws DatabaseError, DBusError, IOError {
    ScannerSessionCodeType codeType = getCodeType(scannerdata);
    ScannerResult scannerResult = ScannerResult();
    switch (codeType) {
      case ScannerSessionCodeType.USER:
        int32 userid = int.parse(scannerdata.substring(5));
        if(login(userid)) {
          scannerResult.type = MessageType.INFO;
          scannerResult.message = _("Login: %s (%d)").printf(name, user);
          scannerResult.audioType = AudioType.LOGIN;
          shoppingCart = {};
          state = ScannerSessionState.USER;
        } else {
          scannerResult.type = MessageType.ERROR;
          scannerResult.message = _("Login failed (User ID = %d)").printf(userid);
          scannerResult.audioType = AudioType.ERROR;
          state = ScannerSessionState.READY;
        }
        return scannerResult;
      case ScannerSessionCodeType.GUEST:
        if(login(0)) {
          scannerResult.type = MessageType.INFO;
          scannerResult.message = _("Login as Guest");
          scannerResult.audioType = AudioType.LOGIN;
          shoppingCart = {};
          state = ScannerSessionState.USER;
        } else {
          scannerResult.type = MessageType.ERROR;
          scannerResult.message = _("Login failed (Guest)");
          scannerResult.audioType = AudioType.ERROR;
          state = ScannerSessionState.READY;
        }
        return scannerResult;
      case ScannerSessionCodeType.EAN:
        uint64 ean = 0;
        scannerdata.scanf("%llu", out ean);
        var p = DetailedProduct();
        try {
          p = db.get_product_for_ean(ean);
        } catch(IOError e) {
          scannerResult.type = MessageType.ERROR;
          scannerResult.message = _("Internal Error!");
          scannerResult.audioType = AudioType.ERROR;
          return scannerResult;
        } catch(DatabaseError e) {
          if(e is DatabaseError.PRODUCT_NOT_FOUND) {
            scannerResult.type = MessageType.ERROR;
            scannerResult.message = _("Error: unknown product: %llu").printf(ean);
            scannerResult.audioType = AudioType.ERROR;
          } else {
            scannerResult.type = MessageType.ERROR;
            scannerResult.message = _("Error: %s").printf(e.message);
            scannerResult.audioType = AudioType.ERROR;
          }
          return scannerResult;
        }

        var mprice = p.memberprice;
        var gprice = p.guestprice;
        var pname = p.name;

        scannerResult.type = MessageType.INFO;
        scannerResult.message = _("Article info: %s (Member: %s €, Guest: %s €").printf(@"$pname", @"$mprice", @"$gprice");
        scannerResult.audioType = AudioType.ERROR;
        state = ScannerSessionState.READY;
        return scannerResult;
      case ScannerSessionCodeType.RFIDEM4100:
          int user = db.get_userid_for_rfid(scannerdata);
          scannerResult.nextScannerdata = @"USER $user";
          return scannerResult;
      default:
	scannerResult.type = MessageType.ERROR;
        scannerResult.message = _("Error: %s").printf("you may have to be logged in");
        scannerResult.audioType = AudioType.ERROR;
        state = ScannerSessionState.READY;
        return scannerResult;
    }
  }

  private ScannerResult handleUserState(string scannerdata) throws DatabaseError, DBusError, IOError {
    ScannerSessionCodeType codeType = getCodeType(scannerdata);
    ScannerResult scannerResult = ScannerResult();
    switch (codeType) {
      case ScannerSessionCodeType.EAN:
        uint64 ean = 0;
        scannerdata.scanf("%llu", out ean);
        var p = DetailedProduct();
        try {
          p = db.get_product_for_ean(ean);
          } catch(IOError e) {
            scannerResult.type = MessageType.ERROR;
            scannerResult.message = _("Internal Error!");
            scannerResult.audioType = AudioType.ERROR;
            return scannerResult;
          } catch(DatabaseError e) {
            if(e is DatabaseError.PRODUCT_NOT_FOUND) {
              scannerResult.type = MessageType.ERROR;
              scannerResult.message = _("Error: unknown product: %llu").printf(ean);
              scannerResult.audioType = AudioType.ERROR;
            } else {
              scannerResult.type = MessageType.ERROR;
              scannerResult.message = _("Error: %s").printf(e.message);
              scannerResult.audioType = AudioType.ERROR;
            }
            return scannerResult;
          }

        shoppingCart += p;

        Price price = p.memberprice;

        if(user == 0){
          price = p.guestprice;
        }

        scannerResult.type = MessageType.INFO;
        scannerResult.message = _("Added to 🛒: %s (%s €)").printf(@"$(p.name)", @"$price");
        scannerResult.audioType = AudioType.PURCHASE;
        state = ScannerSessionState.USER;
        break;
      case ScannerSessionCodeType.UNDO:
        if(shoppingCart.length > 0){
          var removedProduct = shoppingCart[shoppingCart.length-1];
          shoppingCart = shoppingCart[0:shoppingCart.length-1];
          scannerResult.type = MessageType.INFO;
          scannerResult.message = _("Removed from 🛒: %s").printf(@"$(removedProduct.name)");
          scannerResult.audioType = AudioType.INFO;
        } else {
          scannerResult.type = MessageType.INFO;
          scannerResult.message = _("🛒 is empty");
          scannerResult.audioType = AudioType.ERROR;
        }
        break;
      case ScannerSessionCodeType.USERINFO:
	DateTime now = new DateTime.now_utc();
        int64 timestampNow = now.to_unix();
        int64 timestapFirstOfMonth = new DateTime.utc(now.get_year(),now.get_month(),1,0,0,0).to_unix();
	Price currentAmmount = db.get_user_invoice_sum(this.user, timestapFirstOfMonth, timestampNow);
        string currentMonth = new DateTime.now_utc().format("%B %Y");
        scannerResult.type = MessageType.INFO;
        scannerResult.message = ("userinfo: %s %s").printf(currentMonth,currentAmmount.to_string());
        scannerResult.audioType = AudioType.INFO;
        break;
      case ScannerSessionCodeType.LOGOUT:
        scannerResult = logout();
        break;
      case ScannerSessionCodeType.USER:
      case ScannerSessionCodeType.GUEST:
      case ScannerSessionCodeType.RFIDEM4100:
        /* Logout old user session (and buy articles) */
        scannerResult = logout();
        scannerResult.nextScannerdata = scannerdata;
        break;
    }

    return scannerResult;
  }

  private ScannerResult buyShoppingCard() throws DatabaseError, DBusError, IOError {
    ScannerResult scannerResult = ScannerResult();
    uint8 amountOfItems = 0;
    Price totalPrice = 0;
    uint8 i = 0;
    DetailedProduct p = DetailedProduct();
    for(i = 0; i < shoppingCart.length; i++) {
      p = shoppingCart[i];
      db.buy(user, p.ean);
      amountOfItems++;
      Price price = p.memberprice;
      if(user == 0) {
        price = p.guestprice;
      }
      totalPrice += price;
    }
    scannerResult.type = MessageType.INFO;
    scannerResult.message = @_("%s bought %d items for %s €").printf(@"$name", amountOfItems, @"$totalPrice");
    scannerResult.audioType = AudioType.INFO;
    return scannerResult;
  }

  private void handle_barcode(string scannerdata) {
    try {
      stdout.printf("scannerdata: %s\n", scannerdata);
      if(interpret(scannerdata))
        devScanner.blink(1000);
    } catch(DBusError e) {
      send_message(MessageType.ERROR, _("DBus Error: %s"), e.message);
    } catch(IOError e) {
      send_message(MessageType.ERROR, _("IO Error: %s"), e.message);
    } catch(DatabaseError e) {
      send_message(MessageType.ERROR, _("Database Error: %s"), e.message);
    }
  }

  private bool interpret(string scannerdata) throws DatabaseError, DBusError, IOError {
    ScannerResult scannerResult = ScannerResult();
    switch (state) {
      case ScannerSessionState.READY:
        scannerResult = handleReadyState(scannerdata);
        break;
      case ScannerSessionState.USER:
        scannerResult = handleUserState(scannerdata);
        break;
    }

    play_audio(scannerResult.audioType);
    send_message(scannerResult.type, scannerResult.message);
    if(scannerResult.nextScannerdata != null){
      interpret(scannerResult.nextScannerdata);
    }
    return true;
  }

  private ScannerResult logout() throws DatabaseError, DBusError, IOError {
    ScannerResult scannerResult = buyShoppingCard();
	scannerResult.audioType = AudioType.LOGOUT;
    logged_in = false;
    state = ScannerSessionState.READY;
    return scannerResult;
  }
}
