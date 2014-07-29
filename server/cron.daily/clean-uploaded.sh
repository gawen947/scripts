#!/bin/sh
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

now=$(date +"%s")

for user in $(ls /home)
do
  home=/home/$user
  ulf=$home/.uploaded-limit
  umf=$home/.uploaded-map
  if [ ! -r $ulf -o ! -r $umf ]
  then
    continue
  fi

  tmp_ulf=$(mktemp)
  tmp_umf=$(mktemp)
  while read line
  do
    file=$(echo $line | cut -d' ' -f 1)
    limit=$(echo $line | cut -d' ' -f 2)

    if [ "$now" -gt "$limit" ]
    then
      rm -f $home/public_html/upload/$file
    else
      map=$(cat "$umf" | grep "^$file ")
      if [ -n "$map" ]
      then
        echo "$map" >> $tmp_umf
      fi
      echo "$line" >> $tmp_ulf
    fi
  done < $ulf
  mv $tmp_ulf $ulf
  mv $tmp_umf $umf
  chown $user:$user $ulf
  chown $user:$user $umf
  chmod 644 $umf
done

