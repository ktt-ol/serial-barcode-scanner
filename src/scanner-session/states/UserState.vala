/* Copyright 2018, Johannes Rudolph <johannes.rudolph@gmx.com>
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

public struct ShoppingCardResult {
   public uint8 amountOfItems;
   public double totalPrice;
}

public class UserState {

  private Database db;
  private I18n i18n;
  private Config cfg;

  public UserState(){
    try {
      this.db          = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Database", "/io/mainframe/shopsystem/database");
      this.i18n        = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.I18n", "/io/mainframe/shopsystem/i18n");
      this.cfg         = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
    } catch (IOError e){
      error("IOError: %s\n", e.message);
    }
  }

  public ScannerResult handleScannerData(string scannerdata, UserSession usersession) throws DatabaseError, IOError {
    ScannerCodeType codeType = CodeType.getType(scannerdata);
    switch (codeType) {
      case ScannerCodeType.EAN:
        return this.ean(scannerdata,usersession);
      case ScannerCodeType.UNDO:
        return this.undo(scannerdata,usersession);
      case ScannerCodeType.USERINFO:
        return this.userinfo(usersession);
      case ScannerCodeType.LOGOUT:
        return this.logout(usersession);
      case ScannerCodeType.USER:
      case ScannerCodeType.GUEST:
      case ScannerCodeType.RFIDEM4100:
        return this.relogin(scannerdata,usersession);
    }
    ScannerResult scannerResult = ScannerResult();
    scannerResult.usersession = usersession;
    return scannerResult;
  }

  private ScannerResult relogin(string scannerdata, UserSession usersession){
    ScannerResult scannerResult = ScannerResult();
    scannerResult.nextScannerdata = {"LOGOUT",scannerdata};
    scannerResult.nextstate = ScannerSessionState.USER;
    scannerResult.usersession = usersession;
    return scannerResult;
  }

  private ScannerResult ean(string scannerdata, UserSession usersession){
    ScannerResult scannerResult = ScannerResult();
    uint64 ean = 0;
    scannerdata.scanf("%llu", out ean);
    Product p = {};
    try {
      p = db.get_product_for_ean(ean);
    } catch(IOError e) {
        scannerResult.type = MessageType.ERROR;
        scannerResult.message = i18n.get_string("internalerror",usersession.getLanguage());
        scannerResult.audioType = AudioType.ERROR;
        return scannerResult;
    } catch(DatabaseError e) {
        if(e is DatabaseError.PRODUCT_NOT_FOUND) {
          scannerResult.type = MessageType.ERROR;
          scannerResult.message = i18n.get_string("unkonwnproduct",usersession.getLanguage()).printf(ean);
          scannerResult.audioType = AudioType.ERROR;
        } else {
          scannerResult.type = MessageType.ERROR;
          scannerResult.message = i18n.get_string("error",usersession.getLanguage()).printf(e.message);
          scannerResult.audioType = AudioType.ERROR;
        }
        return scannerResult;
    }

    Price price = usersession.addItemToShoppingCard(p);

    scannerResult.type = MessageType.INFO;
    scannerResult.message = i18n.get_string("articleadd",usersession.getLanguage()).printf(p.name,price.to_string());
    scannerResult.audioType = AudioType.PURCHASE;
    scannerResult.nextstate = ScannerSessionState.USER;
    scannerResult.usersession = usersession;
    return scannerResult;
  }

  private ScannerResult undo(string scannerdata, UserSession usersession){
    ScannerResult scannerResult = ScannerResult();
    if(!usersession.isShoppingCardEmpty()){
      Product removedProduct = usersession.removeLastItemFromShoppingCard();
      scannerResult.type = MessageType.INFO;
      scannerResult.message = i18n.get_string("articleremove",usersession.getLanguage()).printf(removedProduct.name);
      scannerResult.audioType = AudioType.INFO;
      scannerResult.nextstate = ScannerSessionState.USER;
      scannerResult.usersession = usersession;
      return scannerResult;
    }
    else {
      scannerResult.type = MessageType.INFO;
      scannerResult.message = i18n.get_string("nomorearticle",usersession.getLanguage());
      scannerResult.audioType = AudioType.ERROR;
      scannerResult.nextstate = ScannerSessionState.USER;
      scannerResult.usersession = usersession;
      return scannerResult;
    }
  }

  private ScannerResult userinfo(UserSession usersession){
    //stdout.printf("userinfo\n");
    ScannerResult scannerResult = ScannerResult();
    scannerResult.usersession = usersession;
    if(usersession.isGuest()){
      return scannerResult;
    }
    Price currentAmmount = usersession.getInvoiceForCurrentMonth();
    string currentMonth = "";
    try {
      currentMonth = new DateTime.now_utc().format(this.cfg.get_string("DATE-FORMAT", "formatMailSubjectMonthly"));
    } catch(KeyFileError e) {
      error("KeyFileError DATE-FORMAT - formatMailSubjectMonthly not defined: %s\n", e.message);
    }

    scannerResult.type = MessageType.INFO;
    scannerResult.message = i18n.get_string("userinfo",usersession.getLanguage()).printf(currentMonth,currentAmmount.to_string());//i18n.get_string("userinfo",usersession.getLanguage()).printf(removedProduct.name);
    scannerResult.audioType = AudioType.INFO;
    scannerResult.nextstate = ScannerSessionState.USER;
    return scannerResult;
  }

  private ScannerResult logout(UserSession usersession){
    ScannerResult scannerResult = ScannerResult();
    ShoppingCardResult shoppingCardResult = usersession.logout();
    if(shoppingCardResult.amountOfItems >= 1) {
      if(usersession.isGuest()){
        scannerResult.message = i18n.get_string("purchaseguest",usersession.getLanguage()).printf(shoppingCardResult.amountOfItems, shoppingCardResult.totalPrice, shoppingCardResult.totalPrice);
      }
      else {
        scannerResult.message = i18n.get_string("purchasemember",usersession.getLanguage()).printf(usersession.getName(), shoppingCardResult.amountOfItems, shoppingCardResult.totalPrice);
      }
    }
    else {
      scannerResult.message = i18n.get_string("logoutnopurchase",usersession.getLanguage());
    }
    scannerResult.type = MessageType.INFO;
    scannerResult.audioType = AudioType.LOGOUT;
    scannerResult.nextstate = ScannerSessionState.READY;
    scannerResult.usersession = null;
    return scannerResult;
  }

}
