#!/bin/sh
# Copyright (c) 2014 David Hauweele <david@hauweele.net>

# Memory unit
FACTOR="$(rpnc 1024 1024 .)"
UNIT="MB"

# Ratio Active/Inactive that gives an activity of 100%
ACTIVITY_EQUIV_RATIO=6

pct() (printf "%3.2f%%" $(rpnc "$1" "$2" / 100 .))
to_unit() (printf "%.0f" $(rpnc "$1" "$FACTOR" / | cut -d'.' -f1))

# Retrieve memory information
case "$(uname -s)" in
  FreeBSD)
    get_sysctl() (sysctl "$1" | cut -d':' -f2 | sed 's/ *//g')
    get_mem() (
      page_count=$(get_sysctl "vm.stats.vm.v_${1}_count")
      rpnc "$page_count" "$page_size" .
    )

    page_size=$(get_sysctl hw.pagesize)

    mem_all=$(get_mem page)
    mem_free=$(get_mem free)
    mem_wire=$(get_mem wire)
    mem_active=$(get_mem active)
    mem_inactive=$(get_mem inactive)
    mem_cache=$(get_mem cache)

    swap_info=$(swapinfo -k | grep "/dev/" | awk '{ used+=$3; all+=$2; } END { print used, all ; }')
    swap_used=$(echo "$swap_info" | cut -d' ' -f1)
    swap_used=$(rpnc "$swap_used" 1024 .)
    swap_all=$(echo "$swap_info" | cut -d' ' -f2)
    swap_all=$(rpnc "$swap_all" 1024 .)

    wire_name="Wire    :"
    ;;
  Linux)
    get_mem() (
      kb=$(cat /proc/meminfo | grep "^${1}:" | grep -oE "[[:digit:]]+ kB" | sed 's/ kB//g')
      rpnc "$kb" 1024 .
    )

    mem_all=$(get_mem MemTotal)
    mem_free=$(get_mem MemFree)
    mem_wire=$(get_mem Buffers)
    mem_inactive=$(get_mem Inactive)
    mem_active=$(get_mem Active)
    mem_cache=$(get_mem Cached)

    swap_all=$(get_mem SwapTotal)
    swap_free=$(get_mem SwapFree)
    swap_used=$(rpnc "$swap_total" "$swap_free" -)


    wire_name="Buffers :"
    ;;
  *)
    echo "$(uname -s) is not supported yet."
    exit 1
    ;;
esac

# Compute details
mem_used=$(rpnc "$mem_active" "$mem_inactive" +)
mem_bufcache=$(rpnc "$mem_wire" "$mem_cache" +)
mem_usage=$(rpnc "$mem_used" "$mem_bufcache" +)

# Compute activity:
#  act/inact   => activity
#  0           ->  0%
#  1           ->  50%
#  EQUIV_RATIO ->  100%
act_a=$(rpnc $ACTIVITY_EQUIV_RATIO 1 - log 2 . inv)
act_b=$(rpnc $ACTIVITY_EQUIV_RATIO 2 -)
activity=$(rpnc $act_b $mem_active $mem_inactive / . 1 + log $act_a . 100 .)

# Display results
echo "Summary:"
echo "  Mem     : $(to_unit $mem_used)+$(to_unit $mem_bufcache) / $(to_unit $mem_all) $UNIT" \
  "($(pct $mem_used $mem_all) + $(pct $mem_bufcache $mem_all))"
if [ "$swap_used" -gt 0 ]
then
  echo "  Swap    : $(to_unit $swap_used) / $(to_unit $swap_all) MB" \
    "($(pct $swap_used $swap_all))"
fi
echo "  Usage   : $(pct $mem_usage $mem_all)"
echo "  Activity: $(printf '%2.2f%%' $activity)"
echo
echo "Details:"
echo "  Active  : $(to_unit $mem_active) $UNIT ($(pct $mem_active $mem_all))"
echo "  Inactive: $(to_unit $mem_inactive) $UNIT ($(pct $mem_inactive $mem_all))"
echo "  Cache   : $(to_unit $mem_cache) $UNIT ($(pct $mem_cache $mem_all))"
echo "  $wire_name $(to_unit $mem_wire) $UNIT ($(pct $mem_wire $mem_all))"
echo "  Total   : $(to_unit $mem_all) $UNIT"
