#!/bin/sh

here=$(dirname "$0")
working_directory="$1"

config_file_name="proxy.cfg"
set_enforce_script_name="setenforce.sh"
proxy_service_file_name="proxy.service"
proxy_update_script_name="proxy_update_execute.sh"
load_configuration_script_name="proxy_load_configuration.sh"

proxy_update="$here/$proxy_update_script_name"
config_file="$working_directory/$config_file_name"
set_enforce_script="$here/$set_enforce_script_name"
proxy_service="$working_directory/$proxy_service_file_name"
load_configuration_script="$here/$load_configuration_script_name"

if test -e "$config_file"; then

  if ! rm -f "$config_file"; then

    echo "ERROR: $config_file could not be removed"
    exit 1
  fi
fi

if mv "$here"/Proxy/"$config_file_name" "$config_file" &&
  test -e "$config_file" && chmod 640 "$config_file"; then

  echo "$config_file: proxy configuration file saved"
else

  echo "ERROR: $config_file proxy configuration file not saved"
  exit 1
fi

if ! test -e "$proxy_update"; then

  echo "ERROR: $proxy_update does not exist"
  exit 1
fi

if ! test -e "$load_configuration_script"; then

  echo "ERROR: $load_configuration_script does not exist"
  exit 1
fi

# shellcheck disable=SC1090,SC2039
source "$load_configuration_script" "$config_file"

echo "Initializing Proxy for the first time"
# shellcheck disable=SC2154,SC2129
if ! sh "$proxy_update" "$working_directory" "$host" "$port" "$account" "$password" \
  "$is_selfSigned_ca" "$certificate_endpoint"; then

  echo "ERROR: Could not initialize proxy for the first time"
  if test "$here"/Proxy/"$proxy_service_file_name"; then

    rm -f "$here"/Proxy/"$proxy_service_file_name"
  fi
  exit 1
fi

if test -e "$proxy_service"; then

  if ! rm -f "$proxy_service"; then

    echo "ERROR: $proxy_service could not be removed"
    exit 1
  fi
fi

if mv "$here"/Proxy/"$proxy_service_file_name" "$proxy_service" &&
  test -e "$proxy_service" && chmod 640 "$proxy_service"; then

  echo "$proxy_service: proxy service file saved"
  if ! test -e "$set_enforce_script"; then

    echo "ERROR: $set_enforce_script does not exits"
    exit 1
  fi

  systemd_service="/etc/systemd/system/$proxy_service_file_name"
  if test -e systemd_service; then

    echo "$systemd_service already exists, cleaning up"
    if rm -f "$systemd_service"; then

      echo "$systemd_service removed"
    else

      echo "ERROR: $systemd_service could not be removed"
      exit 1
    fi
  fi

  if cp "$proxy_service" "$systemd_service"; then

    echo "$systemd_service is ready"
  else

    echo "ERROR: $proxy_service could not be created"
    exit 1
  fi

  if "$set_enforce_script" &&
    systemctl enable "$proxy_service_file_name" &&
    systemctl start "$proxy_service_file_name"; then

    if systemctl status "$proxy_service_file_name" | grep running >/dev/null 2>&1; then

      echo "Proxy service started"
    else

      echo "ERROR: Proxy service is not running"
      exit 1
    fi

    selinux_config_path="/etc/selinux"
    selinux_config="$selinux_config_path/config"
    selinux_config_backup="$selinux_config_path/config.bak"

    if sestatus | grep -i "disabled" >/dev/null 2>&1; then

      echo "SELinux is already disabled"
    else

      if test -e "$selinux_config"; then

        if ! test -e "$selinux_config_backup"; then

          echo "$selinux_config: backing up"
          if ! mv "$selinux_config" "$selinux_config_backup"; then

            echo "ERROR: $selinux_config could not backup"
            exit 1
          fi
        fi

        if echo "SELINUX=disabled" >"$selinux_config" &&
          echo "SELINUXTYPE=targeted" | tee -a "$selinux_config" >/dev/null 2>&1; then

          echo "SELinux is disabled"
        else

          echo "ERROR: Could not disable SELinux"
        fi
      else

        echo "WARNING: $selinux_config not found"
      fi
    fi
  else

    echo "ERROR: Could not start proxy service"
    exit 1
  fi
else

  echo "ERROR: $proxy_service proxy service file not saved"
  exit 1
fi

# TODO: Remove:
echo "WORK IN PROGRESS"
exit 1
