#!/bin/sh

directory="$1"
if test -e "$directory"; then

  size=$(sh get_directory_size.sh "$directory")
  printf "%s" "$size"
  sleep 3
  printf "\r"
  sh ./"$0" "$directory"
else

  echo "ERROR: Directory does not exits"
  exit 1
fi
