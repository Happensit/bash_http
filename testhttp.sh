#!/usr/bin/env bash

#nc -l -p 8080 -e "$PWD$0"

send() {
   printf '%s\r\n' "$*";
}


DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
declare -a RESPONSE_HEADERS=(
      "Date: $DATE"
   "Expires: $DATE"
    "Server: Test Bash HTTP Server"
)

add_response_header() {
   RESPONSE_HEADERS+=("$1: $2")
}

declare -a HTTP_RESPONSE=(
   [200]="OK"
   [400]="Bad Request"
   [403]="Forbidden"
   [404]="Not Found"
   [405]="Method Not Allowed"
   [500]="Internal Server Error"
)

send_response() {
   local code=$1
   send "HTTP/1.0 $1 ${HTTP_RESPONSE[$1]}"
   for i in "${RESPONSE_HEADERS[@]}"; do
      send "$i"
   done
   send
   while read -r line; do
      send "$line"
   done
}

fail_with() {
   send_response "$1" <<< "$1 ${HTTP_RESPONSE[$1]}"
   exit 1
}

get_file() {
   local file=$1

   CONTENT_TYPE=
   case "$file" in
     *\.css)
       CONTENT_TYPE="text/css"
       ;;
     *\.js)
       CONTENT_TYPE="text/javascript"
       ;;
     *)
       read -r CONTENT_TYPE   < <(file -b --mime-type "$file")
       ;;
   esac

   add_response_header "Content-Type"   "$CONTENT_TYPE"
   read -r CONTENT_LENGTH < <(stat -c'%s' "$file")         && \
    add_response_header "Content-Length" "$CONTENT_LENGTH"
   send_response 200 < $file
}

read -r line

line=${line%%$'\r'}

read -r REQUEST_METHOD REQUEST_URI REQUEST_HTTP_VERSION <<<"$line"

        [ -n "$REQUEST_METHOD" ] && \
        [ -n "$REQUEST_URI" ] && \
        [ -n "$REQUEST_HTTP_VERSION" ]\
|| fail_with 400

declare -a REQUEST_HEADERS

while read -r line; do
   line=${line%%$'\r'}
   # If we've reached the end of the headers, break.
   [ -z "$line" ] && break
   REQUEST_HEADERS+=("$line")
done

get_file ${REQUEST_URI#"/"}


