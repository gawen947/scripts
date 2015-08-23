#!/bin/sh
#
#  Copyright (c) 2015, David Hauweele <david@hauweele.net>
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#   1. Redistributions of source code must retain the above copyright notice, this
#      list of conditions and the following disclaimer.
#   2. Redistributions in binary form must reproduce the above copyright notice,
#      this list of conditions and the following disclaimer in the documentation
#      and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
#  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

NAME="cviz"
VERSION="0.2"

# Default path
CFLOW_PATH="cflow"
DOT_PATH="dot"

# Default color (see dot)
CLR_PRIMARY=lightblue
CLR_SECONDARY=aquamarine3
CLR_SCHEME=ylorbr9
CLR_SCHEME_WIDTH=9
CLR_FONT_SWITCH=$((CLR_SCHEME_WIDTH - 2))

# We use this for compatibility
OS=$(uname -s)

# Cflow uses the CPP environment variable to choose a preprocessor.
# This variable is normally "$CC -E". If CC is not defined, cflow
# fall back to gcc. When running cflow from the command line these
# variable are generally not defined. The fallback is problematic
# on platform where the gcc compiler is not available. Therefore
# we override the default with the cc compiler that is just a
# synonym for the default compiler on most platform.
if [ -z "$CPP" ]
then
  if [ -z "$CC" ]
  then
    export CC=cc
  fi

  export CPP="$CC -E"
fi

version() {
  >&2 echo "$NAME v$VERSION"
}

usage() {
  >&2 echo "usage: $(basename $0) [option...] file..."
  >&2 echo
  >&2 echo "  -h Display this help message"
  >&2 echo "  -V Display version"
  >&2 echo "  -r Use reverse call graph"
  >&2 echo "  -e Display external symbols"
  >&2 echo "  -m Display multiple calls as multiple edges (no effect on GNU cflow)"
  >&2 echo "  -p Style pattern for the nodes (use list for a list)"
  >&2 echo "  -l Log scale for the style pattern"
  >&2 echo "  -o Output format (see dot, default: x11)"
  >&2 echo "  -H Switch to an horizontal layout"
  >&2 echo "  -C Extra arguments for cflow"
  >&2 echo "  -D Extra arguments for dot"
}

check_binary() {
  binary=$1
  package=$2

  if [ -z "$package" ]
  then
    package=$binary
  fi

  if ! which "$binary" > /dev/null
  then
    >&2 echo "error: missing dependency $package"
    exit 1
  fi
}

# Default values
dot_out_format="x11"
extern_symbols=false
multiple_calls=false
log_scale=false
pattern=scope
rankdir=LR

while getopts ":hVremp:lo:HC:D:" argv
do
  case "$argv" in
  h)
    version
    >&2 echo
    usage
    exit 0
    ;;
  V)
    version
    exit 0
    ;;
  r)
    cflow_args="$cflow_args -r"
    ;;
  e)
    extern_symbols=true
    ;;
  m)
    multiple_calls=true
    ;;
  p)
    case "$OPTARG" in
    list)
      echo "Available style patterns:"
      echo " scope:     Global or extern symbols (default)"
      echo " mono:      Same style for all nodes"
      echo " none:      No style applied"
      echo " edges_in:  Number of incoming edges"
      echo " edges_out: Number of outgoing edges"
      echo " edges:     Total number of edges"
      echo " max_depth: Maximum depth in the flowgraph"
      echo " min_depth: Minimum depth in the flowgraph"
      echo " depth:     Average depth in the flowgraph"
      exit 0
      ;;
    scope|none|mono|edges_in|edges_out|edges|max_depth|min_depth|depth)
      pattern="$OPTARG"
      ;;
    *)
      >&2 echo "error: unknown style pattern (use list for a list)"
      exit 1
      ;;
    esac
    shift
    ;;
  l)
    log_scale=true
    ;;
  o)
    dot_out_format="$OPTARG"
    shift
    ;;
  H)
    rankdir=TB
    ;;
  C)
    cflow_extra_args="$cflow_extra_args $OPTARG"
    shift
    ;;
  D)
    dot_extra_args="$dot_extra_args $OPTARG"
    shift
    ;;
  \?)
    >&2 echo "error: invalid option -$OPTARG"
    >&2 echo
    usage
    exit 1
    ;;
  esac

  shift
done

if [ $# = 0 ]
then
  >&2 echo "error: arguments required"
  >&2 echo
  usage
  exit 1
fi

check_binary bc
check_binary awk
check_binary cflow
check_binary dot graphviz

# We store the flowgraphs (output of cflow), the stack, nodes list,
# style and the generated dot graph in temporary files.
cflow_out=$(mktemp)
stack=$(mktemp)
edges=$(mktemp)
graph=$(mktemp)
nodes=$(mktemp)
styles=$(mktemp)
clean() {
  rm -f "$cflow_out" "$stack" "$edges" "$graph" "$nodes" "$styles"
}
clean_and_exit() {
  clean
  exit 0
}
trap clean_and_exit 0 1 2 14 15

# We need a stack to track the parent of
# the current symbol.
push() {
  echo "$*" >> "$stack"
}
get() {
  tail -n 1 "$stack"
}
pop() {
  get

  # FIXME: Also check for *BSD
  case "$OS" in
  Darwin)
    # FIXME:
    # Didn't test this on a Mac though...
    # I don't have one :)
    #
    sed -i '' -e '$ d' "$stack"
    ;;
  *)
    sed -i '$ d' "$stack"
    ;;
  esac
}

# Here we use the cflow command to generate the flowgraph of
# the C files given in argument. If the file do not exist
# or is not parseable, the command will report errors and fail.
#
# We use the posix format so that the parser stays similar
# across different version of the cflow tool (GNU vs BSD).
#
# We also replace the leading spaces and line numbers with a sharp so
# they do not interfer with the indentation level. Note that we must
# use a leading sharp character, otherwise the read line below would
# strip indentation spaces.
cflow --format=posix $cflow_args $CFLOW_EXTRA_ARGUMENTS $cflow_extra_args $* \
  | sed -E 's/^ *[0-9]+ /#/' \
  > "$cflow_out"
if [ $? != 0 ]
then
  echo "error: cannot generate flowgraphs"
  exit 1
fi

# Start the graph
echo "digraph G {" > "$graph"
echo "rankdir=$rankdir;" >> "$graph"

sel_field() {
  echo "$1" | cut -d':' -f"$2"
}
get_symbol() {
  sel_field "$1" 1
}
get_desc() {
  sel_field "$1" 2
}
get_indent() {
  echo "$1" | grep -o "^# *" | wc -c
}
get_node() {
  echo "$1" | sed 's/^# *//'
}

# The result of cflow is an indented tree of the flowgraph. Each line
# represents a node of the tree and the level of indentation its depth
# in the tree.  Nodes are displayed line by line using pre-order
# traversal according to the order each symbol is encountered in the C
# source.
#
# FIXME: The parsing might change with other versions of cflow
# (BSD in particular).
last_indent=0
while read line
do
  # Extract the information in the line so we know a bit more about
  # the node it depicts.
  current_indent=$(get_indent "$line")
  current_node=$(get_node "$line")
  current_symbol=$(get_symbol "$current_node")
  current_desc=$(get_desc "$current_node" | sed 's/^ //')

  # For brievety when a symbol reappear in the flowgraph, its
  # description is a reference to previous line. Since we map each
  # symbol to an unique node we recompose the node using the
  # reference.
  desc_ref=$(echo "$current_desc" | grep -E "^[[:digit:]]+$")
  if [ -n "$desc_ref" ]
  then
    current_desc=$(sed -n ${current_desc}p "$cflow_out" | cut -d':' -f 2 | sed 's/^ //')
  fi
  current_node="${current_symbol}:${current_desc}"

  # Store the recomposed node in a separate file.
  # We use this for single node and style pattern.
  echo "$current_node" >> "$nodes"

  if [ "$current_indent" -gt "$last_indent" ]
  then
    [ -n "$last_line" ] && push "$last_line"
  elif [ "$current_indent" -lt "$last_indent" ]
  then
    parent_indent="$current_indent"

    while true
    do
      parent_line=$(get)
      parent_indent=$(get_indent "$parent_line")

      if [ "$parent_indent" -lt "$current_indent" ]
      then
        break
      fi

      _=$(pop)
    done
  fi

  parent_line=$(get)

  if [ -n "$parent_line" ]
  then
    # Output an edge between two nodes.
    parent_node=$(get_node "$parent_line")
    parent_symbol=$(get_symbol "$parent_node")
    parent_desc=$(get_desc "$parent_node" | sed 's/^ //')

    if $extern_symbols || [ "$current_desc" != "<>" -a "$parent_desc" != "<>" ]
    then
      echo "$parent_symbol -> $current_symbol;" >> "$edges"
    fi
  fi

  last_line="$line"
  last_indent="$current_indent"
done < "$cflow_out"


# In this case the style is the same for all nodes.
if [ "$pattern" = "mono" ]
then
  style="[ style=filled, color=black, fillcolor=$CLR_PRIMARY ]"
fi

# Classify nodes according to the choosen style pattern.
# We need to do this offline because some styles require
# to compute their extrema.
cat "$nodes" | sort | uniq | while read line
do
  # Extract the information in the line so we know a bit more about
  # the node it depicts.
  current_node=$(get_node "$line")
  current_symbol=$(get_symbol "$current_node")
  current_desc=$(get_desc "$current_node" | sed 's/^ //')

  if $extern_symbols || [ "$current_desc" != "<>" ]
  then
    if [ "$current_desc" = "<>" ]
    then
      scope="extern"
    else
      scope="local"
    fi

    # Compute class for the choosen style.
    case "$pattern" in
    scope)
      info="$scope"
      ;;
    edges_in)
      info=$(cat "$edges" | grep "\-> $current_symbol;\$" | wc -l)
      ;;
    edges_out)
      info=$(cat "$edges" | grep "^$current_symbol ->" | wc -l)
      ;;
    edges)
      info=$(cat "$edges" | grep -E "^$current_symbol ->|-> $current_symbol;\$" | wc -l)
      ;;
    max_depth)
      info=$(cat "$cflow_out" | grep "$current_symbol:" \
             | grep -o "^# *" | wc -c \
             | awk 'BEGIN { max=0 } { if($0 > max) max=$0 } END { print max }')
      ;;
    min_depth)
      info=$(cat "$cflow_out" | grep "$current_symbol:" \
             | grep -o "^# *" | wc -c \
             | awk 'BEGIN { min=2**30 } { if($0 < min) min=$0 } END { print min }')
      ;;
    depth)
      info=$(cat "$cflow_out" | grep "$current_symbol:" \
             | grep -o "^# *" | wc -c \
             | awk '{ sum += $0; n++ } END { print sum / n }')
      ;;
    esac

    if echo "$info" | grep -E "[[:digit:]]+" > /dev/null && $log_scale
    then
      info=$(echo "l($info + 1)" | bc -l)
    fi

    echo "$current_symbol:$scope:$info" >> "$styles"
  fi
done

# We use the extrema to compute the range of color used for the styles.
# The dot_scale is the number of possible colors for dot styles (minus one).
# This depend on the colorscheme used in dot.
dot_scale=$(($CLR_SCHEME_WIDTH - 1))
max_style=$(cat "$styles" | cut -d':' -f 3 | awk 'BEGIN { max=0 }     { if($0 > max) max=$0 } END { print max }')
min_style=$(cat "$styles" | cut -d':' -f 3 | awk 'BEGIN { min=2**30 } { if($0 < min) min=$0 } END { print min }')

if echo "$max_style" | grep -E "[[:digit:]]+" > /dev/null
then
  delta=$(echo "$max_style - $min_style" | bc)
  offset=$(echo "$min_style * $dot_scale" | bc)
fi

# If any symbol has no edge (not called or does not call anyone in the
# flowgraph), we need to show them as single nodes. To do so we list
# all symbols and append them to the graph.
#
# We also use this to provide a style for each node.
# We define the color scale used with the colorscheme attribute.
# The scheme must be the same width as dot_scale (plus one).
while read line
do
  node=$(sel_field "$line" 1)
  scope=$(sel_field "$line" 2)
  info=$(sel_field "$line" 3)

  if $extern_symbols || [ "$scope" = "local" ]
  then
    # Apply the style for the node.  We do not classify anything here
    # but merely map the style to its representation in the dot
    # format.
    case "$pattern" in
    scope)
      if [ "$info" = "extern" ]
      then
        color="$CLR_SECONDARY"
      else
        color="$CLR_PRIMARY"
      fi

      style="[ style=filled, color=black, fillcolor=$color ]"
      ;;
    edges*|*depth)
      if [ "$delta" != 0 ]
      then
        color=$(echo "1 + (($dot_scale * $info) - $offset) / $delta" | bc)
      else
        color=1
      fi

      if [ $(echo "$color < $CLR_FONT_SWITCH" | bc) -eq 1 ]
      then
        text_color="black"
      else
        text_color="white"
      fi

      style="[ style=filled, color=black, fontcolor=$text_color, colorscheme=$CLR_SCHEME, fillcolor=$color ]"
      ;;
    esac
    echo "$node $style;" >> "$edges"
  fi
done < "$styles"

# If we come up empty, we stop here.
if [ ! -s "$edges" ]
then
  >&2 echo "warning: empty flowgraph"
  clean
  exit 0
fi

# Append the edges
if ! $multiple_calls
then
  sort "$edges" | uniq >> "$graph"
else
  cat "$edges" >> "$graph"
fi

# End the graph
echo "}" >> "$graph"

# Display the graph
if [ "$dot_out_format" = "dot" ]
then
  cat "$graph"
else
  dot -T"$dot_out_format" "$graph"
fi

clean
exit 0
