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

public struct ScannerResult {
	public MessageType type;
	public string message;
	public AudioType audioType;
	public string[] nextScannerdata;
	public UserSession usersession;
	public ScannerSessionState nextstate;
	public bool disablePrivacyMode;
}

[DBus (name = "io.mainframe.shopsystem.ScannerSession")]
public class ScannerSessionImplementation {
  private string systemlanguage;
  private string systemtheme = "beep";
  private int64 timeAutomaticLogout;

  private Database db;
  private AudioPlayer audio;
  private InputDevice devScanner;
  private InputDevice devRfid;
  private Cli cli;
  private I18n i18n;
  private Config cfg;
  private ReadyState readyState;
  private UserState userState;

  private UserSession usersession;

  private ScannerSessionState state = ScannerSessionState.READY;

  public signal void msg(MessageType type, string message);
  public signal void msg_overlay(string title, string message);
  public signal void set_privacy_mode(bool mode);

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

			try {
       this.systemlanguage = cfg.get_string("GENERAL", "language");
			} catch(KeyFileError e) {
				error("KeyFileError General - language not defined: %s\n", e.message);
			}

			try {
       this.timeAutomaticLogout = cfg.get_int64("GENERAL", "autologouttime");
			} catch(KeyFileError e) {
				error("KeyFileError General - autologouttime not defined: %s\n", e.message);
			}

      readyState = new ReadyState();
      userState = new UserState();

			Timeout.add_seconds(1, () => this.check_userssession());
    } catch(IOError e) {
      error("IOError: %s\n", e.message);
    }
  }

	private bool check_userssession(){
		if(this.usersession != null){
			int64 timediff = (new DateTime.now_utc().to_unix()) - (this.usersession.getLastActionTime().to_unix());
			if(timediff >= this.timeAutomaticLogout){
				this.handle_barcode("LOGOUT");
			}
		}

		return true;
	}

  private void send_message(MessageType type, string format, ...) {
    var arguments = va_list();
    var message = format.vprintf(arguments);

    msg(type, message);
  }

  private void play_audio(AudioType audioType, string theme){
    switch (audioType) {
      case AudioType.ERROR:
        try {
	  audio.play_user(theme, "error");
	}
	catch(Error e) {
	  audio.play_system("error.ogg");
	}
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

  private void handle_barcode(string scannerdata) {
    try {
      stdout.printf("scannerdata: %s\n", scannerdata);
      if(interpret(scannerdata))
        devScanner.blink(1000);
    } catch(IOError e) {
      send_message(MessageType.ERROR, i18n.get_string("ioerror",systemlanguage).printf(e.message));
    } catch(DatabaseError e) {
      send_message(MessageType.ERROR, i18n.get_string("databaseerror",systemlanguage).printf(e.message));
    }
  }

  private bool interpret(string scannerdata) throws DatabaseError, IOError {
    ScannerResult scannerResult = ScannerResult();
    switch (this.state) {
      case ScannerSessionState.READY:
        scannerResult = this.readyState.handleScannerData(scannerdata);
        break;
      case ScannerSessionState.USER:
        scannerResult = this.userState.handleScannerData(scannerdata,this.usersession);
        break;
    }

    send_message(scannerResult.type, scannerResult.message);
    this.state = scannerResult.nextstate;
    string theme;
    if(this.usersession != null){
        theme = this.usersession.getTheme();
    } else if(scannerResult.usersession != null){
        theme = scannerResult.usersession.getTheme();
    } else {
        theme = this.systemtheme;
    }
    if(scannerResult.disablePrivacyMode){
        set_privacy_mode(false);
    }
    else {
        set_privacy_mode(true);
    }
    play_audio(scannerResult.audioType,theme);
    this.usersession = scannerResult.usersession;
    if(scannerResult.nextScannerdata != null){
      int i;
      for(i = 0; i < scannerResult.nextScannerdata.length ; i++){
        interpret(scannerResult.nextScannerdata[i]);
      }
    }
    return true;
  }

}
