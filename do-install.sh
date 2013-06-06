#!/bin/sh
# Copyright (c) 2013 David Hauweele <david@hauweele.net>
 
if [ "$(whoami)" != root ]
then
  echo "error: this should be run as root"
  exit 1
fi

dir="$(pwd)"

do_install() (
  if [ "$4" != "no-ext" ]
  then
    ext=$(echo "$3" | grep -E -o "\..*")
    base=$(basename "$3" "$ext")
  else
    base="$3"
  fi

  echo -n "Install $base... "
  rm -f $2/$base
  cp $dir/$1/$3 $2/$base
  chown root:staff $2/$base
  echo "done."
)

do_install_dir() (
  for file in $(ls $1)
  do
    do_install $1 $2 $file $3
  done
)

do_install_dir bin /usr/local/bin
do_install_dir sbin /usr/local/sbin
do_install_dir lib /usr/local/lib/sh no-ext
