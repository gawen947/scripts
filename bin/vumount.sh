#!/bin/sh
#  Copyright (c) 2015, David Hauweele <david@hauweele.net>
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#   1. Redistributions of source code must retain the above copyright notice, this
#      list of conditions and the following disclaimer.
#   2. Redistributions in binary form must reproduce the above copyright notice,
#      this list of conditions and the following disclaimer in the documentation
#      and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
#  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This script unmounts removable devices located
# in /media and removes their mount point, if they exist.
# If no argument is given, it will list currently
# mounted devices.

MEDIA_ROOT=/media
DEV_ROOT=/dev
OS=$(uname -s)

export LC_ALL=C

parse_mount() {
  mount_point="$1"
  mount_line=$(mount | grep "on $mount_point")
  name=$(basename "$mount_point")

  if [ -z "$mount_line" ]
  then
    device="-"
    options="-"
    type="-"
  else
    case "$OS" in
      Linux|OpenBSD)
        device=$(echo "$mount_line" | awk '{ print $1 }')
        options=$(echo "$mount_line" | grep -Eo "\(.*\)" | tr -d '() ')
        type=$(echo "$mount_line" | grep -Eo "type [^ ]+" | sed 's/type //')
        ;;
      FreeBSD)
        device=$(echo "$mount_line" | awk '{ print $1 }')
        options=$(echo "$mount_line" | grep -Eo "\(.*\)" | tr -d '() ')
        type=$(echo "$options" | cut -d',' -f 1)
        options=$(echo "$options" | sed "s#^$type,##")
        ;;
      *)
        >&2 echo "error: unknown OS $OS"
        exit 1
        ;;
    esac
  fi

  echo -e "$name $type $device $options"
}

list_mount() {
  echo "NAME TYPE DEVICE OPTIONS"

  for name in $(ls "$MEDIA_ROOT")
  do
    mount_point="$MEDIA_ROOT/$name"

    if [ ! -d "$mount_point" ]
    then
      continue
    fi

    parse_mount "$mount_point"
  done
}

try_umount() {
  # Multiple cases
  #  1) absolute path to mount point
  #  2) absolute path to device
  #  3) device name
  case "$1" in
    "$MEDIA_ROOT"/*)
      mount_point="$1"
      ;;
    "$DEV_ROOT"/*)
      mount_point=$(mount | grep "^$1" | grep -Eo "on [^ ]+" | cut -d' ' -f 2)

      if [ -z "$mount_point" ]
      then
        >&2 echo "error: unknown device $1"
        exit 1
      elif ! echo "$mount_point" | grep "^$MEDIA_ROOT" > /dev/null
      then
        >&2 echo "error: device $1 does not mount on $MEDIA_ROOT"
        exit 1
      fi
      ;;
    *)
      mount_point="$MEDIA_ROOT/$1"
      ;;
  esac


  if [ -d "$mount_point" ]
  then
    # Check if target is mounted or unmounted
    # but mountpoint still exists.
    if ! mount | grep "on $mount_point" > /dev/null
    then
      echo "target not mounted"
    else
      umount -v "$mount_point"
    fi

    rmdir "$mount_point"
  else
    >&2 echo "error: target $mount_point does not exist"
    exit 1
  fi
}

case "$#" in
  0)
    if which column > /dev/null
    then
      list_mount | column -t
    else
      list_mount
    fi
    ;;
  1)
    try_umount "$1"
    ;;
  *)
    echo "usage: $(basename $0) [device-name]"
    exit 1
    ;;
esac
