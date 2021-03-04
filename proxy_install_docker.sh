#!/bin/sh

here=$(dirname "$0")
working_directory="$1"

proxy_install_script_name="proxy_install.sh"
proxy_install_script="$here/$proxy_install_script_name"

if ! test -e "$proxy_install_script"; then

  echo "ERROR: $proxy_install_script does not exist"
  exit 1
fi

sh "$proxy_install_script" "$working_directory" && source /etc/profile