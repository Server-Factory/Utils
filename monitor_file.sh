#!/bin/sh

file="$1"
if test -e "$file"; then

  clear
  cat "$file"
  sleep 3
  sh ./"$0" "$file"
else

  echo "ERROR: File does not exits"
  exit 1
fi