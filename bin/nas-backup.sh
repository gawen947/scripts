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

NAME="nas-backup"
VERSION="0.1"

# Default path and options
CONFIG_BASE=".config/nas-backup"
CONFIG_PATH="$HOME/$CONFIG_BASE"
CONFIG_FILE_PATH="$CONFIG_PATH/nas-backup.conf"
SITES_PATH="$CONFIG_PATH"
HISTORY_LOCAL_BASE="$CONFIG_BASE/history"
HISTORY_LOCAL_PATH="$HOME/$HISTORY_LOCAL_BASE"
RSYNC="rsync"
RSYNC_OPTIONS="-avhr --progress"

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
  >&2 echo "usage: $(basename $0) [option...] site [component]"
  >&2 echo
  >&2 echo "  -h Display this help message"
  >&2 echo "  -V Display version"
  >&2 echo "  -R Reverse sync (from NAS to local)"
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

if [ -e "$CONFIG_FILE_PATH" ]
then
  . "$CONFIG_FILE_PATH"
fi

check_binary "$RSYNC"

rsync_options="$RSYNC_OPTIONS $RSYNC_EXTRA_OPTIONS"

dry_run=false
while getopts ":hVRn" argv
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
  R)
    error "not implemented"
    exit 1
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
  site="$1"
  ;;
2)
  site="$1"
  component="$2"
  ;;
*)
  error "one or two arguments required"
  >&2 echo
  usage
  exit 1
  ;;
esac

site_path="$SITES_PATH"/"$site"

###
# The site directory contains a configuration file
# and multiple component directories.
#
# <site>/conf
#   - REMOTE_HOST: FQDN or IP of the NAS
#   - ENABLE_LOCAL_HISTORY (optional) : Enable local history of syncs.
#   - REMOTE_HISTORY (optional): Path to the history file on the NAS
# <site>/<component>
# <site>/<component>/
# <site>/<component>/conf
#   - REMOTE_PATH: Path of this component on the NAS
#   - BASE_PATH: Directory from which the sync is done.
#   - NO_DELETE (optional): Do not delete remote file if local copy doesn't exists
#   - RSYNC_EXTRA_OPTIONS (optional): Options added to the rsync command line
#   - DO_644 (optional): Do a chmod 755 on directory and 644 on files on the remote.
# <site>/<component>/files     (optional): see rsync --files-from
# <site>/<component>/exclude   (optional): see rsync --exclude
# <site>/<component>/include   (optional): see rsync --include-from
# <site>/<component>/no-delete (optional): see rsync --delete
##
if [ ! -d "$site_path" ]
then
  error "Cannot read site ${Blu}$site${RCol}."
  error "sites must be directories"
  error "located in ${Cya}$SITES_PATH${Rcol}."
  exit  1
fi

if [ ! -r "$site_path/conf" ]
then
  error "The configuration file was not found in the site."
  error "This mandatory file specifies the host to use"
  error "for this site (REMOTE_HOST)."
  exit 1
else
  info "Loading ${BCya}$site${RCol} site configuration."
  . "$site_path/conf"
fi

if [ -z "$REMOTE_HOST" ]
then
  error "The remote host (REMOTE_HOST) was not configured"
  error "in the site configuration ($site_path/conf)."
  exit 1
fi

exclude_preprocessed=$(mktemp)
include_preprocessed=$(mktemp)
files_preprocessed=$(mktemp)

preprocess() {
  cat "$1" | while read line
  do
    if echo "$line" | grep "^#" > /dev/null
    then
      continue
    fi
    if echo "$line" | grep "^ *$" > /dev/null
    then
      continue
    fi

    echo "$line" >> "$2"
  done
}

do_component() {
  component_path="$1"
  component=$(basename "$component_path")

  # Reset tmp files
  echo > "$exclude_preprocessed"
  echo > "$include_preprocessed"
  echo > "$files_preprocessed"

  if [ ! -r "$component_path/conf" ]
  then
    error "The configuration file was not found in the component."
    error "This mandatory file specifies the path of this component"
    error "on the NAS (REMOTE_PATH) along with other options."
  else
    info "Loading ${BBlu}$component${RCol} component configuration."
    . "$component_path/conf"
  fi

  if [ -z "$REMOTE_PATH" ]
  then
    error "The remote path (REMOTE_PATH) was not configured"
    error "in the component configuration ($component_path/conf)."
    exit 1
  fi

  if [ -z "$BASE_PATH" ]
  then
    error "The base path (BASE_PATH) was not configured"
    error "in the component configuration ($component_path/conf)."
    exit 1
  fi

  NO_DELETE=$(echo "$NO_DELETE" | tr '[:upper:]' '[:lower:]')
  case "$NO_DELETE" in
  true|yes|1|y)
    with_delete=""
    ;;
  *)
    rsync_options="$rsync_options --delete"
    with_delete="true"
    ;;
  esac

  if [ -n "$with_delete" ]
  then
    info "Sync ${BBlu}$component${RCol} to ${BCya}$site${RCol} ${BRed}with${RCol} remote deletion."
  else
    info "Sync ${BBlu}$component${RCol} to ${BCya}$site${RCol} ${BGre}without${RCol} remote deletion."
  fi

  if [ "$DO_644" = "true" ]
  then
    info "Final chmod 755/644 ${BRed}enabled${RCol}."
  else
    info "Final chmod 755/644 ${BGre}disabled${RCol}."
  fi

  rsync_options="$rsync_options $RSYNC_EXTRA_OPTIONS"

  if [ -r "$component_path"/exclude ]
  then
    info "Loading exclude patterns."
    preprocess "$component_path"/exclude "$exclude_preprocessed"
    exclude_option="--exclude-from=$exclude_preprocessed"
  fi
  if [ -r "$component_path"/include ]
  then
    info "Loading include patterns."
    preprocess "$component_path"/include "$include_preprocessed"
    include_option="--include-from=$include_preprocessed"
  fi
  if [ -r "$component_path"/files ]
  then
    info "Loading files list."
    preprocess "$component_path"/files "$files_preprocessed"
    files_option="--files-from=$files_preprocessed"
  fi

  echo
  echo -e "${BWhi}Syncing ${BBlu}$component${BWhi} to ${BYel}$site${BWhi}...${RCol}"
  if $dry_run
  then
    info "Dry-run! No changes will be made!"
  fi
  echo

  set -x
  "$RSYNC" $rsync_options \
           $exclude_option $include_option $files_option \
           "$BASE_PATH"/ \
           "$REMOTE_HOST":"$REMOTE_PATH"
  set +x

  if ! $dry_run
  then
    if [ "$DO_644" = "true" ]
    then
      info "Final chmod 755/644..."
      ssh "$REMOTE_HOST" "find '$REMOTE_PATH' -type d -exec chmod 755 {} \;; find '$REMOTE_PATH' -type f -exec chmod 644 {} \;"
    fi

    now=$(date)
    if [ "$ENABLE_LOCAL_HISTORY" = "true" ]
    then
      stamp="$now -- $component uploaded from me to $site ($REMOTE_HOST:$REMOTE_PATH)"
      echo "$stamp" >> "$HISTORY_LOCAL_PATH"
    fi
    if [ -n "$REMOTE_HISTORY" ]
    then
      stamp="$now -- $component uploaded from $USER@$(hostname) to me"
      ssh "$REMOTE_HOST" "echo $stamp >> $REMOTE_HISTORY" 1>&2
    fi
  fi
}

if [ -n "$component" ]
then
  do_component "$site_path/$component"
else
  find "$site_path" -type d -mindepth 1 -maxdepth 1 | while read component_path
  do
    echo "now doing '$component_path' => '$component'"
    component=$(basename "$component_path")

    # Components that start with '_' have to be selected manually.
    if echo "$component" | grep "^_" > /dev/null
    then
      continue
    fi

    [ ! -d "$component_path" -o \
      ! -r "$component_path"/conf ] && continue

    do_component "$component_path"

    echo "done with $component_path"
  done
fi

rm -f "$exclude_preprocessed" "$include_preprocessed" "$files_preprocessed"
