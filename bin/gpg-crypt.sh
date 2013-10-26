#!/bin/sh
sendf=$(tempfile)
destf=$(tempfile)
messf=$(tempfile)
temp=$(tempfile)

echo "$GPG_DEFAULT_KEY" >> $sendf
echo "#################################" >> $sendf
echo "# Secret key to sign with.      #" >> $sendf
echo "#                               #" >> $sendf
echo "# This can be either a name or  #" >> $sendf
echo "# an email address.             #" >> $sendf
echo "#################################" >> $sendf

echo "" >> $destf
echo "#################################" >> $destf
echo "# Public key to send to.        #" >> $destf
echo "#                               #" >> $destf
echo "# This can be either a name or  #" >> $destf
echo "# an email address.             #" >> $destf
echo "#################################" >> $destf

echo "" >> $messf
echo "#################################" >> $messf
echo "# Enter your message here...    #" >> $messf
echo "#################################" >> $messf

vim $sendf
vim $destf
vim $messf

send="$(grep . $sendf | grep -v '^#')"
dest="$(grep . $destf | grep -v '^#')"
cat $messf | grep -v "^#" > $temp
cp $temp $messf; rm $temp

if [ -n "$send" -a -n "$dest" -a -s $messf ]
then
  gpg2 -esa -u "$send" -r "$dest" $messf
  vim $messf.asc
  rm $messf.asc
else
  echo "Private key / Destination key / Message not specified."
  echo "Nothing encrypted."
fi

rm $messf
rm $sendf
rm $destf
