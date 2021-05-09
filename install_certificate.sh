#!/bin/sh

install_certificate() {

  # shellcheck disable=SC2039
  local host="$1"

  # shellcheck disable=SC2039
  local certificate_endpoint="$2"

  # shellcheck disable=SC2039
  local os=""
  # shellcheck disable=SC2039
  local ver=""

  if [ -f /etc/os-release ]; then

    # freedesktop.org and systemd
    . /etc/os-release
    os=$NAME
    ver=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then

    # linuxbase.org
    os=$(lsb_release -si)
    ver=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then

    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    os=$DISTRIB_ID
    ver=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then

    # Older Debian/Ubuntu/etc.
    os=Debian
    ver=$(cat /etc/debian_version)
  elif [ -f /etc/SuSe-release ]; then

    # Older SuSE/etc.
    echo "Unsupported operating system (1)"
    exit 1
  elif [ -f /etc/redhat-release ]; then

    # Older Red Hat, CentOS, etc.
    echo "Unsupported operating system (2)"
    exit 1
  else

    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    os=$(uname -s)
    ver=$(uname -r)
  fi

  echo "Certificate installation target operating system is: $os $ver"
  echo "Obtaining certificate from: $certificate_endpoint"

  # shellcheck disable=SC2039
  local certificate_home="/usr/local/share/ca-certificates"
  if echo "$os" | grep -i -E "Fedora|Centos|RedHat" >/dev/null 2>&1; then

    certificate_home="/etc/pki/ca-trust/source/anchors"
  fi

  # shellcheck disable=SC2039
  local certificate_file_name="$host.crt"

  # shellcheck disable=SC2039
  local certificate_file="$certificate_home/$certificate_file_name"
  if test -e "$certificate_file"; then

    if rm -f "$certificate_file"; then

      echo "Old $certificate_file has been removed"
    else

      echo "ERROR: $certificate_file could not be removed"
      exit 1
    fi
  fi

  echo "Downloading certificate: $certificate_endpoint"
  if wget --no-proxy -O "$certificate_file" "$certificate_endpoint"; then

    echo "Proxy certificate downloaded to: $certificate_file"
  else

    echo "ERROR: Could not download proxy certificate to: $certificate_file"
    exit 1
  fi

  if echo "$os" | grep -i -E "Fedora|Centos|RedHat" >/dev/null 2>&1; then

    if ! update-ca-trust extract >/dev/null 2>&1; then

      echo "Could not update CA trust (1)"
      exit 1
    fi
  else

    if ! update-ca-certificates >/dev/null 2>&1; then

      echo "Could not update CA trust (2)"
      exit 1
    fi
  fi
}
