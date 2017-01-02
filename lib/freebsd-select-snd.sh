#!/bin/sh
# Copyright (c) 2016 David Hauweele <david@hauweele.net>

# We don't need root for hw.snd.default_unit
zenity_cmd=$(mktemp)

# Assemble zenity cmdline
cat /dev/sndstat | grep "pcm.*:" | while read pcm
do
  pcm_name=$(echo $pcm | cut -d':' -f 1)
  dev_name=$(echo $pcm | cut -d':' -f 2 | sed 's/^ //' | sed 's/ default$//' | grep -Eo "<.*>" | sed 's/[<>]//g')

  if echo $pcm | grep "default$" > /dev/null
  then
    value="TRUE"
  else
    value="FALSE"
  fi

  echo "$value" >> $zenity_cmd
  echo "\"$pcm_name\"" >> $zenity_cmd
  echo "\"$dev_name\"" >> $zenity_cmd
done

# Choose zenity
choice=$(cat $zenity_cmd | xargs zenity --list --text "Default soundcard?" --radiolist --column "Pick" --column "Dev." --column "Name")
if [ -z "$choice" ]
then
  echo "None choosed..."
else
  card=$(echo "$choice" | sed 's/^pcm//')
  echo "Selecting pcm$card as new default"

  sysctl hw.snd.default_unit=$card
fi

rm "$zenity_cmd"
