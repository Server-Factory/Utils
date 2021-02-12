#!/bin/sh

file="$1"
if test -e "$file"; then

  content=$(tail "$file")
  printf "%s" "$content"
  sleep 3
  printf "\r"
  sh ./"$0" "$file"
else

  echo "ERROR: File does not exits"
  exit 1
fi