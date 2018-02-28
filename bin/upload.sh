#!/bin/sh
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

UP_URL="smeagol.hauweele.net"
UP_PATH="public_html/upload"
DOWN_URL="http://hauweele.net/~$USER/upload"
DOWN_URL2="http://apostr.ovh/~$USER/upload"
DEFAULT_UPNAME="${USER}_$(date +"%Y-%m-%d")"
MKTEMP_TEMPLATE="XXXXXX"
TAR_COMPRESSION="Jv"
TAR_EXTENSION="tar.xz"

if [ $# -lt 2 ]
then
  echo "usage: $0 TTL FILES..."
  exit 1
fi

ttl=$1
ttl_unit=$(echo $ttl | sed 's/^[[:digit:]]*//')

case "$ttl_unit" in
    s) factor=1;;
    m) factor=60;;
    h) factor=3600;;
    d) factor=86400;;
    w) factor=604800;;
    y) factor=31536000;;
    *)
        echo "Unknown ttl unit."
        echo "Did you mean:"
        echo " s - seconds ?"
        echo " m - minutes ?"
        echo " h - hours ?"
        echo " d - days ?"
        echo " w - weeks ?"
        echo " y - years ?"
        exit 1
        ;;
esac

ttl=$(echo $ttl | sed "s/$ttl_unit//")
ttl=$(rpnc $(date +"%s") $ttl $factor . +)

# Now we process the FILES arguments
shift

if [ "$#" -gt 1 -o -d "$1" ]
then
  # If we upload multiple files or a directory
  # then we use an archive.
  file=$(mktemp)
  tar -${TAR_COMPRESSION}cf "$file" "$@"
  echo

  if [ "$#" -gt 1 ]
  then
    # Request a name for multiple uploads.
    echo "There are multiple files in this upload."
    echo "They have been compressed into a $TAR_EXTENSION archive."
    echo "What shall be the name of this archive? "
    echo -n " "
    read filename
  else
    echo "This is a directory."
    echo "It has been compressed into a $TAR_EXTENSION archive."
    filename="$(basename $1)"

    if [ "$filename" = "." -o "$filename" = ".." ]
    then
      # Scrap . and .. directory.
      # Resetting to an empty filename will force
      # to use the default upname later.
      filename=""
    fi
  fi

  if [ -z "$filename" ]
  then
    echo "Ambigous or no name supplied..."
    echo "Using '$DEFAULT_UPNAME' instead."
    filename="$DEFAULT_UPNAME"
  fi

  filename="$filename.$TAR_EXTENSION"
else
  file="$1"
  filename=$(basename "$file")
fi

if [ ! -r "$file" ]
then
  echo "error: cannot read file."
  exit 1
fi

echo "Uploading as '$filename'."

upname=$(basename $(ssh $UP_URL "mktemp $UP_PATH/$MKTEMP_TEMPLATE"))

# We redirect stdout to stderr so the only line present on stdout is the fetch URL.
rsync --progress "$file" $UP_URL:$UP_PATH/$upname 1>&2

ssh $UP_URL "echo $upname $ttl  >> ~/.uploaded-limit; echo \"$upname $filename\" >> ~/.uploaded-map; chmod a+r $UP_PATH/$upname" 1>&2

if [ "$#" -gt 1 -o -d "$1" ]
then
  rm "$file"
  echo "Removing temporary archive."
fi

echo "" 1>&2
echo "Uploaded:" 1>&2
echo " $DOWN_URL/$upname"
echo " $DOWN_URL2/$upname"
