#!/bin/sh

MUSIC_ROOT="$HOME/Music"
BITRATE="192"

case "$#" in
  1)
    file="$1"
    artist=$(basename "$file" | awk -F' - ' '{ print $1; }')
    album=$(basename "$file" | awk -F' - ' '{ print $2; }' | sed 's/\.[a-z]*$//')
    ;;
  2)
    artist="$1"
    file="$2"
    album=$(basename "$file" | awk -F' - ' '{ print $2; }' | sed 's/\.[a-z]*$//')
    ;;
  3)
    artist="$1"
    album="$2"
    file="$3"
    ;;
  *)
    echo "usage: $(basename $0) [artist [album]] zip|flac|ogg"
    exit 1
    ;;
esac

artist_path="$MUSIC_ROOT/$artist"
album_path="$artist_path/$album"

echo "Unpacking '$artist/$album'."

if [ ! -d "$artist_path" ]
then
  echo "Create artist '$artist'."
  mkdir "$artist_path"
fi

unpack_zip() {
  zipname=$(basename "$1")
  cp "$1" "$album_path"
  o_pwd=$(pwd)
  cd "$album_path"

  echo -n "Unzip album... "
  unzip "$zipname" > /dev/null
  echo "done!"

  cd "$o_pwd"
}

convert_cover() {
  cover=$(find "$album_path" -iname "cover.*" | head -n 1)
  if [ -n "$cover" ]
  then
    cover_base=$(basename "$cover")
    echo -n "Convert '$cover_base'... "
    orig_cover="$album_path/orig-$cover_base"
    mv "$cover" "$orig_cover"
    convert "$orig_cover" -quality 75 -resize 30% "$album_path/cover.jpg" > /dev/null
    echo "done!"
  fi
}

convert_ogg() {
  echo
  echo "Start conversion to OGG... "
  find "$album_path" -iname "*.flac" -exec convert-generic-to-ogg "$BITRATE" {} \;
  echo "Conversion to OGG done!"
  echo
}

clean() {
  echo -n "Clean... "
  find "$album_path" -iname "*.zip" -delete > /dev/null
  find "$album_path" -iname "*.flac" -delete > /dev/null
  echo "done!"
}

case "$file" in
  *.zip)
    if [ -d "$album_path" ]
    then
      echo "Album '$artist/$album' already exists."
      exit 1
    else
      echo "Create album '$artist/$album'."
      mkdir "$album_path"
    fi
    unpack_zip "$file"
    convert_cover
    convert_ogg
    clean
    ;;
  *.flac)
    album_path="$artist_path/${album}.flac"
    cp "$file" "$album_path"
    convert_ogg
    clean
    album_path="$artist_path/${album}.ogg"
    ;;
  *.ogg)
    album_path="$artist_path/${album}.ogg"
    cp "$file" "$album_path"
    ;;
esac

# Do 644
echo -n "Doing 644... "
chmod 755 "$artist_path"
find "$album_path" -type d -exec chmod 755 {} \;
find "$album_path" -type f -exec chmod 644 {} \;
echo "done!"
