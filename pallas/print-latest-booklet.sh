#! /usr/bin/env bash

# this will use your default printer
# to use a different printer, pass arguments like
# ./print-latest-booklet.sh -d Brother_HL-L5100DN_2

cd "$(dirname "$0")"

options=(-o sides=two-sided-short-edge -o PageSize=A4 -o PrintQuality=600dpi)

pdf=$(find . -maxdepth 1 -name '*.booklet.pdf' -printf "%P\n" | sort -r | head -n1)

set -x

exec \
lp "$pdf" "${options[@]}" "$@"
