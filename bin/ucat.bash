#!/bin/bash
# Universal Cat
#   Last Modified: 2011-09-18 01:51:28
#
#   Copyright (c) 2011
#       Pierre Hauweele <pierre@hauweele.net>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Parse options before processing the files.
# Do it the lazy way (don't reparse with getopts), as we know cat hasn't got
# any parameterized options.
opts=""
declare -a files
for arg in "$@"
do
  shift
  if test "${arg}" == "--"
  then
    break
  fi
  if test ${arg:0:1} == "-"
  then
    opts+=" $arg"
  else
    files=( "${files[@]}" "$arg" )
  fi
done

# Parse the rest of the arguments as files after a "--" argument.
for arg in "$@"
do
  files=( "${files[@]}" "$arg" )
done

# Call a form of [format]cat on each file.
# We decompress the file and pass it to cat instead of using [format]cat, so
# that we can keep the unified options of cat.
for file in "${files[@]}"
do
  format=( $(file -bL -- "$arg") )
  format=${format[0],,}
  case $format in
    # For those formats, the [de]compressor have the same options for
    # decompressing and output to stdout.
    bzip2 | gzip | lzma | xz)
      $format -dc -- "$file" | cat $opts --;;
    # If we can't recognize the compression format, consider it's plain text.
    *) cat $opts -- "$file";;
  esac
done

# Take care of an empty list of files.
if test ${#files[@]} -eq 0
then
  cat $opts
fi
