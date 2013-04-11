#!/bin/sh
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

# This script links targets to the original file in the repository.
# This way the git's cloner could either contribute to the project
# or install each script manually... Ahaha I'm such an evil person!
# No just kidding... As it would poses a grave security risk, it's
# possible to install everything by copying the file instead.
# One may do so by passing "copy" as the first argument.


if [ "$(whoami)" != root ]
then
  echo "error: this should be run as root"
  exit 1
fi

dir=$(pwd)

if [ "$1" = copy ]
then
  echo "Install by copy."
  cmd="cp"
else
  echo "Install by link."
  cmd="ln -s"
fi

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
  $cmd $dir/$1/$3 $2/$base
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
