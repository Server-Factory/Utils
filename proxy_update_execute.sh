#!/bin/sh

working_directory="$1"
host="$2"
port="$3"
account="$4"
password="$5"
certificate_endpoint="$6"
log="$7"
behavior_get_ip="$8"

date_time=$(date)
host_name="$host"
here=$(dirname "$0")

text_file="proxyAddress.txt"
proxy_address_txt="$working_directory/$text_file"
proxy_address_parent_txt="$working_directory/Parent/$text_file"

msg1="Initializing Proxy, $date_time"
msg2="Proxy init. parameters (1): (host=$host, port=$port, account=$account, password=$password)"
msg3="Proxy init. parameters (2): (working_directory=$working_directory, log=$log)"
msg4="Proxy init. parameters (3): (certificate_endpoint=$certificate_endpoint)"
msg5="Proxy init. parameters (4): (behavior_get_ip=$behavior_get_ip)"

# shellcheck disable=SC2129
echo "$msg1" >>"$log"
echo "$msg2" >>"$log"
echo "$msg3" >>"$log"
echo "$msg4" >>"$log"
echo "$msg5" >>"$log"

# shellcheck disable=SC2154
if [ -z "$host" ]; then

  if [ -z "$PROXY_HOST_FALLBACK" ]; then

    echo "No Proxy configuration provided"
    exit 0
  fi
fi

validate_ip_script="$here/validate_ip_address.sh"
if ! test -e "$validate_ip_script"; then

  echo "ERROR: $validate_ip_script does not exist" >>"$log"
  exit 1
fi

# shellcheck disable=SC2154
if [ -z "$PROXY_HOST_FALLBACK" ]; then

  echo "No information about last known proxy address" >>"$log"
else

  echo "Last known proxy address: $PROXY_HOST_FALLBACK" >>"$log"
fi

if sh "$validate_ip_script" "$host" >/dev/null 2>&1; then

  proxy_address="$host"
  echo "Proxy host is address: $proxy_address" >>"$log"
else

  if [ -z "$behavior_get_ip" ]; then

    echo "We will not obtain proxy address from host address"
  else

    if [ "$behavior_get_ip" = "true" ]; then

      get_address_script="$here"/getip.sh
      if test -e "$get_address_script"; then

        proxy_address=""
        if [ -z "$FACTORY_SERVICE" ]; then

          proxy_address=$(sh "$get_address_script" "$host")
        else

          if test -e "$proxy_address_parent_txt"; then

            echo "$proxy_address_parent_txt: is available" >>"$log"
            proxy_address=$(cat "$proxy_address_parent_txt")
          else

            echo "WARNING: $proxy_address_parent_txt does not exist" >>"$log"
          fi
        fi

        if [ "$proxy_address" = "" ]; then

          echo "ERROR: Proxy address was not obtained successfully, value: '$PROXY_HOST_FALLBACK'" >>"$log"
          if [ -z "$PROXY_HOST_FALLBACK" ]; then

            echo "ERROR: Could not obtain proxy address (1)" >>"$log"
            exit 1
          else

            proxy_address="$PROXY_HOST_FALLBACK"
            host="$proxy_address"
            echo "Proxy (1B): $host" >>"$log"
          fi
        else

          echo "Proxy (1): $proxy_address" >>"$log"
        fi

        if sh "$validate_ip_script" "$proxy_address" >/dev/null 2>&1; then

          echo "Proxy (2): $proxy_address" >>"$log"
          host="$proxy_address"
        else

          if [ -z "$PROXY_HOST_FALLBACK" ]; then

            echo "ERROR: Could not obtain proxy address (2)" >>"$log"
            exit 1
          else

            host="$PROXY_HOST_FALLBACK"
            echo "Proxy (2B): $host" >>"$log"
          fi
        fi
      else

        echo "ERROR: $get_address_script is unavailable" >>"$log"
        exit 1
      fi
    fi
  fi
fi

if ! [ "$certificate_endpoint" = "" ]; then

  install_certificate_script="$here/install_certificate.sh"
  if ! test -e "$install_certificate_script"; then

    echo "ERROR: $install_certificate_script does not exist" >>"$log"
    exit 1
  fi

  if ! [ "$host_name" = "$proxy_address" ] && ! [ "$proxy_address" = "" ]; then

    if certificate_endpoint=$(echo "$certificate_endpoint" | sed "s/$host_name/$proxy_address/1"); then

      echo "Proxy certificate endpoint has been updated to: $certificate_endpoint" >>"$log"
    else

      echo "ERROR: could not update proxy certificate endpoint: '$host_name' -> '$proxy_address'" >>"$log"
      exit 1
    fi
  fi

  # shellcheck disable=SC1090
  . "$install_certificate_script"
  install_certificate "$host" "$certificate_endpoint" >>"$log"
fi

if [ -z "$certificate_endpoint" ]; then

  enable_insecure_script="$here/enable_curl_wget_insecure.sh"
  if ! test -e "$enable_insecure_script"; then

    echo "ERROR: $enable_insecure_script does not exist" >>"$log"
    exit 1
  fi

  # shellcheck disable=SC1090
  . "$enable_insecure_script"
  enable_insecure >>"$log"
else

  echo "'Insecure' certificate settings are not needed (1)" >>"$log"
fi

cmdStartProxy="apply_proxy.sh"
startProxyScript="$working_directory"/"$cmdStartProxy"

if [ -z "$behavior_get_ip" ]; then

  echo "$proxy_address_txt: will not be written"

  if test -e "$proxy_address_txt"; then

    if ! rm -f "$proxy_address_txt"; then

      echo "ERROR: $proxy_address_txt could not be removed"
      exit 1
    fi
  fi
else

  if [ "$behavior_get_ip" = "true" ]; then

    if echo "$proxy_address" >"$proxy_address_txt"; then

      echo "$proxy_address_txt: has been created" >>"$log"
    else

      echo "ERROR: $proxy_address_txt has not been created" >>"$log"
      exit 1
    fi
  fi
fi

if echo """
  #!/bin/sh

  host=\"$host\"
  port=\"$port\"
  account=\"$account\"
  password=\"$password\"

  echo \"Setting up proxy\"

  export PROXY_HOST_FALLBACK=\"$proxy_address\"
  export proxy_url=\"http://\$host:\$port/\"

  if ! [ \"\$account\" = \"\" ]; then

    export proxy_url=\"http://\$account:\$password@\$host:\$port/\"
  fi

  echo \"Proxy address is set to: \$PROXY_HOST_FALLBACK\"
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

  . $startProxyScript
    """ >>"$etc_profile"; then

    echo "'start proxy' script has been installed" >>"$log"
  else

    echo "ERROR: 'start proxy' script has not been installed" >>"$log"
    exit 1
  fi
else

  echo "'start proxy' script is already installed" >>"$log"
fi

if [ -z "$FACTORY_SERVICE" ]; then

  docker_configuration_proxy_init_script_name="docker_configuration_proxy_init.sh"
  docker_configuration_proxy_init_script="$here/$docker_configuration_proxy_init_script_name"

  if test -e "$docker_configuration_proxy_init_script"; then

    if sh "$docker_configuration_proxy_init_script" "$host" "$port" "$account" "$password"; then

      echo "Docker service Proxy configuration has been refreshed" >>"$log"
    else

      echo "ERROR: Could not refresh Docker service Proxy configuration" >>"$log"
      exit 1
    fi
  else

    echo "ERROR: $docker_configuration_proxy_init_script does not exist" >>"$log"
    exit 1
  fi
fi
