#!/bin/sh

load_configuration() {

  # shellcheck disable=SC2039
  local config_file="$1"

  if ! test -e "$config_file"; then

    echo "ERROR: $config_file does not exist"
    exit 1
  fi

  echo "Loading configuration: $config_file"

  # shellcheck disable=SC2039
  local line=""
  while read -r line; do

    export IFS="="
    # shellcheck disable=SC2039
    local parameter_name=""
    for parameter in $line; do

      if [ "$parameter_name" = "" ]; then

        parameter_name="$parameter"
      else

        eval "$parameter_name"="$parameter"
      fi
    done
  done <"$config_file"

  echo "Configuration loaded: $config_file"
}
