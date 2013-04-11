#!/bin/sh
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

pids=$(tempfile)

error() (
  echo "error: " $1
  zenity --error --title "Error" --text "$1"
  rm $pids
)

# And it uses "zenity" aha pun...
type=$(zenity --list --text "Choose your relaxation type below" --column "Type" Underwater Rainforest)

case "$type" in
  Underwater)
    if [ -x /usr/lib/xscreensaver/atlantis -a -r $HOME/Musique/Relax/underwater.ogg ]
    then
      /usr/lib/xscreensaver/atlantis &
      echo $! >> $pids
      mplayer -loop 0 $HOME/Musique/Relax/underwater.ogg &
      echo $! >> $pids
    else
      error "cannot find a required file for underwater"
      exit 1
    fi
    ;;
  Rainforest)
    if [ -x $HOME/Photos/.relax -a -r $HOME/Musique/Relax/rainstorm.ogg ]
    then
      image=$(ls $HOME/Photos/.relax/rainforest/ | shuf - -n 1)
      feh -x $HOME/Photos/.relax/rainforest/$image &
      echo $! >> $pids
      mplayer -loop 0 $HOME/Musique/Relax/rainstorm.ogg &
      echo $! >> $pids
    else
      error "cannot find a required file for rainstorm"
      exit 1
    fi
    ;;
  "")
    echo "Cancel bye..."
    exit 0
    ;;
  *)
    error "invalid relax-type"
    exit 1
    ;;
esac

if zenity --question --title "Flurry" --text "Display second screensaver ?"
then
  if [ -x /usr/lib/xscreensaver/flurry ]
  then
    /usr/lib/xscreensaver/flurry&
    echo $! >> $pids
  else
    error "cannot find a required file for flurry"
    exit 1
  fi
fi

if [ $# = 1 ]
then
  echo "Sleep and stop"
  sleep $1
else
  echo "Wait and stop"
  fpid=$(cat $pids | head -n1)
  wait $fpid
fi

while read pid
do
  kill -TERM $pid
done < $pids

rm $pids
echo "Bye..."

exit 0

