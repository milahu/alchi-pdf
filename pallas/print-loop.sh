#! /usr/bin/env bash

cd "$(dirname "$0")"

# options
# https://www.cs.utexas.edu/facilities/documentation/printing-options

# manual duplex: even -> odd
# -o sides=one-sided -o page-set=even
# -o sides=one-sided -o page-set=odd

#pdf="wersindmeinefreunde.2023-06-26.booklet.pdf"
#pdf="wersindmeinefreunde.2023-08-28.booklet.pdf"
#pdf="wersindmeinefreunde.2024-02-16.booklet.pdf"
#pdf="wersindmeinefreunde.2025-04-29.booklet.pdf"
pdf="wersindmeinefreunde.2025-11-19.booklet.pdf"
pdf=wersindmeinefreunde.2026-01-26.booklet.pdf
pdf=wersindmeinefreunde.2026-01-28.booklet.pdf
if [ -n "$1" ]; then
  pdf="$1"
fi
echo "pdf: $pdf"

printer_nums_name_prefix="Brother_HL-L5100DN_"
if false; then
printer_nums="1 2 3 4 5 6" # 5 einzug fail
printer_nums="1 2 3 4   6 7" # 7 is slow (but works)
printer_nums="1 2 3 4   6   8" # 3 makes (too many) vertical creases
printer_nums="1 2   4   6 7 8" # 4 is slow (overheating)
printer_nums="1 2       6 7 8" # 7 always says "toner empty"
printer_nums="1 2   4   6   8"
printer_nums="1 2   4 5 6   8" # 4 always says "toner empty"
printer_nums="1 2     5 6   8" # 1 2 5 creases
printer_nums="          6   8 9 10 11 12" # 9 broken?
printer_nums="      4   6   8   10 11 12" # 6 always says "toner empty"
printer_nums="      4       8   10 11 12 13"
printer_nums="      4           10 11 12 13 14" # 8 -> 14
printer_nums="1 2               10 11 12    14 15 16" # slow: 4 5 8 13 (overheating)
printer_nums="1 2   4 5     8   10 11 12 13 14 15 16" # falten: 16
printer_nums="1 2   4 5     8   10 11 12 13 14 15" # fixed fuser: 16
printer_nums="1 2   4 5     8   10 11 12 13 14 15 16" # falten: 5
printer_nums="1 2   4       8   10 11 12 13 14 15 16" # falten: 4
printer_nums="1 2           8   10 11 12 13 14 15 16" # fuser refurb: 4 5
printer_nums="1 2   4 5     8   10 11 12 13 14 15 16" # falten: 2 5
printer_nums="1     4       8   10 11 12 13 14 15 16 17" # papierstau: 8
printer_nums="1     4           10 11 12 13 14 15 16 17" # dirty fuser: 4
printer_nums="1                 10 11 12 13 14 15 16 17" # no toner: 7, fuser rebuild: 4 8, new: 18
printer_nums="1     4       8   10 11 12 13 14 15 16 17 18" # falten: 1, new: 19
printer_nums="      4       8   10 11 12 13 14 15 16 17 18 19" # jam: 4 8
printer_nums="                  10 11 12 13 14 15 16 17 18 19" # duplex jam: 15
printer_nums="                  10 11 12 13 14    16 17 18 19" # fuser rebuild: 1 2 5
printer_nums="1 2     5         10 11 12 13 14    16 17 18 19" # jam: 2 5
printer_nums="1                 10 11 12 13 14    16 17 18 19"
printer_nums="1 2     5         10 11 12 13 14    16 17 18 19" # broken fuser: 5
printer_nums="1 2               10 11 12 13 14    16 17 18 19" # broken fuser: 2
fi
printer_nums="1                 10 11 12 13 14    16 17 18 19"

# if true; then
if false; then
  printer_nums=
  printer_class=Brother_HL-L5100DN_all
fi



if [ -n "$printer_nums" ]; then
  for p in $printer_nums; do
    printer_name="$printer_nums_name_prefix$p"
    printer_name_list+=("$printer_name")
  done
elif [ -n "$printer_class" ]; then
  printer_name_list=(
    $(LANG=C lpstat -l -c "$printer_class" | tail -n+2 | tr -d $'\t')
  )
fi

if [ ${#printer_name_list[@]} = 0 ]; then
  echo "error: no printers declared. hint: set printer_nums or printer_class"
  exit 1
fi



# use the first printer for the pdf2raster conversion
# TODO group printers by printer model
pdf2raster_dest="${printer_name_list[0]}"



options=(
  -o sides=two-sided-short-edge
  -o PageSize=A4
  -o PrintQuality=600dpi
  -o scaling=100
  -o fit-to-page
  -o page-border=none
)

t1=0
t2=4m # time to print round + sleep time after round

# set -x # debug

# 4 * 2 = 8 rounds with fast printers
# 3 * 2 = 6 rounds with fast printers

# print only with one printer
#if true; then
if false; then
  sleep $t1; lp "$pdf" "${options[@]}" -d Brother_HL-L5100DN
  exit
fi

#rounds=3
rounds=4 # 4 * 60 = 240 of 250
#rounds=6 # 6 * 33 = 198 of 250
#rounds=7 # 7 * 33 = 231 of 250

if false; then
if [ -n "$1" ]; then
  rounds="$1"
fi
fi



# device for Brother_HL-L5100DN_19: dnssd://Brother%20HL-L5100DN%20series%20%5B3c2af4cbb32a%5D._ipp._tcp.local/?uuid=e3248000-80ce-11db-8000-3c2af4cbb32a
declare -A cups_printer_urls
while IFS= read -r line; do
  IFS=": " read printer_name printer_url <<<"${line:11}"
  cups_printer_urls[$printer_name]="$printer_url"
done < <(LANG=C lpstat -v)

declare -A avahi_printers
while IFS= read -r line; do
  if [ "${line:0:1}" = "+" ]; then
    continue
  fi
  if [ "${line:0:1}" = "=" ]; then
    # = enp2s0 IPv4 Brother HL-L5100DN series [3c2af4cbb32a]      _ipp._tcp            local
    printer_macaddr=
    printer_uuid=
    printer_name= # the CUPS printer name
    printer_hostname=
    printer_ipaddr=
    printer_port=
    printer_txt=
    # no. always parse printer_macaddr from printer_uuid
    if false; then
      printer_macaddr=$(echo "$line" | sed -E 's/^.* \[([0-9a-f]{12})\] .*$/\1/')
      if [ "$printer_macaddr" = "$line" ]; then
        printer_macaddr=
        echo "warning: failed to parse printer_macaddr from avahi-browse line=${line@Q}"
        # continue
      fi
    fi
    continue
  fi
  if [ "${line:0:13}" = "   hostname =" ]; then
    printer_hostname="${line:15: -1}"
  elif [ "${line:0:12}" = "   address =" ]; then
    printer_ipaddr="${line:14: -1}"
  elif [ "${line:0:9}" = "   port =" ]; then
    printer_port="${line:11: -1}"
  elif [ "${line:0:8}" = "   txt =" ]; then
    printer_txt="${line:10: -1}"

    # done printer

    if [ -z "$printer_macaddr" ]; then
      # get macaddr from uuid
      printer_uuid="$(echo "$printer_txt" | sed -E 's/^.*"UUID=([^"]+)".*$/\1/')"
      if [ "$printer_uuid" = "$printer_txt" ]; then
        echo "warning: failed to parse printer_uuid from avahi-browse printer_txt=${printer_txt@Q}"
        printer_uuid=
      else
        # printer_uuid=e3248000-80ce-11db-8000-b42200b873c0
        # printer_macaddr=b42200b873c0
        printer_macaddr="${printer_uuid##*-}"
      fi
    fi

    if [ -n "$printer_macaddr" ]; then
      # get the CUPS printer name
      for _printer_name in ${!cups_printer_urls[@]}; do
        _printer_url="${cups_printer_urls[$_printer_name]}"
        if echo "$_printer_url" | grep -qF "$printer_macaddr"; then
          printer_name="$_printer_name"
          # echo "ok: resolved printer_name=$printer_name from printer_macaddr=$printer_macaddr via printer_url=$_printer_url"
          break
        fi
      done
      if [ -z "$printer_name" ]; then
        echo "warning: failed to resolved printer_name from avahi-browse printer_macaddr=$printer_macaddr"
      fi
    fi

    if [ -z "$printer_name" ]; then
      continue
    fi
    if [ -z "$printer_ipaddr" ]; then
      echo "warning: failed to get printer_ipaddr of avahi-browse printer_name=$printer_name"
      continue
    fi
    if [ -z "$printer_port" ]; then
      echo "warning: failed to get printer_port of avahi-browse printer_name=$printer_name"
      continue
    fi

    printer_ipp_url="ipp://$printer_ipaddr:$printer_port/ipp/print"
    avahi_printers[$printer_name]="$printer_ipp_url"

    if false; then
      # verbose
      echo "found avahi printer:"
      if [ -n "$printer_uuid" ]; then
        echo "  printer_uuid: ${printer_uuid@Q}"
      fi
      echo "  printer_macaddr: ${printer_macaddr@Q}"
      # echo "  printer_hostname: ${printer_hostname@Q}"
      # echo "  printer_ipaddr: ${printer_ipaddr@Q}"
      # echo "  printer_port: ${printer_port@Q}"
      echo "  printer_ipp_url: ${printer_ipp_url@Q}"
      echo "  printer_name: ${printer_name@Q}"
      # echo "  printer_txt: ${printer_txt@Q}"
    else
      # short
      echo "found avahi printer: ${printer_name@Q} -> ${printer_ipp_url@Q}"
    fi
  else
    echo "warning: ignoring avahi-browse line=${line@Q}"
  fi
done < <(avahi-browse -rt _ipp._tcp)



pdf_hash=$(sha1sum "$pdf" | head -c40)

ppd_path="/etc/cups/ppd/$pdf2raster_dest.ppd"
cache_ppd_path="$pdf.$pdf_hash.ppd"

# FIXME this does not support duplex printing
# cupsfilter: No filter to convert from application/pdf to application/octet-stream.
# raster_mime_type=application/octet-stream
# raster_mime_type=application/vnd.cups-raster
raster_mime_type="printer/$pdf2raster_dest"
cache_raster_path="$pdf".$pdf_hash.raster.native

if true; then
# if false; then
  # PWG format does support duplex printing
  # FIXME the PWG format adds extra print margin
  raster_mime_type=image/pwg-raster
  cache_raster_path="$pdf".$pdf_hash.raster.pwg
fi

if ! head -c1 "$ppd_path" &>/dev/null; then
  # we need root access to read $ppd_path
  # FIXME make this work without root access
  if ! [ -e "$cache_ppd_path" ]; then
    echo "writing cache $cache_ppd_path"
    temp_ppd_path="$cache_ppd_path.tmp"
    if [ -e "$temp_ppd_path" ]; then
      rm "$temp_ppd_path"
    fi
    sudo cat "$ppd_path" >"$temp_ppd_path"
    mv "$temp_ppd_path" "$cache_ppd_path"
  fi
  ppd_path="$cache_ppd_path"
fi

if [ -e "$cache_raster_path" ] && [ "$(stat -c%s "$cache_raster_path")" = 0 ]; then
  echo "clearing empty cache $cache_raster_path"
  rm "$cache_raster_path"
fi

if ! [ -e "$cache_raster_path" ]; then
  echo "writing cache $cache_raster_path"
  temp_raster_path="$cache_raster_path.tmp"
  if [ -e "$temp_raster_path" ]; then
    rm "$temp_raster_path"
  fi
  cupsfilter -p "$ppd_path" -m $raster_mime_type "$pdf" "${options[@]}" >"$temp_raster_path"
  mv "$temp_raster_path" "$cache_raster_path"
fi

ipp_print_job="$(
  echo '{'
  echo '  OPERATION Print-Job'
  echo '  GROUP operation-attributes-tag'
  echo '    ATTR charset attributes-charset utf-8'
  echo '    ATTR language attributes-natural-language en'
  echo '    ATTR uri printer-uri $uri'
  echo '    ATTR name requesting-user-name "user"'
  echo '    ATTR name job-name "Broadcast Job"'
  echo '  GROUP job-attributes-tag'
  # echo '    ATTR rangeOfInteger page-ranges 21-30'
  echo '    ATTR keyword sides two-sided-short-edge'
  echo '    ATTR keyword print-scaling none'
  echo '    ATTR keyword media iso_a4_210x297mm'
  if [ "${raster_mime_type:0:6}" = "image/" ]; then
    echo "    ATTR mimeMediaType document-format $raster_mime_type"
  else
    echo '    ATTR mimeMediaType document-format application/octet-stream'
  fi
  echo "  FILE $cache_raster_path"
  echo '}'
)"
echo "ipp_print_job:"; echo "$ipp_print_job"
# exit # debug

for round in $(seq $rounds); do

  echo "round $round of $rounds"

  if [[ "$round" != "1" ]]; then
    # wait between rounds
    if [ "$t2" != 0 ]; then
      echo sleep $t2
      sleep $t2
    fi
    echo hit enter to print this round
    # TODO drain stdin before reading enter
    while true; do
      echo reading enter
      read user_input
      echo "user_input = '$user_input'"
      if [[ "$user_input" == "" ]]; then
        echo got enter
        break
      fi
    done
  fi

  # one round with slow printer
  #sleep $t1; lp "$pdf" "${options[@]}" -d Samsung_M3825_socket
  #sleep $t1; lp "$pdf" "${options[@]}" -d Brother_HL-L5100DN # FIXME slow

  # auto duplex
  for printer_name in "${printer_name_list[@]}"; do
    sleep $t1
    # lp "$pdf" "${options[@]}" -d "$printer_name"
    # lp -d "$printer_name" "${options[@]}" -o raw "$cache_raster_path"
    printer_ipp_url="${avahi_printers[$printer_name]}"
    echo ">" ipptool -tv "$printer_ipp_url" ipp_print_job.txt
    ipptool -tv "$printer_ipp_url" <(echo "$ipp_print_job") >/dev/null &
  done

  continue

  # see also: print-loop.manual-duplex.sh
  if false; then
    # manual duplex
    # workaround for vertical crease from auto duplex
    # front side
    # TODO loop $printer_nums
    sleep $t1; lp "$pdf" "${options[@]}" -d Brother_HL-L5100DN_3 -o sides=one-sided -o page-set=odd
    sleep $t1; lp "$pdf" "${options[@]}" -d Brother_HL-L5100DN_4 -o sides=one-sided -o page-set=odd
    sleep $t2
    echo TODO move paper from output to manual feed: Brother_HL-L5100DN_3, Brother_HL-L5100DN_4
    echo hit enter to print back side
    read
    # back side
    # TODO loop $printer_nums
    sleep $t1; lp "$pdf" "${options[@]}" -d Brother_HL-L5100DN_3 -o sides=one-sided -o page-set=even -o outputorder=reverse
    sleep $t1; lp "$pdf" "${options[@]}" -d Brother_HL-L5100DN_4 -o sides=one-sided -o page-set=even -o outputorder=reverse

    if false; then
      # two rounds with fast printers
      for k in $(seq 2); do
        round=$(((i-1)*2 + k))
        echo round $round
        # TODO loop $printer_nums
        sleep $t1; lp "$pdf" "${options[@]}" -d Brother_HL-L5100DN
        sleep $t1; lp "$pdf" "${options[@]}" -d Brother_HL-L5100DN_2
        #sleep $t1; lp "$pdf" "${options[@]}" -d Brother_HL-L5100DN_3 # FIXME vertical crease
        #sleep $t1; lp "$pdf" "${options[@]}" -d Brother_HL-L5100DN_4 # FIXME vertical crease
        sleep $t2
      done
    fi
  fi
done
