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

public class ReadyState {

  private I18n i18n;
  private Config cfg;
  private Database db;

  private string systemlanguage;

  public ReadyState(){
    try {
      this.i18n        = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.I18n", "/io/mainframe/shopsystem/i18n");
      this.cfg         = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
      this.db          = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Database", "/io/mainframe/shopsystem/database");

      this.systemlanguage = this.cfg.get_string("GENERAL", "language");
    } catch (Error e){
      error("Error %s\n", e.message);
    }
  }

  public ScannerResult handleScannerData(string scannerdata) throws DatabaseError, IOError{
    ScannerCodeType codeType = CodeType.getType(scannerdata);
    ScannerResult scannerResult = ScannerResult();
    switch (codeType) {
      case ScannerCodeType.USER:
        return this.user(scannerdata);
      case ScannerCodeType.GUEST:
        scannerResult.nextScannerdata ={@"USER 0"};
        return scannerResult;
      case ScannerCodeType.EAN:
        return this.ean(scannerdata);
      case ScannerCodeType.RFIDEM4100:
          int user = db.get_userid_for_rfid(scannerdata);
          scannerResult.nextScannerdata = {@"USER $user"};
          return scannerResult;
      default:
        scannerResult.nextstate = ScannerSessionState.READY;
        return scannerResult;
    }
  }

  private ScannerResult ean(string scannerdata){
    ScannerResult scannerResult = ScannerResult();
    uint64 ean = 0;
    scannerdata.scanf("%llu", out ean);
    Product p = Product();
    try {
      p = db.get_product_for_ean(ean);
    } catch(IOError e) {
      scannerResult.type = MessageType.ERROR;
      scannerResult.message = i18n.get_string("internalerror",this.systemlanguage);
      scannerResult.audioType = AudioType.ERROR;
      return scannerResult;
    } catch(DatabaseError e) {
      if(e is DatabaseError.PRODUCT_NOT_FOUND) {
        scannerResult.type = MessageType.ERROR;
        scannerResult.message = i18n.get_string("unkonwnproduct",this.systemlanguage).printf(ean);
        scannerResult.audioType = AudioType.ERROR;
      } else {
        scannerResult.type = MessageType.ERROR;
        scannerResult.message = i18n.get_string("error",this.systemlanguage).printf(e.message);
        scannerResult.audioType = AudioType.ERROR;
      }
      return scannerResult;
    }

    var mprice = p.memberprice;
    var gprice = p.guestprice;
    var pname = p.name;

    scannerResult.type = MessageType.INFO;
    scannerResult.message = i18n.get_string("articleinfo",this.systemlanguage).printf(pname,mprice.to_string(),gprice.to_string());
    scannerResult.audioType = AudioType.INFO;
    scannerResult.nextstate = ScannerSessionState.READY;
    return scannerResult;
  }

  private ScannerResult user(string scannerdata){
    ScannerResult scannerResult = ScannerResult();
    int32 userid = int.parse(scannerdata.substring(5));
    scannerResult.usersession = new UserSession(userid);
    if(scannerResult.usersession.isLoginSuccesfull()) {
      scannerResult.type = MessageType.INFO;
      if(scannerResult.usersession.isGuest()){
        scannerResult.message = i18n.get_string("loginguest",scannerResult.usersession.getLanguage()).printf(scannerResult.usersession.getName(), userid);
      }
      else {
        scannerResult.message = i18n.get_string("login",scannerResult.usersession.getLanguage()).printf(scannerResult.usersession.getName(), userid);
      }
      scannerResult.audioType = AudioType.LOGIN;
      scannerResult.nextstate = ScannerSessionState.USER;
      scannerResult.disablePrivacyMode = true;
      return scannerResult;
    } else {
      scannerResult.type = MessageType.ERROR;
      scannerResult.message = i18n.get_string("loginfailed",this.systemlanguage).printf(userid);
      scannerResult.audioType = AudioType.ERROR;
      scannerResult.nextstate = ScannerSessionState.READY;
      return scannerResult;
    }
  }
}
