#!/bin/sh
type=$1
album=$2
title=$3

remote_call() (
  if [ -z "$1" ]
  then
    exit 0
  else
    purple-remote "setstatus?message=$2"
  fi
)

case "$type" in
  new)
    remote_call "$title" "(8) $album - $title"
    ;;
  end)
    remote_call "$title" ""
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
