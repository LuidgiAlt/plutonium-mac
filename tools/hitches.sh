#!/bin/bash
# Summarize BO2's own "Hitch warning" lines (frames slower than ~500 ms), with
# the last meaningful log line before each one, so load-time hitches can be
# told apart from gameplay hitches. Works with any renderer.
#   tools/hitches.sh            both console_zm.log and console_mp.log
#   tools/hitches.sh zm|mp      one of them
# BO2 rewrites a log each time that mode starts, so check before relaunching.
set -u
here=$(cd -- "$(dirname -- "$0")/.." && pwd)
plutonium=${PLUTONIUM_DIR:-$here/prefix/drive_c/users/crossover/AppData/Local/Plutonium}
dir="$plutonium/storage/t6/main"
modes=${1:-"zm mp"}
for mode in $modes; do
  log="$dir/console_$mode.log"
  [ -f "$log" ] || { echo "== $mode: no log"; continue; }
  echo "== $mode: $(sed -n 2p "$log") (last write $(date -r "$log" '+%H:%M:%S'))"
  awk '
    /^Hitch warning:/ {
      n++; ms = $3 + 0; total += ms; if (ms > max) max = ms
      if (ms >= 1000) big++
      printf "  %6d ms %-7s after: %s\n", ms, $(NF-1), substr(last, 1, 80)
      next
    }
    /^[[:space:]]*$/ || /^[[:space:]]+[a-zA-Z_0-9]+ "/ { next }   # blank lines, dvar dumps
    { last = $0 }
    END {
      if (!n) print "  no hitch warnings"
      else printf "  %d hitches, %d over 1 s, longest %d ms\n", n, big, max
    }' "$log"
done
