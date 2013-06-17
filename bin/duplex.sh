#!/bin/sh
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

if [ $# != 2 -a $# != 1 ]
then
  echo "usage: [printer] <file>"
  exit 1
fi

if [ $# = "1" ]
then
  if [ -r $HOME/.default-printer ]
  then
    printer=$(cat $HOME/.default-printer)
  else
    echo "error: cannot find the default printer in $HOME/.default-printer"
    exit 1
  fi
else
  printer=$1
  shift
fi

file=$1

do_print() (
  lp -d "$printer" -o page-set=$1 "$file"
)

do_print even

if zenity --question --text "Waiting for the documents on ${printer}...\n\nNote that it may won't print any page at all. In that case this may be because the document only has one page so you may safely continue from here.\n\nYou may also cancel the impression at this point." --ok-label "Print" --cancel-label "Cancel" --title "Waiting on ${printer}"
then
  do_print odd
fi
