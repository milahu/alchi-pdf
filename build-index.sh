#!/bin/sh

set -e

# empty
echo -n >index.html

function add() {
  echo "$1" >>index.html
}

add "<html>"
add "<ul>"
ls **/*.pdf | grep -v -e '\.booklet\.pdf$' -e '\.twopage\.pdf$' |
while read basefile
do
  base=${basefile%.*}
  add "<li>"
  add "  <div>$base</div>"
  add "  <ul>"
  subfiles=()
  for file in "$base"*.pdf
  do
    [[ "$file" != "$base.pdf" ]] && subfiles+=("$file")
  done
  for file in "$base.pdf" "${subfiles[@]}"
  do
    size="$(du -sh "$file" | cut -d$'\t' -f1)Byte"
    add "    <li><a href="$file">$file</a> ($size)</li>"
  done
  add "  </ul>"
  add "</li>"
done
add "</ul>"
add "</html>"

cat index.html
