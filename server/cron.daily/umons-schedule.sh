#!/bin/sh
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

. /etc/umons-schedule.conf

while read line
do
  url=$(echo $line | cut -d' ' -f 1)
  out=$(echo $line | cut -d' ' -f 2)

  tmp=$(mktemp)
  wget "$url" -O $tmp > /dev/null 2>&1

  # Clean the file
  timezone="Europe\\/Brussels"
  asciify $tmp     > $tmp.0
  dos2unix $tmp.0  > /dev/null 2>&1
  cat $tmp.0 | sed "s/DTSTART:\\([[:digit:]]*T[[:digit:]]*\\)$/DTSTART;TZID=$timezone:\\1/" > $tmp
  cat $tmp   | sed "s/DTEND:\\([[:digit:]]*T[[:digit:]]*\\)$/DTEND;TZID=$timezone:\\1/" > $tmp.0

  cp $tmp.0 $out
  chown $OWNING_USER:www-data $out
  chmod a+r $out

  rm $tmp $tmp.0
done < /etc/umons-schedule

exit 0
