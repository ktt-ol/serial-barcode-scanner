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

 public const int DAYINSECONDS = 60*60*24;

 public class ReportImplementation {

   private Database db;
   private Config cfg;
   private Mailer mailer;
   private DateTime startTime;
   private DateTime stopTime;

   private string[] reportParts = {};

   private string dateTimeFormat;
   private string timeFormat;
   private string startstring;
   private string stopstring;

   public ReportImplementation (DateTime startTime) {
     try {
      this.mailer           = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Mail", "/io/mainframe/shopsystem/mailer");
 		  this.cfg              = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Config", "/io/mainframe/shopsystem/config");
 		  this.db               = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Database", "/io/mainframe/shopsystem/database");
      this.dateTimeFormat   = cfg.get_string("DATE-FORMAT", "formatDateTime");
      this.timeFormat       = cfg.get_string("DATE-FORMAT", "formatTime");
     } catch (Error e){
        error("Error: %s\n", e.message);
     }

      this.startTime        = startTime;
  		this.stopTime         = new DateTime.from_unix_local(this.startTime.to_unix() + DAYINSECONDS - 1);

      this.startstring      = startTime.format(this.dateTimeFormat);
      this.stopstring       = stopTime.format(this.dateTimeFormat);
   }

   public void collectReportData(){
     reportParts += this.collectCashData();
     reportParts += this.collectStockData();
     reportParts += this.collectSellData();
     reportParts += this.collectProductStatisticData();
     reportParts += this.collectMoneyStatisticData();
   }

   public void sendReport(){
     try {
       /* title */
       string mailtitle = "Report "+ cfg.get_string("GENERAL", "shortname")+" Shopsystem " + @" $startstring - $stopstring";

       string mailpath = this.mailer.create_mail();
       Mail mail = Bus.get_proxy_sync(BusType.SYSTEM, "io.mainframe.shopsystem.Mail", mailpath);
       mail.from = {cfg.get_string("GENERAL", "shortname")+" Shopsystem", cfg.get_string("MAIL", "mailfromaddress")};
       mail.add_recipient({cfg.get_string("GENERAL", "shortname") + " Shop Report",cfg.get_string("MAIL", "reportaddress")}, RecipientType.TO);
       mail.subject = mailtitle;

       string mailcontent = "Here Is Your Daily " + cfg.get_string("GENERAL", "shortname") + " Shop Report\n\n";

       foreach(string part in this.reportParts){
         mailcontent += part;
       }

       mail.set_main_part(mailcontent, MessageType.PLAIN);
       mailer.send_mail(mailpath);
     } catch (Error e){
       error("Error: %s\n", e.message);
     }
   }

   public void cliOutput(){
     stdout.printf("Daily Report\n\nFrom: %s\nTo: %s\n\n",this.startstring,this.stopstring);
     foreach(string part in this.reportParts){
       stdout.printf("%s",part);
     }
   }

   private string collectStockData() {
     string data = "###### STOCK Data\n\n";
     try {
       StockEntry[] stockData = db.get_stock();
       string category = "";

       foreach (StockEntry entry in stockData) {
          if(category != entry.category){
            data += "----------------------------------------------------\n";
            data += "\t%s\n".printf(entry.category);
            data += "----------------------------------------------------\n";
            category = entry.category;
          }
          data += "%i\t| %s\n".printf(entry.amount,entry.name);
       }

       data += "\n";
     } catch (Error e){
       error("Error: %s\n", e.message);
     }
     return data;
   }

   private string collectCashData() {
     string data = "###### CASH Data\n\n";
     try {
       Price currentCash = db.cashbox_status();
       data += "The Current Amount in the Cashregister is/should be %s €\n\n".printf(currentCash.to_string());
     } catch (Error e){
       error("Error: %s\n", e.message);
     }
     return data;
   }

   private string collectSellData() {
     string data = "###### SELL Data\n\n";
     try {
       Sale[] sales = db.get_sales(this.startTime.to_unix(),this.stopTime.to_unix());

       foreach (Sale entry in sales) {
         DateTime dt = new DateTime.from_unix_local(entry.timestamp);
         string newdate = dt.format(this.timeFormat);
         data += "%s\t| %s\t| %s %s\n".printf(newdate,entry.productname,entry.userFirstname,entry.userLastname);
       }

       data += "\n";
     } catch (Error e){
       error("Error: %s\n", e.message);
     }
     return data;
   }

   private string collectProductStatisticData() {
     string data = "###### Product Statistic Data\n\n";
     string category = "";
     try {
       StatisticProductsPerDay[] productsDataDay = db.get_statistic_products_per_day_withDate(this.startTime.format("%Y-%m-%d"));
       data += "For Day: " + this.startTime.format("%Y-%m-%d") + "\n";
       foreach (StatisticProductsPerDay productData in productsDataDay) {
         if (productData.numOfProducts > 0){
             if(category != productData.category){
               data += "----------------------------------------------------\n";
               data += "\t%s\n".printf(productData.category);
               data += "----------------------------------------------------\n";
               category = productData.category;
             }
             data += "%ld\t| %s\n".printf((long)productData.numOfProducts,productData.product);
         }
       }
       data += "\n";
       category = "";
       
       StatisticProductsPerMonth[] productsDataMonth = db.get_statistic_products_per_month_withMonthYear(this.startTime.format("%m"),this.startTime.format("%Y"));
       data += "For Month: " + this.startTime.format("%m %Y") + "\n";
       foreach (StatisticProductsPerDay productData in productsDataDay) {
         if (productData.numOfProducts > 0){
             if(category != productData.category){
               data += "----------------------------------------------------\n";
               data += "\t%s\n".printf(productData.category);
               data += "----------------------------------------------------\n";
               category = productData.category;
             }
             data += "%ld\t| %s\n".printf((long)productData.numOfProducts,productData.product);
         }
       }
       data += "\n";
       category = "";
       
       StatisticProductsPerYear[] productsDataYear = db.get_statistic_products_per_year_withYear(this.startTime.format("%Y"));
       data += "For Year: " + this.startTime.format("%Y") + "\n";
       foreach (StatisticProductsPerDay productData in productsDataDay) {
         if (productData.numOfProducts > 0){
             if(category != productData.category){
               data += "----------------------------------------------------\n";
               data += "\t%s\n".printf(productData.category);
               data += "----------------------------------------------------\n";
               category = productData.category;
             }
             data += "%ld\t| %s\n".printf((long)productData.numOfProducts,productData.product);
         }
       }
       data += "\n";
     } catch (Error e){
       error("Error: %s\n", e.message);
     }
     return data;
   }

   private string collectMoneyStatisticData() {
     string data = "###### Money Statistic Data\n\n";
     try {
       StatisticSalesPerDay[] productsDataDay = db.get_statistic_sales_per_day_withDate(this.startTime.format("%Y-%m-%d"));
       data += "For Day: " + this.startTime.format("%Y-%m-%d") + "\n";
       foreach (StatisticSalesPerDay productData in productsDataDay) {
         data += "%s €\n".printf(productData.total.to_string());
       }
       data += "\n";

       StatisticSalesPerMonth[] productsDataMonth = db.get_statistic_sales_per_month();
       data += "For Month\n";
       foreach (StatisticSalesPerMonth productData in productsDataMonth) {
         if (productData.total > 0){
          data += "%s/%s: %s €\n".printf(productData.month,productData.year, productData.total.to_string());
         }
       }
       data += "\n";

       StatisticSalesPerYear[] productsDataYear = db.get_statistic_sales_per_year_withYear(this.startTime.format("%Y"));
       data += "For Year\n";
       foreach (StatisticSalesPerYear productData in productsDataYear) {
         data += "%s: %s €\n".printf(productData.year, productData.total.to_string());
       }
       data += "\n";
     } catch (Error e){
       error("Error: %s\n", e.message);
     }
     return data;
   }
 }
