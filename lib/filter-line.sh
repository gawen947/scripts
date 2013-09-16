#!/bin/sh
# Filter a file and display only lines lesser than the specified limit.
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

if [ $# != 1 ]
then
  echo "usage: $0 <limit>"
  exit 1
fi
limit="$1"

while read line
do
  len=$(args-length "$line")

  if [ -z "$len" ]
  then
    len=0
  fi

  if [ "$len" -lt "$limit" ]
  then
    echo "$line"
  fi
done
