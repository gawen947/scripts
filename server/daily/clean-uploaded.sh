#!/bin/sh
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

now=$(date +"%s")

HOME_UPLOAD_PATH="public_html/upload"

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
    file_path = "$home/$HOME_UPLOAD_PATH/$file"

    if [ ! -r "$file_path" ]
    then
      echo "Ignoring non-existent file: $file_path"
      continue
    fi

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

  # Removing non-mapped files
  find "$home/$HOME_UPLOAD_PATH" -type f | while read file
  do
    file=$(basename $file)
    if ! cat "$map_file" | grep "^$file" > /dev/null
    then
      echo "Removing non-mapped file: $file"
      rm -f "$file"
    fi
    if ! cat "$limit_file" | grep "^$file" > /dev/null
    then
      echo "Removing non-limited file: $file"
      rm -f "$file"
    fi
  done

  mv $tmp_limit $limit_file
  mv $tmp_map   $map_file
  chown $user:$user $limit_file
  chown $user:$user $map_file
  chmod 644 $map_file
done
