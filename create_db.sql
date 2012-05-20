CREATE TABLE products (id INTEGER PRIMARY KEY NOT NULL, name TEXT, amount INTEGER NOT NULL DEFAULT 0);
CREATE TABLE purchases (user INTEGER NOT NULL DEFAULT 0, product INTEGER NOT NULL DEFAULT 0, timestamp INTEGER NOT NULL DEFAULT 0);
CREATE TABLE restock (user INTEGER NOT NULL DEFAULT 0, product INTEGER NOT NULL DEFAULT 0, amount INTEGER NOT NULL DEFAULT 0, timestamp INTEGER NOT NULL DEFAULT 0);
CREATE TABLE prices (product INTEGER NOT NULL DEFAULT 0, valid_from INTEGER NOT NULL DEFAULT 0, memberprice INTEGER NOT NULL DEFAULT 0, guestprice INTEGER NOT NULL DEFAULT 0);
CREATE TABLE users (id INTEGER PRIMARY KEY NOT NULL, username TEXT, firstname TEXT NOT NULL, lastname TEXT NOT NULL, street TEXT, city TEXT, email TEXT);
BEGIN TRANSACTION;
INSERT INTO products (id, name) VALUES(4029764001807,'Club Mate');
INSERT INTO products (id, name) VALUES(5449000017888,'Coka Cola');
INSERT INTO products (id, name) VALUES(5449000017895,'Coka Cola Light');
INSERT INTO products (id, name) VALUES(5449000134264,'Coka Cola Zero');
INSERT INTO products (id, name) VALUES(5449000017918,'Fanta');
INSERT INTO products (id, name) VALUES(5449000017932,'Sprite');
INSERT INTO products (id, name) VALUES(4104450004383,'Limette');
INSERT INTO products (id, name) VALUES(4104450005878,'Vilsa Classic');
INSERT INTO products (id, name) VALUES(5000159407236,'Mars');
INSERT INTO products (id, name) VALUES(5000159407397,'Snickers');
INSERT INTO products (id, name) VALUES(5000159418539,'Balisto Jogurt Beeren Mix');
INSERT INTO products (id, name) VALUES(7613032625474,'Lion');
INSERT INTO products (id, name) VALUES(7613032850340,'KitKat Chunky');
INSERT INTO products (id, name) VALUES(40084015,'Duplo');
INSERT INTO products (id, name) VALUES(40358802,'Knoppers');
INSERT INTO products (id, name) VALUES(40084107,'Ü-Ei');
INSERT INTO products (id, name) VALUES(40114606,'KitKat');
INSERT INTO products (id, name) VALUES(40111315,'Twix');
INSERT INTO products (id, name) VALUES(4003586000491,'Chips Frisch Oriento');
INSERT INTO products (id, name) VALUES(8690504018568,'Üker Sesamsticks');
INSERT INTO products (id, name) VALUES(4001686216125,'Haribo Salino');
INSERT INTO products (id, name) VALUES(4001686312025,'Haribo Schnuller');
INSERT INTO products (id, name) VALUES(4001686150689,'Haribo Konfekt');
INSERT INTO products (id, name) VALUES(4001686128244,'Haribo Staffeten');
INSERT INTO products (id, name) VALUES(4001686390085,'Haribo Phantasia');
INSERT INTO products (id, name) VALUES(4001686310229,'Haribo Weinland');
INSERT INTO products (id, name) VALUES(4001686386613,'Haribo Saftgoldbären');
INSERT INTO products (id, name) VALUES(4001686301265,'Haribo Goldbären');
INSERT INTO products (id, name) VALUES(4001686313046,'Haribo Saure Bohnen');
INSERT INTO products (id, name) VALUES(4001686720028,'Haribo Colorado Mini');
COMMIT;
