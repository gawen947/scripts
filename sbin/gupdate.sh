#!/bin/sh

# Common options:
CLEAN=false

# FreeBSD options:
PORTMASTER_EXTRA="--delete-build-only -P"

# Detect the update method
os=$(uname -s)
if [ -r /etc/debian_version ]
then
  method=apt
elif [ "$os" = "FreeBSD" ]
then
  method=pkgng_portmaster
  case "$1" in
    port)   method=portmaster;;
    pkg)    method=pkgng;;
    "")     method=pkgng;;
    *)
      echo "Specify port or pkg (default: pkg)."
      exit 1
      ;;
  esac
fi

case "$method" in
  apt)
    apt-get update
    apt-get upgrade
    $CLEAN && apt-get clean
    ;;
  pkgng)
    pkg update
    pkg upgrade
    $CLEAN && pkg clean
    ;;
  portmaster)
    _pwd=$(pwd)
    cd /usr/ports
    make update
    portmaster -a $PORTMASTER_EXTRA
    cd "$_pwd"
    ;;
  pkgng_portmaster)
    $0 pkg
    $0 port
    ;;
  *)
    echo "Invalid method!"
    exit 1
    ;;
esac

exit 0
