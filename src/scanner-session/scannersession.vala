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

  private void logout() {
    logged_in = false;
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
    if(scannerdata.has_prefix("USER ")) {
      string str_id = scannerdata.substring(5);
      int32 id = int.parse(str_id);

      /* check if scannerdata has valid format */
      if(scannerdata != "USER %d".printf(id)) {
        audio.play_system("error.ogg");
        send_message(MessageType.ERROR, "Invalid User ID: %s", scannerdata);
        return false;
      }

      if(logged_in) {
        send_message(MessageType.WARNING, "Last user forgot to logout");
        logout();
      }

      if(login(id)) {
        audio.play_user(theme, "login");
        send_message(MessageType.INFO, "Login: %s (%d)", name, user);
        return true;
      } else {
        audio.play_system("error.ogg");
        send_message(MessageType.ERROR, "Login failed (User ID = %d)", id);
        return false;
      }
    } else if(scannerdata == "GUEST") {
      if(logged_in) {
        send_message(MessageType.WARNING, "Last user forgot to logout");
        logout();
      }

      if(login(0)) {
        audio.play_user(theme, "login");
        send_message(MessageType.INFO, "Login: %s (%d)", name, user);
        return true;
      } else {
        audio.play_system("error.ogg");
        send_message(MessageType.ERROR, "Login failed (User ID = 0)");
        return false;
      }
    } else if(scannerdata == "UNDO") {
      if(!logged_in) {
        audio.play_system("error.ogg");
        send_message(MessageType.ERROR, "Can't undo if not logged in!");
        return false;
      } else {
        string product = db.undo(user);

        if(product != "") {
          audio.play_user(theme, "purchase");
          send_message(MessageType.INFO, "Removed purchase of %s", product);
          return true;
        } else {
          audio.play_user(theme, "error");
          send_message(MessageType.ERROR, "Couldn't undo last purchase!");
          return false;
        }
      }
    } else if(scannerdata == "LOGOUT") {
      if(logged_in) {
        audio.play_user(theme, "logout");
        send_message(MessageType.INFO, "Logout!");
        logout();
        return true;
      }

      return false;
    } else {
      uint64 id = 0;
      scannerdata.scanf("%llu", out id);

      /* check if scannerdata has valid format */
      if(scannerdata != "%llu".printf(id) && scannerdata != "%08llu".printf(id) && scannerdata != "%013llu".printf(id)) {
        audio.play_user(theme, "error");
        send_message(MessageType.ERROR, "invalid product: %s", scannerdata);
        return false;
      }

      string name = "unknown product";

      try {
        id = db.ean_alias_get(id);
        name = db.get_product_name(id);
      } catch(IOError e) {
        audio.play_user(theme, "error");
        send_message(MessageType.ERROR, "Internal Error!");
        return false;
      } catch(DatabaseError e) {
        if(e is DatabaseError.PRODUCT_NOT_FOUND) {
          audio.play_user(theme, "error");
          var msg = "Error: unknown product: %llu".printf(id);
          send_message(MessageType.ERROR, msg);
          msg_overlay("Attention", msg);
        } else {
          audio.play_user(theme, "error");
          send_message(MessageType.ERROR, "Error: %s", e.message);
        }
        return false;
      }

      if(!logged_in) {
        var mprice = db.get_product_price(1, id);
        var gprice = db.get_product_price(0, id);
        var msg = @"article info: $name (Member: $mprice €, Guest: $gprice €)";
        audio.play_system("error.ogg");
        send_message(MessageType.INFO, msg);
        send_message(MessageType.ERROR, "Login required for purchase!");
        msg_overlay("Attention", "%s\nLogin required for purchase!".printf(msg));

        return false;
      }

      if(db.buy(user, id)) {
        var price = db.get_product_price(user, id);
        audio.play_user(theme, "purchase");
        send_message(MessageType.INFO, @"article bought: $name ($price €)");
        return true;
      } else {
        audio.play_user(theme, "error");
        send_message(MessageType.ERROR, "purchase failed!");
        return false;
      }
    }
  }
}
