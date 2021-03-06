#!/bin/sh
# Copyright (c) 2015 David Hauweele <david@hauweele.net>

user_root="$HOME/.config/conf"
system_root="/usr/local/etc/conf"

if [ -r "/etc/conf.rc" ]
then
  . /etc/conf.rc
fi

action=$1
mode=$2
key=$3
value=$4

error() {
  >&2 echo "error: $1"
  exit 1
}

bad_usage() {
  error "$1. use '$(basename $0) help' for usage information."
}

help_message() {
  >&2 echo "usage: $(basename $0) action user|system [[key] value]"
  >&2 echo
  >&2 echo Actions:
  >&2 echo "  is   key           Exit according to the boolean value (0|1) of the key."
  >&2 echo "  get  key           Get the value of a leaf key."
  >&2 echo "  set  key [value]   Set the value of a leaf key. If value is omitted,"
  >&2 echo "                     read the value from stdin."
  >&2 echo "  list key           List sub-keys in a non-leaf key."
  >&2 echo "  remove key         Remove a key."
  >&2 echo "  enum key           Recursively enumerate all keys under the one specified."
  >&2 echo "  snapshot           Output a snapshot of the configuration on stdout."
  >&2 echo "  restore            Restore a snapshot from stdin."
  >&2 echo "  help               Show this help message."

  exit "$1"
}

check_key() {
  if ! echo "$1" | grep '^/[a-zA-Z0-9/_+-]*' > /dev/null
  then
    error "invalid key."
  fi

  key="${root}${key}"
}

[ $# -gt 0 ] || help_message 1
[ "$action" = help ] && help_message 0

case "$mode" in
  user)
    root=$user_root
    ;;
  system)
    root=$system_root
    ;;
  *)
    bad_usage "unknown mode"
    ;;
esac

if [ ! -d "$root" ]
then
  mkdir -p "$root"
fi

[ -d "$root" ] || error "root is not a directory"

case "$action" in
  get)
    check_key "$key"
    [ -r "$key" ] || error "key does not exist."
    [ -f "$key" ] || error "cannot get a non-leaf key."

    cat "$key"
    ;;
  is)
    check_key "$key"
    [ -r "$key" ] || error "key does not exist."
    [ -f "$key" ] || error "cannot get a non-leaf key."

    value=$(cat "$key")

    if [ "$value" == 1 ]
    then
      exit 0
    elif [ "$value" == 0 ]
    then
      exit 1
    else
      error "non boolean value."
    fi
    ;;
  set)
    check_key "$key"

    if [ ! -r "$key" ]
    then
      parent=$(dirname "$key")
      [ -d "$parent" -o ! -e "$parent" ] || error "cannot create inside a leaf key."
      mkdir -p "$parent"
      touch "$key"
    fi

    [ -f "$key" ] || error "cannot set a non-leaf key."

    if [ $# -lt 4 ]
    then
      cat > "$key"
    else
      echo "$value" > "$key"
    fi
    ;;
  list)
    check_key "$key"
    [ -r "$key" ] || error "key does not exist."
    [ -d "$key" ] || error "cannot list a leaf key."

    ls "$key"
    ;;
  remove)
    [ "$key" != "/" ] || error "cannot remove root key."
    check_key "$key"
    [ -r "$key" ] || error "key does not exist."

    if [ -d "$key" ]
    then
      if ! rmdir "$key" > /dev/null 2>&1
      then
        error "cannot remove non-empty key."
      fi
    else
      rm "$key"

      #FIXME: recursively delete parents if they are empty.
    fi
    ;;
  enum)
    check_key "$key"
    [ -r "$key" ] || error "key does not exist."

    find "$key" -print | sed "s#^$root##"
    ;;
  snapshot)
    tar -C "$root" -cf - .
    ;;
  restore)
    tar -C "$root" -xf -
    ;;
  *)
    bad_usage "unknown action"
    ;;
esac

exit 0
