#!/bin/sh
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

now=$(date +"%s")

for user in $(ls /home)
do
  home=/home/$user
  ulf=$home/.uploaded-limit
  if [ ! -r $ulf ]
  then
    continue
  fi

  tmp=$(tempfile)
  while read line
  do
    file=$(echo $line | cut -d' ' -f 1)
    limit=$(echo $line | cut -d' ' -f 2)

    if [ "$now" -gt "$limit" ]
    then
      rm -f $home/public_html/upload/$file
    else
      echo "$line" >> $tmp
    fi
  done < $ulf
  mv $tmp $ulf
  chown $user:$user $ulf
done

