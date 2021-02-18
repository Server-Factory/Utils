#!/bin/sh

while true; do

  here=$(dirname "$0")
  working_directory="$1"
  config_file="$working_directory"/proxy.cfg
  update_execute_script="$here"/proxy_update_execute.sh
  load_configuration_script="$here"/proxy_update_execute.sh

  if ! test -e "$load_configuration_script"; then

    echo "ERROR: $load_configuration_script does not exist"
    exit 1
  fi

  # shellcheck disable=SC1090,SC2039
  source "$load_configuration_script" "$config_file"

  # shellcheck disable=SC2154,SC2129
  sleep "$frequency"

  if test -e "$update_execute_script"; then

    # shellcheck disable=SC2154,SC2129
    sh "$update_execute_script" "$working_directory" "$host" "$port" "$account" "$password" \
      "$is_selfSigned_ca" "$certificate_endpoint"
  else

    echo "ERROR: $update_execute_script does not exist"
    exit 1
  fi
done
