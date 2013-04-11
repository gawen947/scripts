#!/bin/bash
# Copyright (c) 2012 Hauweele

find . -name "Makefile" | xargs cat > REVMakefiles
lsmod | grep -o "^\w*" | while read module
do
 echo "### $module ###"
 module="$(echo $module.o | sed -r "s/(_|-)/(_|-)/g")"
 grep -nE "\b$module\b" REVMakefiles
done
