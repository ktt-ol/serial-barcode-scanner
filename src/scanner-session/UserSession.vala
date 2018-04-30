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

public class UserSession {

  private string theme;
	private string language;
	private string name;
	private int userid;
	private DateTime logintime;
  private bool disabled;
  private bool loginSuccesfull;
  private Product[] shoppingCard = {};

  private I18n i18n;
  private Config cfg;
  private Database db;
  private AudioPlayer audio;

  public UserSession(int userid){
    this.i18n        = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.I18n", "/io/mainframe/shopsystem/i18n");
    this.cfg         = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
    this.db          = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Database", "/io/mainframe/shopsystem/database");
    this.audio       = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.AudioPlayer", "/io/mainframe/shopsystem/audio");

    this.userid = userid;
    this.loginSuccesfull = this.login();
  }

  private bool login() throws IOError {
    try {
      this.name       = this.db.get_username(this.userid);
      this.disabled   = this.db.user_is_disabled(this.userid);
    } catch(DatabaseError e) {
      stdout.printf(this.i18n.get_string("loginerror",this.cfg.get_string("GENERAL", "language")).printf(this.userid, e.message));
      return false;
    }

    try {
      this.theme = this.db.get_user_theme(this.userid, "");
      if (this.theme == "") {
        this.theme = this.audio.get_random_user_theme();
      }
    } catch(DatabaseError e) {
      this.theme = "beep";
    }
    // Here the Displayed Language can be modiyfied later for each user after login
    this.language = this.cfg.get_string("GENERAL", "language");

    this.logintime = new DateTime.now_local();
    return true;
  }

  private ShoppingCardResult buyShoppingCard() {
    ShoppingCardResult shoppingCardResult = ShoppingCardResult();
    uint8 amountOfItems = 0;
    double totalPrice = 0.0;
    uint8 i = 0;
    Product p = Product();
    for(i = 0; i < this.shoppingCard.length; i++) {
      p = this.shoppingCard[i];
      db.buy(this.userid, p.ean);
      amountOfItems++;
      Price price = p.memberprice;
      if(this.isGuest()){
        price = p.guestprice;
      }
      totalPrice += price/100.0;
    }
    shoppingCardResult.amountOfItems = amountOfItems;
    shoppingCardResult.totalPrice = totalPrice;
    return shoppingCardResult;
  }

  public ShoppingCardResult logout() {
    ShoppingCardResult shoppingCardResult = ShoppingCardResult();
    shoppingCardResult = this.buyShoppingCard();
    return shoppingCardResult;
  }

  public Price addItemToShoppingCard(Product product){
    this.shoppingCard += product;

    if(this.isGuest()){
      return product.guestprice;
    }
    return product.memberprice;
  }

  public Product removeLastItemFromShoppingCard(){
    Product[] newShoppingCard = {};
    Product removedProduct = this.shoppingCard[this.shoppingCard.length-1];
    for (int i = 0; i < this.shoppingCard.length-1;i++){
      newShoppingCard += this.shoppingCard[i];
    }
    this.shoppingCard = newShoppingCard;
    return removedProduct;
  }

  public bool isLoginSuccesfull(){
    return this.loginSuccesfull;
  }

  public string getLanguage(){
    return this.language;
  }

  public string getName(){
    return this.name;
  }

  public bool isGuest(){
    if(this.userid == 0){
      return true;
    }
    return false;
  }

  public bool isShoppingCardEmpty(){
    if(this.shoppingCard.length > 0){
      return false;
    }
    return true;
  }
}
