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
  method=pkg
  case "$1" in
    port)   method=port;;
    pkg)    method=pkg;;
    "")     method=pkg;;
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
  pkg)
    pkg update
    pkg upgrade
    $CLEAN && pkg clean
    ;;
  port)
    _pwd=$(pwd)
    cd /usr/ports
    make update
    echo

    # Upgrade all locked ports
    pkg lock -lq | while read package
    do
      origin=$(pkg query '%o' "$package")
      echo "Upgrading locked $package from $origin"

      cd "/usr/ports/$origin"
      pkg unlock -y "$origin"
      make install clean
      make deinstall
      make reinstall
      pkg lock -y "$origin"
    done

    cd "$_pwd"
    ;;
  *)
    echo "Invalid method!"
    exit 1
    ;;
esac

exit 0
