#!/bin/sh

file="$1"
if test -e "$file"; then

  clear
  content=$(cat "$file")
  printf "%s" "$content"
  sleep 3
  sh ./"$0" "$file"
else

  echo "ERROR: File does not exits"
  exit 1
fi