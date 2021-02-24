#!/bin/sh

working_directory="$1"
host="$2"
port="$3"
account="$4"
password="$5"
is_selfSigned_ca="$6"
certificate_endpoint="$7"
log="$8"

date_time=$(date)
host_name="$host"
here=$(dirname "$0")

msg1="Initializing Proxy, $date_time"
msg2="Proxy init. parameters (1): (host=$host, port=$port, account=$account, password=$password)"
msg3="Proxy init. parameters (2): (is_selfSigned_ca=$is_selfSigned_ca, working_directory=$working_directory)"
msg4="Proxy init. parameters (3): (certificate_endpoint=$certificate_endpoint, log=$log)"

# shellcheck disable=SC2129
echo "$msg1" >>"$log"
echo "$msg2" >>"$log"
echo "$msg3" >>"$log"
echo "$msg4" >>"$log"

validate_ip_script="$here/validate_ip_address.sh"
if ! test -e "$validate_ip_script"; then

  echo "ERROR: $validate_ip_script does not exist" >>"$log"
  exit 1
fi

# shellcheck disable=SC2154
if ! [ "$proxy_host_ip" = "" ]; then

  echo "Last known proxy IP: $proxy_host_ip" >>"$log"
fi

if sh "$validate_ip_script" "$host" >/dev/null 2>&1; then

  proxy_ip="$host"
  echo "Proxy host is IP address: $proxy_ip" >>"$log"
else

  get_ip_script="$here"/getip.sh
  if test -e "$get_ip_script"; then

    if sh "$get_ip_script" "$host" >/dev/null 2>&1; then

      proxy_ip=$(sh "$get_ip_script" "$host")
      if [ "$proxy_ip" = "" ]; then

        echo "ERROR: Proxy IP was not obtained successfully, ip value: '$proxy_host_ip'" >>"$log"
        if [ "$proxy_host_ip" = "" ]; then

          echo "ERROR: Could not obtain proxy IP address (1)" >>"$log"
          exit 1
        else

          proxy_ip="$proxy_host_ip"
          host="$proxy_ip"
          echo "Proxy IP (1B): $host" >>"$log"
        fi
      else

        echo "Proxy IP (1): $proxy_ip" >>"$log"
      fi

      if sh "$validate_ip_script" "$proxy_ip" >/dev/null 2>&1; then

        echo "Proxy IP (2): $proxy_ip" >>"$log"
        host="$proxy_ip"
      else

        if [ "$proxy_host_ip" = "" ]; then

          echo "ERROR: Could not obtain proxy IP address (2)" >>"$log"
          exit 1
        else

          host="$proxy_host_ip"
          echo "Proxy IP (2B): $host" >>"$log"
        fi
      fi
    else

      if [ "$proxy_host_ip" = "" ]; then

        echo "ERROR: Could not obtain proxy IP address (3)" >>"$log"
        exit 1
      else

        host="$proxy_host_ip"
        echo "Proxy IP (3B): $host" >>"$log"
      fi
    fi
  else

    echo "ERROR: $get_ip_script is unavailable" >>"$log"
    exit 1
  fi
fi

if ! [ "$certificate_endpoint" = "" ]; then

  install_certificate_script="$here/install_certificate.sh"
  if ! test -e "$install_certificate_script"; then

    echo "ERROR: $install_certificate_script does not exist" >>"$log"
    exit 1
  fi

  if ! [ "$host_name" = "$proxy_ip" ]; then

    if certificate_endpoint=$(echo "$certificate_endpoint" | sed "s/$host_name/$proxy_ip/1"); then

      echo "Proxy certificate endpoint has been updated to: $certificate_endpoint" >>"$log"
    else

      echo "ERROR: could not update proxy certificate endpoint: '$host_name' -> '$proxy_ip'" >>"$log"
      exit 1
    fi
  fi

  # shellcheck disable=SC2039,SC1090
  source "$install_certificate_script"
  install_certificate "$host" "$certificate_endpoint" >>"$log"
fi

# TODO: Move into separate script same as we did for: install_certificate.sh
if [ "$is_selfSigned_ca" = "true" ]; then

  echo "Proxy is using self-signed certificate" >>"$log"
  if [ "$certificate_endpoint" = "" ]; then

    wget_rc="/etc/wgetrc"
    curl_rc="/root/.curlrc"
    curl_rc_disable_ca_check="insecure"
    wget_rc_disable_ca_check="check_certificate = off"

    source=$(cat "$curl_rc")
    if ! echo "$source" | grep -i "$curl_rc_disable_ca_check" >/dev/null 2>&1; then

      echo "Enabling 'Insecure' certificate setting for Curl" >>"$log"
      if echo "$curl_rc_disable_ca_check" >>"$curl_rc"; then

        echo "Enabled 'Insecure' certificate setting for Curl" >>"$log"
      else

        echo "ERROR: could not enable 'Insecure' certificate setting for Curl" >>"$log"
        exit 1
      fi
    else

      echo "'Insecure' certificate setting for Curl is already set" >>"$log"
    fi

    source=$(cat "$wget_rc")
    if ! echo "$source" | grep -i "$wget_rc_disable_ca_check" >/dev/null 2>&1; then

      echo "Enabling 'Insecure' certificate setting for Wget" >>"$log"
      if echo "$wget_rc_disable_ca_check" >>"$wget_rc"; then

        echo "Enabled 'Insecure' certificate setting for Wget" >>"$log"
      else

        echo "ERROR: could not enable 'Insecure' certificate setting for Wget" >>"$log"
        exit 1
      fi
    else

      echo "'Insecure' certificate setting for Wget is already set" >>"$log"
    fi
  else

    echo "'Insecure' certificate settings are not needed (1)" >>"$log"
  fi
else

  echo "'Insecure' certificate settings are not needed (2)" >>"$log"
fi

cmdStartProxy="apply_proxy.sh"
startProxyScript="$working_directory"/"$cmdStartProxy"
if echo """
  #!/bin/sh

  host=\"$host\"
  port=\"$port\"
  account=\"$account\"
  password=\"$password\"

  echo \"Setting up proxy\"

  export proxy_host_ip=\"$proxy_ip\"
  export proxy_url=\"\$host:\$port/\"

  if ! [ \"\$account\" = \"\" ]; then

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

  echo "$startProxyScript has been created" >>"$log"
else

  echo "ERROR: $startProxyScript has not been created" >>"$log"
  exit 1
fi

etc_profile="/etc/profile"
profile=$(cat "$etc_profile")
if ! echo "$profile" | grep -i "$startProxyScript" >/dev/null 2>&1; then

  echo "Installing 'start proxy' script" >>"$log"
  if echo """

  source $startProxyScript
    """ >>"$etc_profile"; then

    echo "'start proxy' script has been installed" >>"$log"
  else

    echo "ERROR: 'start proxy' script has not been installed" >>"$log"
    exit 1
  fi
else

  echo "'start proxy' script is already installed" >>"$log"
fi
