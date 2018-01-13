/* Copyright 2012-2013, Sebastian Reichel <sre@ring0.de>
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
  private string name = "Guest";
  private bool logged_in = false;
  private bool disabled = false;
  private string theme = "beep";

  private Database db;
  private AudioPlayer audio;
  private InputDevice dev;
  private Cli cli;

  private ScannerSessionState state = ScannerSessionState.READY;
  private Array<?> userProductList = new Array<Product> ();

  public signal void msg(MessageType type, string message);
  public signal void msg_overlay(string title, string message);

  public ScannerSessionImplementation() {
    try {
      db       = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Database", "/io/mainframe/shopsystem/database");
      dev      = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.InputDevice", "/io/mainframe/shopsystem/device");
      cli      = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Cli", "/io/mainframe/shopsystem/cli");
      audio    = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.AudioPlayer", "/io/mainframe/shopsystem/audio");

      dev.received_barcode.connect(handle_barcode);
      cli.received_barcode.connect(handle_barcode);
    } catch(IOError e) {
      error("IOError: %s\n", e.message);
    }
  }

  private void send_message(MessageType type, string format, ...) {
    var arguments = va_list();
    var message = format.vprintf(arguments);

    msg(type, message);
  }

  private bool login(int user) throws IOError {
    this.user      = user;
    try {
      this.name      = db.get_username(user);
      this.disabled  = db.user_is_disabled(user);
    } catch(DatabaseError e) {
      send_message(MessageType.ERROR, "Error (user=%d): %s", user, e.message);
      return false;
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

  private ScannerSesseionCodeType getCodeType(string scannerdata){
    if(scannerdata.has_prefix("USER ")){
      return ScannerSesseionCodeType.USER;
    } else if(scannerdata == "GUEST") {
      return ScannerSesseionCodeType.GUEST;
    } else if(scannerdata == "UNDO") {
      return ScannerSesseionCodeType.UNDO;
    } else if(scannerdata == "LOGOUT") {
      return ScannerSesseionCodeType.LOGOUT;
    } else {
      //Handle EAN Code
      uint64 id = 0;
      scannerdata.scanf("%llu", out id);

      /* check if scannerdata has valid format */
      if(scannerdata != "%llu".printf(id) && scannerdata != "%08llu".printf(id) && scannerdata != "%013llu".printf(id)) {
        return ScannerSesseionCodeType.UNKNOWN;
      }
      return ScannerSesseionCodeType.EAN;
    }
  }

  private void play_audio(AudioType audioType){
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

  private ScannerResult handleReadyState(string scannerdata) throws DatabaseError, IOError{
    ScannerSesseionCodeType codeType = getCodeType(scannerdata);
    ScannerResult scannerResult = ScannerResult();
    switch (codeType) {
      case ScannerSesseionCodeType.USER:
          int32 userid = int.parse(scannerdata.substring(5));
          if(login(userid)) {
            scannerResult.type = MessageType.INFO;
            scannerResult.message = "Login: %s (%d)".printf(name, user);
            scannerResult.audioType = AudioType.LOGIN;
            userProductList = new Array<Product> ();
            state = ScannerSessionState.USER;
            return scannerResult;
          } else {
            scannerResult.type = MessageType.ERROR;
            scannerResult.message = "Login failed (User ID = %d)".printf(userid);
            scannerResult.audioType = AudioType.ERROR;
            state = ScannerSessionState.READY;
            return scannerResult;
          }
        break;
      case ScannerSesseionCodeType.GUEST:
        if(login(0)) {
          scannerResult.type = MessageType.INFO;
          scannerResult.message = "Login as GUEST";
          scannerResult.audioType = AudioType.LOGIN;
          userProductList = new Array<Product> ();
          state = ScannerSessionState.USER;
          return scannerResult;
        } else {
          scannerResult.type = MessageType.ERROR;
          scannerResult.message = "Login failed as GUEST";
          scannerResult.audioType = AudioType.ERROR;
          state = ScannerSessionState.READY;
          return scannerResult;
        }
        break;
      case ScannerSesseionCodeType.EAN:
        uint64 ean = 0;
        scannerdata.scanf("%llu", out ean);
        Product p = Product();
        try {
          p = db.get_product_for_ean(ean);
        } catch(IOError e) {
          scannerResult.type = MessageType.ERROR;
          scannerResult.message = "Internal Error!";
          scannerResult.audioType = AudioType.ERROR;
          return scannerResult;
        } catch(DatabaseError e) {
          if(e is DatabaseError.PRODUCT_NOT_FOUND) {
            scannerResult.type = MessageType.ERROR;
            scannerResult.message = "Error: unknown product: %llu".printf(ean);
            scannerResult.audioType = AudioType.ERROR;
          } else {
            scannerResult.type = MessageType.ERROR;
            scannerResult.message = "Error: %s".printf(e.message);
            scannerResult.audioType = AudioType.ERROR;
          }
          return scannerResult;
        }

        var mprice = p.memberprice;
        var gprice = p.guestprice;
        scannerResult.type = MessageType.INFO;
        scannerResult.message = @"article info: $name (Member: $mprice €, Guest: $gprice €)";
        scannerResult.audioType = AudioType.ERROR;
        state = ScannerSessionState.READY;
        return scannerResult;
        break;
      default:
        state = ScannerSessionState.READY;
        return scannerResult;
        break;
    }
  }

  private ScannerResult buyShoppingCard() {
    ScannerResult scannerResult = ScannerResult();
    uint8 amountOfItems = 0;
    double totalPrice = 0.0;
    uint8 i = 0;
    Product p = Product();
    for(i = 0; i < userProductList.length; i++) {
      p = userProductList.index(i);
      db.buy(user, p.ean);
      amountOfItems++;
      Price price = p.memberprice;
      if(user == 0){
        price = p.guestprice;
      }
      totalPrice += price;
    }
    scannerResult.type = MessageType.INFO;
    scannerResult.message = @"Purchase successful. $amountOfItems for $totalPrice € brought";
    scannerResult.audioType = AudioType.INFO;
    return scannerResult;
  }

  private ScannerResult handleUserState(string scannerdata) throws DatabaseError, IOError {
    ScannerSesseionCodeType codeType = getCodeType(scannerdata);
    ScannerResult scannerResult = ScannerResult();
    switch (codeType) {
      case ScannerSesseionCodeType.EAN:
        uint64 ean = 0;
        scannerdata.scanf("%llu", out ean);
        Product p = {};
        try {
          p = db.get_product_for_ean(ean);
          } catch(IOError e) {
            scannerResult.type = MessageType.ERROR;
            scannerResult.message = "Internal Error!";
            scannerResult.audioType = AudioType.ERROR;
            return scannerResult;
          } catch(DatabaseError e) {
            if(e is DatabaseError.PRODUCT_NOT_FOUND) {
              scannerResult.type = MessageType.ERROR;
              scannerResult.message = "Error: unknown product: %llu".printf(ean);
              scannerResult.audioType = AudioType.ERROR;
            } else {
              scannerResult.type = MessageType.ERROR;
              scannerResult.message = "Error: %s".printf(e.message);
              scannerResult.audioType = AudioType.ERROR;
            }
            return scannerResult;
          }

        userProductList.append_val(p);

        Price price = p.memberprice;

        if(user == 0){
          price = p.guestprice;
        }

        scannerResult.type = MessageType.INFO;
        scannerResult.message = @"article added to shopping card: $(p.name) ($price €)";
        scannerResult.audioType = AudioType.PURCHASE;
        state = ScannerSessionState.USER;
        return scannerResult;
        break;
      case ScannerSesseionCodeType.UNDO:
        if(userProductList.length > 0){
          userProductList.remove_index(userProductList.length-1);
          scannerResult.type = MessageType.INFO;
          scannerResult.message = @"removed last Item from Shopping Cart";
          scannerResult.audioType = AudioType.INFO;
          return scannerResult;
        }
        else {
          scannerResult.type = MessageType.INFO;
          scannerResult.message = @"No more Items on your Shopping Cart";
          scannerResult.audioType = AudioType.ERROR;
          return scannerResult;
        }
        break;
      case ScannerSesseionCodeType.LOGOUT:
        scannerResult = logout();
        return scannerResult;
        break;
      case ScannerSesseionCodeType.USER:
      case ScannerSesseionCodeType.GUEST:
        //Logout alten User und akrtikel kaufen
        scannerResult = logout();
        scannerResult.nextScannerdata = scannerdata;
        return scannerResult;
        break;
    }

    return scannerResult;
  }

  private void handle_barcode(string scannerdata) {
    try {
      stdout.printf("scannerdata: %s\n", scannerdata);
      if(interpret(scannerdata))
        dev.blink(1000);
    } catch(IOError e) {
      send_message(MessageType.ERROR, "IOError: %s", e.message);
    } catch(DatabaseError e) {
      send_message(MessageType.ERROR, "DatabaseError: %s", e.message);
    }
  }

  private bool interpret(string scannerdata) throws DatabaseError, IOError {
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

    return true;
  }

  private ScannerResult logout() {
    ScannerResult scannerResult = ScannerResult();
    scannerResult = buyShoppingCard()
    logged_in = false;
    state = ScannerSessionState.READY;
    return scannerResult;
  }


}
