#!/bin/sh

working_directory="$1"
log="$working_directory"/proxy_update.log
config_file="$working_directory"/proxy.cfg

date_time=$(date)
echo "$date_time" > "$log"

if ! test -e "$config_file"; then

  error="ERROR: $config_file does not exist"
  echo "$error" >>"$log"
  exit 1
fi

config=$(cat "$config_file")
printf "\nConfiguration:\n\n%s\n\n" "$config" >>"$log"

while read -r line; do

  export IFS="="
  parameter_name=""
  for parameter in $line; do

    if [ "$parameter_name" = "" ]; then

      parameter_name="$parameter"
    else

      eval "$parameter_name"="$parameter"
    fi
  done
done <"$config_file"

# shellcheck disable=SC2154,SC2129
printf "Loaded parameters:\n\nhost=%s\nport=%s\naccount=%s\npassword=%s\n" "$host" "$port" "$account" "$password" >> "$log"
# shellcheck disable=SC2154,SC2129
printf "is_selfSigned_ca=%s\ncertificate_endpoint=%s\n" "$is_selfSigned_ca" "$certificate_endpoint" >> "$log"
# shellcheck disable=SC2154,SC2129
printf "delayed=%s\nutils=%s\n" "$delayed" "$utils" >> "$log"


echo "$date_time" >> "$log"