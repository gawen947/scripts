#!/bin/sh
# Copyright (c) 2014-2015 David Hauweele <david@hauweele.net>

# Memory unit
FACTOR="$(rpnc 1024 1024 .)"
UNIT="MB"

pct() (printf "%3.2f%%" $(rpnc "$1" "$2" / 100 .))
to_unit() (printf "%.0f" $(rpnc "$1" "$FACTOR" / | cut -d'.' -f1))

# Retrieve memory information
case "$(uname -s)" in
  DragonFly|FreeBSD)
    get_sysctl() (sysctl "$1" | cut -d':' -f2 | sed 's/ *//g')
    get_mem() (
      page_count=$(get_sysctl "vm.stats.vm.v_${1}_count")
      rpnc "$page_count" "$page_size" .
    )

    page_size=$(get_sysctl hw.pagesize)

    mem_all=$(get_mem page)
    mem_free=$(get_mem free)
    mem_wire_or_buffer=$(get_mem wire)
    mem_active=$(get_mem active)
    mem_inactive=$(get_mem inactive)
    mem_cache=$(get_mem cache)

    swap_info=$(swapinfo -k | grep "/dev/" | awk '{ used+=$3; all+=$2; } END { print used, all ; }')
    swap_used=$(echo "$swap_info" | cut -d' ' -f1)
    swap_used=$(rpnc "$swap_used" 1024 .)
    swap_all=$(echo "$swap_info" | cut -d' ' -f2)
    swap_all=$(rpnc "$swap_all" 1024 .)

    wire_or_buffer_name="Wire    :"

    mem_used="$mem_active"
    mem_bufcache=$(rpnc "$mem_wire_or_buffer" "$mem_cache" "$mem_inactive" + +)
    ;;
  Linux)
    get_mem() (
      kb=$(cat /proc/meminfo | grep "^${1}:" | grep -oE "[[:digit:]]+ kB" | sed 's/ kB//g')
      rpnc "$kb" 1024 .
    )

    mem_all=$(get_mem MemTotal)
    mem_free=$(get_mem MemFree)
    mem_wire_or_buffer=$(get_mem Buffers)
    mem_inactive=$(get_mem Inactive)
    mem_active=$(get_mem Active)
    mem_cache=$(get_mem Cached)

    swap_all=$(get_mem SwapTotal)
    swap_free=$(get_mem SwapFree)


    wire_or_buffer_name="Buffers :"

    # "free used" = inact + act + buffer + cache
    swap_used=$(rpnc "$swap_total" "$swap_free" -)
    mem_used=$(rpnc "$mem_all" "$mem_free" - "$mem_wire_or_buffer" "$mem_cache" + -)
    mem_bufcache=$(rpnc "$mem_wire_or_buffer" "$mem_cache" +)
    ;;
  *)
    echo "$(uname -s) is not supported yet."
    exit 1
    ;;
esac

# Compute details
mem_usage=$(rpnc "$mem_used" "$mem_bufcache" +)

# Compute activity:
activity=$(rpnc $mem_active $mem_inactive /)

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
echo "  Activity: $(printf '%.2f' $activity)"
echo
echo "Details:"
echo "  Active  : $(to_unit $mem_active) $UNIT ($(pct $mem_active $mem_all))"
echo "  Inactive: $(to_unit $mem_inactive) $UNIT ($(pct $mem_inactive $mem_all))"
echo "  Cache   : $(to_unit $mem_cache) $UNIT ($(pct $mem_cache $mem_all))"
echo "  $wire_or_buffer_name $(to_unit $mem_wire_or_buffer) $UNIT ($(pct $mem_wire_or_buffer $mem_all))"
echo "  Total   : $(to_unit $mem_all) $UNIT"
