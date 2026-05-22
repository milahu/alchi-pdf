#!/bin/sh

# get cover image of pdf document

for bin in magick; do
  if ! command -v $bin; then
    echo "error: missing program: $bin"
    exit 1
  fi
done

set -eux

src="$1"
if [ -z "$src" ]; then
  echo "missing argument: pdf file"
  exit 1
fi

ext="${src##*.}"
exit
if [ "$ext" != "pdf" ]; then
  echo "error: no pdf file: $src"
  exit 1
fi

base="${src%.*}" # remove .pdf extension

dst="$base.cover.png"

magick -density 600 "$src[0]" -background white -alpha remove -alpha off "$dst"

echo "done $dst"
