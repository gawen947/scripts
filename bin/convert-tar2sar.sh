#!/bin/sh
# Copyright (c) 2013 David Hauweele

ext=$(echo "$1" | grep -E -o "\.[[:alnum:]]+(\.[[:alnum:]]+)?$")
name=$(basename "$1" "$ext")

case "$ext" in
  .tar.gz)
    comp="z"
    sext=".gz"
    ;;
  .tar.bz2)
    comp="j"
    sext=".bz2"
    ;;
  .tar.xz)
    comp="J"
    sext=".xz"
    ;;
  .tar.Z)
    comp="Z"
    sext=".Z"
    ;;
  .tar)
    comp=""
    sext="";;
  *)
    echo "cannot recognize the $ext format"
    return 0
    ;;
esac

dir=$(mktemp -d tmpXXXXXX)
 
echo "Decompress..."
tar -C $dir -${comp}xvf "$1"
echo "OK!"
echo ""

count=$(ls $dir | wc -l)
if [ $count != 1 ]
then
  echo "cannot compress a bomb archive"
  rm -rf $dir
  return 0
fi

echo "Compress..."
o_pwd=$(pwd)
cd $dir
sar -${comp}cvvvf $name.sar$sext *
cd $o_pwd
mv $dir/$name.sar$sext .
echo "OK!"
echo ""

echo "Delete temporary file..."
rm -rfv $dir
echo "OK!"
