sqlite3 ../shop.db "SELECT id,firstname,lastname FROM users LEFT JOIN authentication ON users.id = authentication.user WHERE (disabled IS NULL or disabled != 1) and id > 0" | sed "s~|~,~g" > users.csv
