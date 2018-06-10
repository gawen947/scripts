#!/bin/sh
# Copyright(c) 2018 David Hauweele <david@hauweele.net>

WP_RANDOM="/tmp/wp-random_$DISPLAY.pid"
INHIBIT_XLOCK="/tmp/.inhibit-Xlock"
LVDS_PORT="LVDS1"
VGA_PORT="VGA1"

if [ -r "/usr/local/etc/dock.conf" ]
then
  . "/usr/local/etc/dock.conf"
elif [ -r "/etc/dock.conf" ]
then
  . "/etc/dock.conf"
fi

if [ "$#" = 0 ]
then
  echo "usage: $(basename $0) commands ..."
  echo "  status        Try to guess the current status."
  echo "  vga:(on|off)  Enable or disable the VGA output."
  echo "  lvds:(on|off) Enable or disable the LVDS output."
  echo "  iface:<name>  Change the active interface."
  echo "  sleep         Switch the laptop to sleep."
  echo "  lock:(on|off) Inhibit or reenable the locking mechanism on lid state change."
  echo "  lock          Lock the screen with xscreensaver."

  exit 1
fi

getarg() {
  echo "$1" | cut -d':' -f2
}

invalid_arg_onoff() {
  echo "invalid command argument: expected on or off."
  exit 1
}

cmd_status() {
  # Xrandr status
  echo -n "lvds     : "
  if echo "$_xrandr" | grep -E "^$LVDS_PORT [a-z]* [0-9]+x[0-9]+" > /dev/null
  then
    echo "on"
  else
    echo "off"
  fi
  echo -n "vga      : "
  if echo "$_xrandr" | grep -E "^$VGA_PORT [a-z]* [0-9]+x[0-9]+" > /dev/null
  then
    echo "on"
  else
    echo "off"
  fi

  # Lock status
  echo -n "lock     : "
  if [ -r "$INHIBIT_XLOCK" ]
  then
    echo "off"
  else
    echo "on"
  fi

  # Wallpaper status
  echo -n "wp daemon: "
  if [ -r "$WP_RANDOM" ]
  then
    echo "on"
  else
    echo "off"
  fi

  # Ifaces
  echo -n "ifaces   : "
  ifconfig |grep "^[a-z0-9]*:" | cut -d':' -f1 | grep -v "lo0" | grep -v "pflog0" | grep -v "tun0" | xargs echo
}

cmd_vga() {
  echo "vga => $1"
  case "$1" in
    on)  xrandr --output "$VGA_PORT" --auto --above "$LVDS_PORT";;
    off) xrandr --output "$VGA_PORT" --off;;
    *)
      invalid_arg_onoff;;
  esac

  # redraw wallpaper
  kill -USR1 $(cat "$WP_RANDOM")
}

cmd_lvds() {
  echo "lvds => $1"
  case "$1" in
    on)  xrandr --output "$LVDS_PORT" --auto --below "$VGA_PORT";;
    off) xrandr --output "$LVDS_PORT" --off;;
    *)
      invalid_arg_onoff;;
  esac

  # redraw wallpaper
  kill -USR1 $(cat "$WP_RANDOM")
}

cmd_sleep() {
  echo "sleep"
  sudo acpiconf -s3
}

cmd_lock() {
  echo "lock => $1"
  case "$1" in
    on) rm -f "$INHIBIT_XLOCK";;
    off) touch "$INHIBIT_XLOCK";;
    *)
      invalid_arg_onoff;;
  esac
}

cmd_lock_screen() {
  echo "lock"
  xscreensaver-command -lock
}

cmd_iface() {
  # FIXME: The magic lies beyond...
  sudo /root/iface.sh "$1"
}

_xrandr=$(xrandr)
sleep 1

while [ "$#" -gt 0 ]
do
  case "$1" in
    status) cmd_status;;
    vga:*) cmd_vga $(getarg "$1");;
    lvds:*) cmd_lvds $(getarg "$1");;
    iface:*) cmd_iface $(getarg "$1");;
    sleep) cmd_sleep;;
    lock:*) cmd_lock $(getarg "$1");;
    lock) cmd_lock_screen;;
    *)
      echo "unknown command $1"
      exit 1
      ;;
  esac
  shift
done
