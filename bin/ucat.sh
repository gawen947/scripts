#!/bin/sh
#  Copyright (c) 2018, David Hauweele <david@hauweele.net>
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

do_cat() {
  file="$1"
  shift

  ext=$(echo "$i" | grep -Eo "\.[a-zA-Z0-9]+$" | tr '[:upper:]' '[:lower:]')

  case "$ext" in
  .xz) xzcat $*;;
  .gz) gzcat $*;;
  .lz) lzcat $*;;
  .bz) bzcat $*;;
  .z)  zcat  $*;;
  *)   cat   $*;;
  esac
}

# Assemble all option first
for i in $*
do
  case "$i" in
  --)
    break
    ;;
  -*)
    args="$args $i"
    ;;
  esac
done

# Cat all files before --
for i in $*
do
  shift
  case "$i" in
  --)
    break
    ;;
  -*)
    # ignore
    ;;
  *)
    do_cat "$i" $args "$i"
    ;;
  esac
done

# Cat all files after --
for i in $*
do
  do_cat "$i" $args -- "$i"
done
