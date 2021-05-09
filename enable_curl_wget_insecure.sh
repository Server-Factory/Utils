#!/bin/sh

enable_insecure() {

  # shellcheck disable=SC2039
  local wget_rc="/etc/wgetrc"
  # shellcheck disable=SC2039
  local curl_rc="/root/.curlrc"
  # shellcheck disable=SC2039
  local curl_rc_disable_ca_check="insecure"
  # shellcheck disable=SC2039
  local wget_rc_disable_ca_check="check_certificate = off"

  # shellcheck disable=SC2039
  local src=""
  src=$(cat "$curl_rc")
  if ! echo "$src" | grep -i "$curl_rc_disable_ca_check" >/dev/null 2>&1; then

    echo "Enabling 'Insecure' certificate setting for Curl"
    if echo "$curl_rc_disable_ca_check" >>"$curl_rc"; then

      echo "Enabled 'Insecure' certificate setting for Curl"
    else

      echo "ERROR: could not enable 'Insecure' certificate setting for Curl"
      exit 1
    fi
  else

    echo "'Insecure' certificate setting for Curl is already set"
  fi

  src=$(cat "$wget_rc")
  if ! echo "$src" | grep -i "$wget_rc_disable_ca_check" >/dev/null 2>&1; then

    echo "Enabling 'Insecure' certificate setting for Wget"
    if echo "$wget_rc_disable_ca_check" >>"$wget_rc"; then

      echo "Enabled 'Insecure' certificate setting for Wget"
    else

      echo "ERROR: could not enable 'Insecure' certificate setting for Wget"
      exit 1
    fi
  else

    echo "'Insecure' certificate setting for Wget is already set"
  fi
}
