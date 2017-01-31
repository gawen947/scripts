#!/bin/sh
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

now=$(date +"%s")

for user in $(ls /home)
do
  home=/home/$user
  limit_file=$home/.uploaded-limit
  map_file=$home/.uploaded-map
  if [ ! -r $limit_file -o ! -r $map_file ]
  then
    continue
  fi

  tmp_limit=$(mktemp)
  tmp_map=$(mktemp)
  while read line
  do
    file=$(echo $line | cut -d' ' -f 1)
    limit=$(echo $line | cut -d' ' -f 2)

    if [ "$now" -gt "$limit" ]
    then
      rm -f $home/public_html/upload/$file
    else
      map=$(cat "$map_file" | grep "^$file ")
      if [ -n "$map" ]
      then
        echo "$map" >> $tmp_map
      fi
      echo "$line" >> $tmp_limit
    fi
  done < $limit_file

  mv $tmp_limit $limit_file
  mv $tmp_map   $map_file
  chown $user:$user $limit_file
  chown $user:$user $map_file
  chmod 644 $map_file
done
