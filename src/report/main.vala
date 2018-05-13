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

public static int main(string[] args) {

  bool mail = false;
  bool today = false;
  DateTime now = new DateTime.now_local();
  DateTime yesterday = now.add_days(-1);;

  foreach (string arg in args) {
    switch (arg) {
      case "mail": mail = true;
        break;
      case "today": today = true;
        break;
    }
  }

  if(today){
    yesterday = now;
  }
  DateTime start = new DateTime.local(yesterday.get_year(),yesterday.get_month(),yesterday.get_day_of_month(),0,0,0);

  ReportImplementation report = new ReportImplementation(start);
  report.collectReportData();
  report.cliOutput();
  if(mail){
    report.sendReport();
  }

	return 0;
}
