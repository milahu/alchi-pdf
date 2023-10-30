#!/bin/sh

# TODO add only git-tracked files

set -e

# empty
echo -n >index.html

function add() {
  echo "$1" >>index.html
}

add "<!doctype html>"
add "<html lang='en'>"
add "<body>"

add "<h1>alchi-pdf</h1>"

add "<section id='files'>"
add "<h2>files</h2>"
add "<ul>"
find . -name '*.pdf' -printf "%P\n" |
grep -v -e '\.booklet\.pdf$' -e '\.twopage\.pdf$' |
sort -r |
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
add "</section>"

add "<section id='sources'>"
add "<h2>sources</h2>"
add "<ul>"
add "<li><a href='https://github.com/milahu/alchi-pdf'>https://github.com/milahu/alchi-pdf</a></li>"
add "<li><a href='https://github.com/milahu/alchi'>https://github.com/milahu/alchi</a></li>"
add "</ul>"
add "</section>"

add "</body>"
add "</html>"

echo done index.html
