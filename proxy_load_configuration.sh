#!/bin/sh

config_file="$1"

if ! test -e "$config_file"; then

  echo "ERROR: $config_file does not exist"
  exit 1
fi

while read -r line; do

  export IFS="="
  parameter_name=""
  for parameter in $line; do

    if [ "$parameter_name" = "" ]; then

      parameter_name="$parameter"
    else

      eval "$parameter_name"="$parameter"
      # shellcheck disable=SC2163
      export "$parameter_name"
    fi
  done
done <"$config_file"
