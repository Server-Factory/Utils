#!/bin/sh

host="$1"
host_name="$host"
port="$2"
account="$3"
password="$4"
is_selfSigned_ca="$5"
script_root="$6"
certificate_endpoint="$7"
delayed="$8"
here=$(dirname "$0")
empty="_empty"
log="proxy_install.log"
config_file_name="proxy.cfg"
proxy_service_file_name="proxy.service"
proxy_update_script_name="proxy_update.sh"
config_file="$script_root/$config_file_name"
proxy_service="$script_root/$proxy_service_file_name"
proxy_update_script="$here/$proxy_update_script_name"

# FIXME: Make sure that the script can be scheduled on system reboot
# 1. Create proxy configuration file (configuration file goes here: $script_root) [ done ]
# 2. Start proxy service (service file goes here: $script_root)
# 3. Proxy service will start the script

if sh "$validate_ip_script" "$host_name" >/dev/null 2>&1; then

  echo "$config_file configuration is not required"
else

  if echo """
host=$1
port=$2
account=$3
password=$4
is_selfSigned_ca=$5
script_root=$6
certificate_endpoint=$7
delayed=$8
""" | tee "$config_file" >/dev/null 2>&1 && chmod 640 "$config_file"; then

    echo "$config_file: configuration saved"
  else

    echo "ERROR: $config_file configuration was not saved"
    exit 1
  fi

  if ! test -e "$proxy_update_script"; then

    echo "ERROR: $proxy_update_script is not available"
    exit 1
  fi

  if echo """
[Unit]
Description=Proxy service

[Service]
ExecStart=$proxy_update_script

[Install]
WantedBy=multi-user.target
""" | tee "$proxy_service" >/dev/null 2>&1 && chmod 640 "$config_file"; then

    echo "$proxy_service: proxy service file saved"
    # TODO: enable and start service
  else

    echo "ERROR: $proxy_service proxy service file not saved"
    exit 1
  fi
fi

# TODO: Move delay if needed
delay=10 # TODO: Set to: 900
if [ "$delayed" = "delayed" ]; then

  delayMsg="Delay set to $delay seconds"
  sleep 10
else

  delayMsg="No delay set"
fi
echo "$delayMsg"

msg1="Initializing Proxy"
msg2="Proxy init. parameters (1): (host=$host, port=$port, account=$account, password=$password)"
msg3="Proxy init. parameters (2): (is_selfSigned_ca=$is_selfSigned_ca, script_root=$script_root)"
msg4="Proxy init. parameters (3): (certificate_endpoint=$certificate_endpoint, delayed=$delayed)"

echo "$msg1"
echo "$msg2"
echo "$msg3"
echo "$msg4"

date=$(date)
# shellcheck disable=SC2129
echo "$date" >>"$here/$log"
echo "$delayMsg" >>"$here/$log"
echo "$msg1" >>"$here/$log"
echo "$msg2" >>"$here/$log"
echo "$msg3" >>"$here/$log"
echo "$msg4" >>"$here/$log"
echo "- - - - - - - - - -" >>"$here/$log"

validate_ip_script="$here/validate_ip_address.sh"
if ! test -e "$validate_ip_script"; then

  echo "ERROR: $validate_ip_script does not exist"
  exit 1
fi

# shellcheck disable=SC2154
if ! [ "$proxy_host_ip" = "" ]; then

  echo "Last known proxy IP: $proxy_host_ip"
fi

if sh "$validate_ip_script" "$host" >/dev/null 2>&1; then

  proxy_ip="$host"
  echo "Proxy host is IP address: $proxy_ip"
else

  get_ip_script="$here"/getip.sh
  if test -e "$get_ip_script"; then

    if sh "$get_ip_script" "$host" >/dev/null 2>&1; then

      proxy_ip=$(sh "$get_ip_script" "$host")
      if [ "$proxy_ip" = "" ]; then

        echo "ERROR: proxy IP was not obtained successfully"
        if [ "$proxy_host_ip" = "" ]; then

          echo "ERROR: Could not obtain proxy IP address (1)"
          exit 1
        else

          proxy_ip="$proxy_host_ip"
          host="$proxy_ip"
          echo "Proxy IP (1B): $host"
        fi
      else

        echo "Proxy IP (1): $proxy_ip"
      fi

      if sh "$validate_ip_script" "$proxy_ip" >/dev/null 2>&1; then

        echo "Proxy IP (2): $proxy_ip"
        host="$proxy_ip"
      else

        if [ "$proxy_host_ip" = "" ]; then

          echo "ERROR: Could not obtain proxy IP address (2)"
          exit 1
        else

          host="$proxy_host_ip"
          echo "Proxy IP (2B): $host"
        fi
      fi
    else

      if [ "$proxy_host_ip" = "" ]; then

        echo "ERROR: Could not obtain proxy IP address (3)"
        exit 1
      else

        host="$proxy_host_ip"
        echo "Proxy IP (3B): $host"
      fi
    fi
  else

    echo "ERROR: $get_ip_script is unavailable"
    exit 1
  fi
fi

if ! [ "$certificate_endpoint" = "$empty" ]; then

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

  echo "Proxy certificate installation target operating system is: $os $ver"
  echo "Obtaining proxy certificate from: $certificate_endpoint"

  certificate_home="/usr/local/share/ca-certificates"
  if echo "$os" | grep -i -E "Fedora|Centos|RedHat" >/dev/null 2>&1; then

    certificate_home="/etc/pki/ca-trust/source/anchors"
  fi

  certificate_file_name="$host.crt"
  certificate_file="$certificate_home/$certificate_file_name"
  if test -e "$certificate_file"; then

    if rm -f "$certificate_file"; then

      echo "Old $certificate_file has been removed"
    else

      echo "ERROR: $certificate_file could not be removed"
      exit 1
    fi
  fi

  if ! [ "$host_name" = "$proxy_ip" ]; then

    if certificate_endpoint=$(echo "$certificate_endpoint" | sed "s/$host_name/$proxy_ip/1"); then

      echo "Proxy certificate endpoint has been updated to: $certificate_endpoint"
    else

      echo "ERROR: could not update proxy certificate endpoint: '$host_name' -> '$proxy_ip'"
      exit 1
    fi
  fi

  if wget --no-proxy -O "$certificate_file" "$certificate_endpoint" >/dev/null 2>&1; then

    echo "Proxy certificate saved to: $certificate_file"
  else

    echo "ERROR: Could not save proxy certificate to: $certificate_file"
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
fi

if [ "$is_selfSigned_ca" = "true" ]; then

  echo "Proxy is using self-signed certificate"
  if [ "$certificate_endpoint" = "$empty" ]; then

    wget_rc="/etc/wgetrc"
    curl_rc="/root/.curlrc"
    curl_rc_disable_ca_check="insecure"
    wget_rc_disable_ca_check="check_certificate = off"

    source=$(cat "$curl_rc")
    if ! echo "$source" | grep -i "$curl_rc_disable_ca_check" >/dev/null 2>&1; then

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

    source=$(cat "$wget_rc")
    if ! echo "$source" | grep -i "$wget_rc_disable_ca_check" >/dev/null 2>&1; then

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
  else

    echo "'Insecure' certificate settings are not needed (1)"
  fi
else

  echo "'Insecure' certificate settings are not needed (2)"
fi

cmdStartProxy="apply_proxy.sh"
startProxyScript="$script_root"/"$cmdStartProxy"
if echo """
#!/bin/sh

host=\"$host\"
port=\"$port\"
account=\"$account\"
password=\"$password\"

echo \"Setting up proxy\"

export proxy_host_ip=\"$proxy_ip\"
export proxy_url=\"\$host:\$port/\"

if ! [ \"\$account\" = \"_empty\" ]; then

  proxy_url=\"\$account:\$password@\$host:\$port/\"
fi

echo \"Proxy IP is set to: \$proxy_host_ip\"
echo \"Proxy URL is set to: \$proxy_url\"

export http_proxy=\"\$proxy_url\"
export https_proxy=\"\$proxy_url\"
export ftp_proxy=\"\$proxy_url\"
export no_proxy=\"127.0.0.1,localhost\"

export HTTP_PROXY=\"\$proxy_url\"
export HTTPS_PROXY=\"\$proxy_url\"
export FTP_PROXY=\"\$proxy_url\"
export NO_PROXY=\"127.0.0.1,localhost\"
""" >"$startProxyScript" && chmod 740 "$startProxyScript"; then

  echo "$startProxyScript has been created"
else

  echo "ERROR: $startProxyScript has not been created"
  exit 1
fi

etc_profile="/etc/profile"
profile=$(cat "$etc_profile")
if ! echo "$profile" | grep -i "$startProxyScript" >/dev/null 2>&1; then

  echo "Installing 'start proxy' script"
  if echo """

source $startProxyScript
  """ >>"$etc_profile"; then

    echo "'start proxy' script has been installed"
  else

    echo "ERROR: 'start proxy' script has not been installed"
    exit 1
  fi
else

  echo "'start proxy' script is already installed"
fi

# shellcheck disable=SC2039,SC1090
source "$startProxyScript"
if sh "$validate_ip_script" "$host_name" >/dev/null 2>&1; then

  echo "Delayed repeated proxy install execution will not be scheduled"
else

  echo "WARNING: Scheduling delayed repeated proxy install execution."
  echo "Proxy installation will be performed on each $delay seconds"
  echo "so proxy IP address and certificate are up to date."
  nohup sh "$0" "$1" "$2" "$3" "$4" "$5" "$6" "$7" delayed >/dev/null 2>&1 &
fi

# TODO: Remove:
echo "WORK IN PROGRESS"
exit 1
