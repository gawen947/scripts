#!/bin/sh
# Copyright (c) 2015 David Hauweele <david@hauweele.net>

user_root="$HOME/.config/conf"
system_root="/usr/local/etc/conf"

if [ -r "/etc/conf.rc" ]
then
  . /etc/conf.rc
fi

mode=$1
action=$2
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
  >&2 echo "usage: $(basename $0) mode action [[key] value]"
  >&2 echo
  >&2 echo Mode:
  >&2 echo "  user               User configuration."
  >&2 echo "  system             System configuration."
  >&2 echo "  help               Show this help message."
  >&2 echo
  >&2 echo Actions:
  >&2 echo "  is   key           Exit according to the boolean value (0|1) of the key."
  >&2 echo "  get  key           Get the value of a leaf key."
  >&2 echo "  set  key [value]   Set the value of a leaf key. If value is omitted,"
  >&2 echo "                     read the value from stdin."
  >&2 echo "  list key           List sub-keys in a non-leaf key."
  >&2 echo "  create key         Create a leaf-key."
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

case "$mode" in
  help)
    help_message 0
    ;;
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

[ -d "$root" ] || error "root does not exist."

case "$action" in
  help)
    help_message 0
    ;;
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

    if [ "$key" == 1 ]
    then
      exit 0
    elif [ "$key" == 0 ]
    then
      exit 1
    else
      error "non boolean value."
    fi
    ;;
  set)
    check_key "$key"
    [ -r "$key" ] || error "key does not exist."
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
  create)
    check_key "$key"
    [ ! -r "$key" ] || error "key already exists."

    parent=$(dirname "$key")
    [ -d "$parent" -o ! -e "$parent" ] || error "cannot create inside a leaf key."

    mkdir -p "$parent"
    touch "$key"
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
