#!/bin/sh
messf=$(tempfile)
outpf=$(tempfile)
tempf=$(tempfile)
echo "" >> $messf
echo "###################################" >> $messf
echo "# Enter the received message here #" >> $messf
echo "###################################" >> $messf

vim $messf
cat $messf | grep -v "^#" > $tempf
cp $tempf $messf; rm $tempf

if [ -s $messf ]
then
  gpg2 -d $messf > $outpf
  read null
  vim $outpf
else
  echo "Private key / Destination key / Message not specified."
  echo "Nothing encrypted."
fi

rm $messf
rm $outpf
