#!/bin/sh
# Petits crochets à laptop-mode pour un système avec énormément de RAM.
# Copyright (C) 2012 David Hauweele <david@hauweele.net>

hdparm -B 254 -S 20 /dev/sda > /dev/null
echo "60"   > /proc/sys/vm/laptop_mode
#echo "5"      > /proc/sys/vm/dirty_background_ratio
#echo "720000" > /proc/sys/vm/dirty_expire_centisecs
#echo "360000" > /proc/sys/vm/dirty_writeback_centisecs
echo "600"    > /proc/sys/vm/extfrag_threshold
echo "0"      > /proc/sys/vm/swappiness
echo "10"     > /proc/sys/vm/vfs_cache_pressure
echo "60"     > /proc/sys/vm/stat_interval
