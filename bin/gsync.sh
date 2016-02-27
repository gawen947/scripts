#!/bin/sh
#  Copyright (c) 2016, David Hauweele <david@hauweele.net>
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

NAME="gsync"
VERSION="0.1"

# Default path and options
CONFIGURATION_PATH="$HOME/.config/gsync/gsync.conf"
PROFILES_PATH="$HOME/.config/gsync/profiles"
RSYNC_PATH="rsync"
RSYNC_OPTIONS="-avzh --progress --delete"

RCol='\e[0m'    # Text Reset

# Regular           Bold                Underline           High Intensity      BoldHigh Intens     Background          High Intensity Backgrounds
Bla='\e[0;30m';     BBla='\e[1;30m';    UBla='\e[4;30m';    IBla='\e[0;90m';    BIBla='\e[1;90m';   On_Bla='\e[40m';    On_IBla='\e[0;100m';
Red='\e[0;31m';     BRed='\e[1;31m';    URed='\e[4;31m';    IRed='\e[0;91m';    BIRed='\e[1;91m';   On_Red='\e[41m';    On_IRed='\e[0;101m';
Gre='\e[0;32m';     BGre='\e[1;32m';    UGre='\e[4;32m';    IGre='\e[0;92m';    BIGre='\e[1;92m';   On_Gre='\e[42m';    On_IGre='\e[0;102m';
Yel='\e[0;33m';     BYel='\e[1;33m';    UYel='\e[4;33m';    IYel='\e[0;93m';    BIYel='\e[1;93m';   On_Yel='\e[43m';    On_IYel='\e[0;103m';
Blu='\e[0;34m';     BBlu='\e[1;34m';    UBlu='\e[4;34m';    IBlu='\e[0;94m';    BIBlu='\e[1;94m';   On_Blu='\e[44m';    On_IBlu='\e[0;104m';
Pur='\e[0;35m';     BPur='\e[1;35m';    UPur='\e[4;35m';    IPur='\e[0;95m';    BIPur='\e[1;95m';   On_Pur='\e[45m';    On_IPur='\e[0;105m';
Cya='\e[0;36m';     BCya='\e[1;36m';    UCya='\e[4;36m';    ICya='\e[0;96m';    BICya='\e[1;96m';   On_Cya='\e[46m';    On_ICya='\e[0;106m';
Whi='\e[0;37m';     BWhi='\e[1;37m';    UWhi='\e[4;37m';    IWhi='\e[0;97m';    BIWhi='\e[1;97m';   On_Whi='\e[47m';    On_IWhi='\e[0;107m';

version() {
  >&2 echo "$NAME v$VERSION"
}

usage() {
  >&2 echo "usage: $(basename $0) [option...] remote [profile]"
  >&2 echo
  >&2 echo "  -h Display this help message"
  >&2 echo "  -V Display version"
  >&2 echo "  -n Perform a trial with no changes made"
}

check_binary() {
  binary=$1
  package=$2

  if [ -z "$package" ]
  then
    package=$binary
  fi

  if ! which "$binary" > /dev/null
  then
    >&2 echo "error: missing dependency $package"
    exit 1
  fi
}

if [ -e "$CONFIGURATION_PATH" ]
then
  . "$CONFIGURATION_PATH"
fi

if [ ! -d "$PROFILES_PATH" ]
then
  mkdir -p "$PROFILES_PATH"
fi

check_binary "$RSYNC_PATH" rsync
check_binary dialog dialog

rsync_options="$RSYNC_OPTIONS"

hclr="${BRed}"
while getopts ":hVn" argv
do
  case "$argv" in
  h)
    version
    >&2 echo
    usage
    exit 0
    ;;
  V)
    version
    exit 0
    ;;
  n)
    rsync_options="$rsync_options -n"
    hclr="${Blu}"
    ;;
  \?)
    >&2 echo "error: invalid option -$OPTARG"
    >&2 echo
    usage
    exit 1
    ;;
  esac

  shift
done

case "$#" in
1)
  remote="$1"
  # FIXME: The fselect dialog kind of sucks...
  # Anything better is welcome!
  profile=$(dialog --fselect "$PROFILES_PATH" 0 0)
  ;;
2)
  remote="$1"
  profile="$PROFILES_PATH/$2"
  ;;
*)
  >&2 echo "error: one or two arguments required"
  >&2 echo
  usage
  exit 1
  ;;
esac

if [ ! -r "$profile" ]
then
  >&2 echo "error: cannot read profile"
  exit 1
fi

cat "$profile" | while read line
do
  case "$line" in
  \#|"")
  ;;
  esac

  # FIXME: We don't check the no trailing slash at the end of the target ($0).
  echo
  echo "$line" | xargs sh -c "echo -e \"${hclr}syncing '${BYel}\$0${hclr}' to ${BBlu}$remote${hclr} (extra-opt: '${BPur}\$*${hclr}')...${RCol}\""
  echo "$line" | xargs sh -c "rsync $rsync_options \$* \"$HOME/\$0\"/ \"$remote\":\"$HOME/\$0\""
done
