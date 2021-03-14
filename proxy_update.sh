#!/bin/sh

here=$(dirname "$0")
working_directory="$1"

while true; do

  config_file_name="proxy.cfg"
  proxy_update_execute_script_name="proxy_update_execute.sh"
  load_configuration_script_name="proxy_load_configuration.sh"

  config_file="$working_directory/$config_file_name"
  proxy_update_execute="$here/$proxy_update_execute_script_name"
  load_configuration_script="$here/$load_configuration_script_name"

  if ! test -e "$load_configuration_script"; then

    echo "ERROR: $load_configuration_script does not exist"
    exit 1
  fi

  # shellcheck disable=SC1090
  . "$load_configuration_script"
  load_configuration "$config_file"

  # shellcheck disable=SC2154,SC2129
  sleep "$frequency"

  # shellcheck disable=SC2154
  if test -e "$log"; then

    if rm -f "$log"; then

      echo "$log: has been removed"
    else

      echo "WARNING: $log has not been removed"
    fi
  fi

  echo "Working directory: $working_directory" >>"$log"

  if test -e "$proxy_update_execute"; then

    # shellcheck disable=SC2154,SC2129
    if sh "$proxy_update_execute" "$working_directory" "$host" \
      "$port" "$account" "$password" "$is_selfSigned_ca" \
      "$certificate_endpoint" "$log"; then

      echo "Proxy has been updated"
    else

      echo "ERROR: Could not update proxy"
    fi
  else

    echo "ERROR: $proxy_update_execute does not exist" >>"$log"
    exit 1
  fi
done
