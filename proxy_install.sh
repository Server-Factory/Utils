#!/bin/sh

script_root="$6"
here=$(dirname "$0")
config_file_name="proxy.cfg"
set_enforce_script_name="setenforce.sh"
proxy_service_file_name="proxy.service"
config_file="$script_root/$config_file_name"
set_enforce_script="$here/$set_enforce_script_name"
proxy_service="$script_root/$proxy_service_file_name"

if test -e "$config_file"; then

  if ! rm -f "$config_file"; then

    echo "ERROR: $config_file could not be removed"
    exit 1
  fi
fi

if cp "$here"/Proxy/"$config_file_name" "$config_file" &&
  test -e "$config_file" && chmod 640 "$config_file"; then

  echo "$config_file: proxy configuration file saved"
else

  echo "ERROR: $config_file proxy configuration file not saved"
  exit 1
fi

if test -e "$proxy_service"; then

  if ! rm -f "$proxy_service"; then

    echo "ERROR: $proxy_service could not be removed"
    exit 1
  fi
fi

if cp "$here"/Proxy/"$proxy_service_file_name" "$proxy_service" &&
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

  if "$set_enforce_script" && systemctl enable "$proxy_service_file_name" && systemctl start "$proxy_service_file_name"; then
    echo "Proxy service started"

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
