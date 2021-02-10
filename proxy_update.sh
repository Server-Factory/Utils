#!/bin/sh

working_directory="$1"
log="$working_directory"/proxy_update.log
config_file="$working_directory"/proxy.cfg

date > "$log"

if ! test -e "$config_file"; then

  error="ERROR: $config_file does not exist"
  echo "$error" >> "$log"
  exit 1
fi

config=$(cat "$config_file")

# shellcheck disable=SC2129
echo "" >> "$log"
echo "Configuration:" >> "$log"
echo "$config" >> "$log"
echo "" >> "$log"

while read -r line; do

  echo ">>> $line" >> "$log"
done <"$config_file"

