/* Copyright 2012-2013, Sebastian Reichel <sre@ring0.de>
 * Copyright 2017-2018, Johannes Rudolph <johannes.rudolph@gmx.com>
 * Copyright 2017-2018, Malte Modler <malte@malte-modler.de>
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
  private string systemlanguage;
  private string userlanguage;

  private Database db;
  private AudioPlayer audio;
  private InputDevice devScanner;
  private InputDevice devRfid;
  private Cli cli;
  private I18n i18n;
  private Config cfg;

  private ScannerSessionState state = ScannerSessionState.READY;
  private Product[] shoppingCard = {};

  public signal void msg(MessageType type, string message);
  public signal void msg_overlay(string title, string message);

  public ScannerSessionImplementation() {
    try {
      db          = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Database", "/io/mainframe/shopsystem/database");
      devScanner  = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.InputDevice", "/io/mainframe/shopsystem/device/scanner");
      devRfid     = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.InputDevice", "/io/mainframe/shopsystem/device/rfid");
      cli         = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Cli", "/io/mainframe/shopsystem/cli");
      audio       = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.AudioPlayer", "/io/mainframe/shopsystem/audio");
      i18n        = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.I18n", "/io/mainframe/shopsystem/i18n");
      cfg         = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");

      devScanner.received_barcode.connect(handle_barcode);
      devRfid.received_barcode.connect(handle_barcode);
      cli.received_barcode.connect(handle_barcode);

      systemlanguage = cfg.get_string("GENERAL", "language");
      userlanguage = systemlanguage;
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
      send_message(MessageType.ERROR, i18n.get_string("loginerror",userlanguage).printf(user, e.message));
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
    // Here the Displayed Language can be modiyfied later for each user after login
    this.userlanguage = this.systemlanguage;
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
    } else if(scannerdata.length == 10) {
      return ScannerSesseionCodeType.RFIDEM4100;
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
        audio.play_user(theme, "info");
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
            scannerResult.message = i18n.get_string("login",userlanguage).printf(name, user);
            scannerResult.audioType = AudioType.LOGIN;
            shoppingCard = {};
            state = ScannerSessionState.USER;
            return scannerResult;
          } else {
            scannerResult.type = MessageType.ERROR;
            scannerResult.message = i18n.get_string("loginfailed",userlanguage).printf(userid);
            scannerResult.audioType = AudioType.ERROR;
            state = ScannerSessionState.READY;
            return scannerResult;
          }
      case ScannerSesseionCodeType.GUEST:
        if(login(0)) {
          scannerResult.type = MessageType.INFO;
          scannerResult.message = i18n.get_string("loginguest",userlanguage);
          scannerResult.audioType = AudioType.LOGIN;
          shoppingCard = {};
          state = ScannerSessionState.USER;
          return scannerResult;
        } else {
          scannerResult.type = MessageType.ERROR;
          scannerResult.message = i18n.get_string("loginguestfailed",userlanguage);
          scannerResult.audioType = AudioType.ERROR;
          state = ScannerSessionState.READY;
          return scannerResult;
        }
      case ScannerSesseionCodeType.EAN:
        uint64 ean = 0;
        scannerdata.scanf("%llu", out ean);
        Product p = Product();
        try {
          p = db.get_product_for_ean(ean);
        } catch(IOError e) {
          scannerResult.type = MessageType.ERROR;
          scannerResult.message = i18n.get_string("internalerror",userlanguage);
          scannerResult.audioType = AudioType.ERROR;
          return scannerResult;
        } catch(DatabaseError e) {
          if(e is DatabaseError.PRODUCT_NOT_FOUND) {
            scannerResult.type = MessageType.ERROR;
            scannerResult.message = i18n.get_string("unkonwnproduct",userlanguage).printf(ean);
            scannerResult.audioType = AudioType.ERROR;
          } else {
            scannerResult.type = MessageType.ERROR;
            scannerResult.message = i18n.get_string("error",userlanguage).printf(e.message);
            scannerResult.audioType = AudioType.ERROR;
          }
          return scannerResult;
        }

        var mprice = p.memberprice;
        var gprice = p.guestprice;
        var pname = p.name;

        scannerResult.type = MessageType.INFO;
        scannerResult.message = i18n.get_string("articleinfo",userlanguage).printf(pname,mprice.to_string(),gprice.to_string());
        scannerResult.audioType = AudioType.INFO;
        state = ScannerSessionState.READY;
        return scannerResult;
      case ScannerSesseionCodeType.RFIDEM4100:
          int user = db.get_userid_for_rfid(scannerdata);
          scannerResult.nextScannerdata =@"USER $user";
          return scannerResult;
      default:
        state = ScannerSessionState.READY;
        return scannerResult;
    }
  }

  private ScannerResult buyShoppingCard() {
    ScannerResult scannerResult = ScannerResult();
    uint8 amountOfItems = 0;
    double totalPrice = 0.0;
    uint8 i = 0;
    Product p = Product();
    for(i = 0; i < shoppingCard.length; i++) {
      p = shoppingCard[i];
      db.buy(user, p.ean);
      amountOfItems++;
      Price price = p.memberprice;
      if(user == 0){
        price = p.guestprice;
      }
      totalPrice += price/100.0;
    }
    scannerResult.type = MessageType.INFO;
    if(this.user == 0){ //GUEST
        scannerResult.message = i18n.get_string("purchaseguest",userlanguage).printf(amountOfItems, totalPrice.to_string(), totalPrice.to_string());
    }
    else { //All Others
      scannerResult.message = i18n.get_string("purchasemember",userlanguage).printf(name, amountOfItems, totalPrice.to_string());
    }
    scannerResult.audioType = AudioType.LOGOUT;
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
            scannerResult.message = i18n.get_string("internalerror",userlanguage);
            scannerResult.audioType = AudioType.ERROR;
            return scannerResult;
          } catch(DatabaseError e) {
            if(e is DatabaseError.PRODUCT_NOT_FOUND) {
              scannerResult.type = MessageType.ERROR;
              scannerResult.message = i18n.get_string("unkonwnproduct",userlanguage).printf(ean);
              scannerResult.audioType = AudioType.ERROR;
            } else {
              scannerResult.type = MessageType.ERROR;
              scannerResult.message = i18n.get_string("error",userlanguage).printf(e.message);
              scannerResult.audioType = AudioType.ERROR;
            }
            return scannerResult;
          }

          shoppingCard += p;

        Price price = p.memberprice;

        if(user == 0){
          price = p.guestprice;
        }

        scannerResult.type = MessageType.INFO;
        scannerResult.message = i18n.get_string("articleadd",userlanguage).printf(p.name,price.to_string());
        scannerResult.audioType = AudioType.PURCHASE;
        state = ScannerSessionState.USER;
        return scannerResult;
      case ScannerSesseionCodeType.UNDO:
        if(shoppingCard.length > 0){
          Product[] newShoppingCard = {};
          Product removedProduct = shoppingCard[shoppingCard.length-1];
          for (int i = 0; i < shoppingCard.length-1;i++){
            newShoppingCard += shoppingCard[i];
          }
          shoppingCard = newShoppingCard;
          scannerResult.type = MessageType.INFO;
          scannerResult.message = i18n.get_string("articleremove",userlanguage).printf(removedProduct.name);
          scannerResult.audioType = AudioType.INFO;
          return scannerResult;
        }
        else {
          scannerResult.type = MessageType.INFO;
          scannerResult.message = i18n.get_string("nomorearticle",userlanguage);
          scannerResult.audioType = AudioType.ERROR;
          return scannerResult;
        }
      case ScannerSesseionCodeType.LOGOUT:
        scannerResult = logout();
        return scannerResult;
      case ScannerSesseionCodeType.USER:
      case ScannerSesseionCodeType.GUEST:
      case ScannerSesseionCodeType.RFIDEM4100:
        //Logout alten User und akrtikel kaufen
        scannerResult = logout();
        scannerResult.nextScannerdata = scannerdata;
        return scannerResult;
    }

    return scannerResult;
  }

  private void handle_barcode(string scannerdata) {
    try {
      stdout.printf("scannerdata: %s\n", scannerdata);
      if(interpret(scannerdata))
        devScanner.blink(1000);
    } catch(IOError e) {
      send_message(MessageType.ERROR, i18n.get_string("ioerror",userlanguage).printf(e.message));
    } catch(DatabaseError e) {
      send_message(MessageType.ERROR, i18n.get_string("databaseerror",userlanguage).printf(e.message));
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
    if(scannerResult.nextScannerdata != null){
      interpret(scannerResult.nextScannerdata);
    }
    return true;
  }

  private ScannerResult logout() {
    ScannerResult scannerResult = ScannerResult();
    //Back to Default Language
    this.userlanguage = this.systemlanguage;
    scannerResult = buyShoppingCard();
    logged_in = false;
    state = ScannerSessionState.READY;
    return scannerResult;
  }


}
