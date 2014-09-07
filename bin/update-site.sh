#!/bin/sh
# Copyright (c) 2013-2014 David Hauweele <david@hauweele.net>

do_sha1()
(
  case "$(uname -s)" in
    FreeBSD)
      sha1 "$1" | cut -d'=' -f 2 | sed 's/^ *//';;
    Linux)
      sha1sum "$1" | cut -d' ' -f 1 | sed 's/^ *//';;
    *)
      echo "Unknown operating system..."
      echo "How can I hash a file?"
      exit 1
      ;;
  esac
)

o_pwd=$(pwd)
tmp=$(mktemp)
tmp2=$(mktemp)
sitecache=$(mktemp)
cp $HOME/.site-cache $sitecache
cd $HOME/public_html
for file in *.xml
do
  echo -n "Process $file... "
  xsltproc xslt/page.xsl "$file" > "$tmp"
  sha1=$(do_sha1 "$tmp")

  if grep -qs "$sha1 $file" "$sitecache"
  then
    echo "Fresh!"
  else
    echo -n "Refreshing... "
    basefile=$(basename $file .xml).html
    cp "$tmp" "$basefile"
    chmod a+r "$basefile"

    grep -v "$file" "$sitecache" > "$tmp2"
    cp "$tmp2" "$sitecache"
    echo "$sha1 $file" >> "$sitecache"
    echo "Done!"
  fi
done
cp $sitecache $HOME/.site-cache
rm $tmp
rm $tmp2
rm $sitecache
cd $o_pwd
