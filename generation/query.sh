#!/bin/bash

if [[ "$1" != "" ]]; then
  # format YYYY-MM-DD, e.g. 2017-01-01
  DATE_PART="AND joined_at > strftime('%s', '$1')"
fi

SQL=`cat <<EOF
SELECT id,firstname,lastname FROM users
LEFT JOIN authentication ON users.id = authentication.user
WHERE (users.disabled IS NULL or users.disabled != 1)
AND id > 0
$DATE_PART
EOF
`
sqlite3 shop.db "$SQL" \
  | sed "s~|~,~g" > users.csv
