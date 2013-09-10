#!/bin/sh
type=$1
album=$2
title=$3

remote_call() (
  if [ -z "$1" ]
  then
    exit 0
  else
    message="$2"
    message=$(echo "$message" | sed 's/&/and/g')
    purple-remote "setstatus?message=$message"
  fi
)

case "$type" in
  new)
    remote_call "$title" "(8) $album - $title"
    ;;
  end)
    remote_call "*" ""
    ;;
  end-list)
    remote_call "*" ""
    ;;
  new-title)
    remote_call "$title" "(8) $title"
    ;;
  *)
    echo "Unrecognized command"
    ;;
esac
