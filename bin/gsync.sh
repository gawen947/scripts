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
VERSION="0.2"

# Default path and options
CONFIGURATION_PATH="$HOME/.config/gsync/gsync.conf"
PROFILES_PATH="$HOME/.config/gsync/profiles"
DIALOG="dialog" # could change with Xdialog
RSYNC="rsync"
RSYNC_OPTIONS="-avzhrR --progress --delete"

# We need some colors
# Regular           Bold                Underline           High Intensity      BoldHigh Intens     Background          High Intensity Backgrounds
Bla='\e[0;30m';     BBla='\e[1;30m';    UBla='\e[4;30m';    IBla='\e[0;90m';    BIBla='\e[1;90m';   On_Bla='\e[40m';    On_IBla='\e[0;100m';
Red='\e[0;31m';     BRed='\e[1;31m';    URed='\e[4;31m';    IRed='\e[0;91m';    BIRed='\e[1;91m';   On_Red='\e[41m';    On_IRed='\e[0;101m';
Gre='\e[0;32m';     BGre='\e[1;32m';    UGre='\e[4;32m';    IGre='\e[0;92m';    BIGre='\e[1;92m';   On_Gre='\e[42m';    On_IGre='\e[0;102m';
Yel='\e[0;33m';     BYel='\e[1;33m';    UYel='\e[4;33m';    IYel='\e[0;93m';    BIYel='\e[1;93m';   On_Yel='\e[43m';    On_IYel='\e[0;103m';
Blu='\e[0;34m';     BBlu='\e[1;34m';    UBlu='\e[4;34m';    IBlu='\e[0;94m';    BIBlu='\e[1;94m';   On_Blu='\e[44m';    On_IBlu='\e[0;104m';
Pur='\e[0;35m';     BPur='\e[1;35m';    UPur='\e[4;35m';    IPur='\e[0;95m';    BIPur='\e[1;95m';   On_Pur='\e[45m';    On_IPur='\e[0;105m';
Cya='\e[0;36m';     BCya='\e[1;36m';    UCya='\e[4;36m';    ICya='\e[0;96m';    BICya='\e[1;96m';   On_Cya='\e[46m';    On_ICya='\e[0;106m';
Whi='\e[0;37m';     BWhi='\e[1;37m';    UWhi='\e[4;37m';    IWhi='\e[0;97m';    BIWhi='\e[1;97m';   On_Whi='\e[47m';    On_IWhi='\e[0;107m';
RCol='\e[0m' # Text Reset

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

error() {
  >&2 echo -e "${BRed}error:${RCol}" $*
}

info() {
  >&2 echo -e "${BBlu}info:${RCol}" $*
}

check_binary() {
  binary=$1

  if [ -z "$package" ]
  then
    package=$binary
  fi

  if ! which "$binary" > /dev/null
  then
    error "cannot find $binary"
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

check_binary "$RSYNC"
check_binary "$DIALOG"

rsync_options="$RSYNC_OPTIONS"

dry_run=false
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
    dry_run=true
    ;;
  \?)
    error "invalid option -$OPTARG"
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

  profile_selected=$(mktemp)

  find "$PROFILES_PATH" -type d -maxdepth 1 | while read profile
  do
    profile_name=$(basename "$profile")
    if echo "$profile_name" | grep "^_" > /dev/null
    then
      continue
    fi

    [ ! -d "$profile" -o \
      ! -r "$profile"/desc -o \
      ! -r "$profile"/files ] && continue
    echo $profile_name
    head -n1 "$profile"/desc
  done | tr '\n' '\0' | xargs -0 "$DIALOG" --menu "Profile selection" 0 0 0 2> "$profile_selected"

  profile=$(cat "$profile_selected")
  rm -f "$profile_selected"

  if [ -z "$profile" ]
  then
    error "No profile selected."
    exit 1
  fi
  ;;
2)
  remote="$1"
  profile="$2"
  ;;
*)
  error "one or two arguments required"
  >&2 echo
  usage
  exit 1
  ;;
esac

profile_path="$PROFILES_PATH"/"$profile"

if [ ! -d "$profile_path" ]
then
  error "Cannot read profile ${Blu}$profile${RCol}."
  error "profiles must be directories"
  error "located in ${Cya}$PROFILES_PATH${Rcol}."
  exit 1
fi

if [ ! -r "$profile_path"/desc ]
then
  # FIXME: Perhaps this shouldn't be mandatory."
  error "The desc was not found in the profile."
  error "This file provides a description"
  error "of the profile. The first line should"
  error "provide a short description that is used"
  error "for the selection menu."
fi

if [ ! -r "$profile_path"/files ]
then
  error "The files was not found in the profile."
  error "This is a list of source files"
  error "for this synchronization profile."
  exit 1
fi

echo -e "Profile selected ${Blu}$profile${RCol}:${BWhi}"
cat "$profile_path"/desc
echo -e "${RCol}"

exclude_preprocessed=$(mktemp)
include_preprocessed=$(mktemp)
files_preprocessed=$(mktemp)

preprocess() {
  cat "$2" | while read line
  do
    if echo "$line" | grep "^#" > /dev/null
    then
      continue
    fi
    if echo "$line" | grep "^ *$" > /dev/null
    then
      continue
    fi

    if echo "$line" | grep "^:include " > /dev/null
    then
      included_profile=$(echo "$line" | sed 's/^:include //')

      info "include ${Blu}$included_profile${RCol}"

      tmp_preprocessed=$(mktemp)
      preprocess "$1" "$PROFILES_PATH"/"$included_profile"/"$1" "$tmp_preprocessed"
      cat "$tmp_preprocessed" >> "$3"
      rm -f "$tmp_preprocessed"
    else
      echo "$line" >> "$3"
    fi
  done
}

if [ -r "$profile_path"/options ]
then
  info "Loading profile options."
  . "$profile_path"/options

  rsync_options="$rsync_options $RSYNC_EXTRA_OPTIONS"
fi

if [ -r "$profile_path"/exclude ]
then
  info "Loading exclude patterns."

  preprocess exclude "$profile_path"/exclude "$exclude_preprocessed"
  exclude_option="--exclude-from=$exclude_preprocessed"
fi

if [ -r "$profile_path"/include ]
then
  info "Loading include patterns."

  preprocess include "$profile_path"/include "$include_preprocessed"
  include_option="--include-from=$profile_path/include"
fi

preprocess files "$profile_path"/files "$files_preprocessed"

echo
echo -e "${BWhi}Syncing profile ${BBlu}$profile${BWhi} to ${BYel}$remote${BWhi}...${RCol}"
if $dry_run
then
  info "Dry-run! No changes will be made!"
fi
echo

set -x
"$RSYNC" $rsync_options --files-from="$files_preprocessed" \
         $exclude_option $include_option \
         "$HOME" \
         "$remote":

rm -f "$exclude_preprocessed" "$include_preprocessed" "$files_preprocessed"
