#!/bin/sh

host="$1"
port="$2"
account="$3"
password="$4"
isSelfSignedCA="$5"
scriptRoot="$6"
here=$(dirname "$0")

echo "Initializing Proxy"
echo "Parameters(1)(host=$host, port=$port, account=$account, password=$password)"
echo "Parameters(2)(isSelfSignedCA=$isSelfSignedCA, scriptRoot=$scriptRoot)"

# shellcheck disable=SC2154
if ! [ "$proxy_host_ip" = "" ]
then

  echo "Last known proxy IP: $proxy_host_ip"
fi

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
    if echo "$proxy_ip" | awk '/^([0-9]{1,3}[.]){3}([0-9]{1,3})$/{print $1}' >/dev/null 2>&1; then

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

if [ -n "$isSelfSignedCA" ]; then

  wget_rc="/etc/wgetrc"
  curl_rc="/root/.curlrc"
  curl_rc_disable_ca_check="insecure"
  wget_rc_disable_ca_check="check_certificate = off"

  source=$(cat "$curl_rc")
  if ! echo "$source" | grep -i "$curl_rc_disable_ca_check" >/dev/null 2>&1; then

    echo "Enabling 'Insecure' setting for Curl"
    if echo "$curl_rc_disable_ca_check" >>"$curl_rc"; then

      echo "Enabled 'Insecure' setting for Curl"
    else

      echo "ERROR: could not enable 'Insecure' setting for Curl"
      exit 1
    fi
  else

    echo "'Insecure' setting for Curl is already set"
  fi

  source=$(cat "$wget_rc")
  if ! echo "$source" | grep -i "$wget_rc_disable_ca_check" >/dev/null 2>&1; then

    echo "Enabling 'Insecure' setting for Wget"
    if echo "$wget_rc_disable_ca_check" >>"$wget_rc"; then

      echo "Enabled 'Insecure' setting for Wget"
    else

      echo "ERROR: could not enable 'Insecure' setting for Wget"
      exit 1
    fi
  else

    echo "'Insecure' setting for Wget is already set"
  fi
else

  echo "'Insecure' setting for Curl and Wget is not needed"
fi

cmdStartProxy="setup_proxy.sh"
startProxyScript="$scriptRoot"/"$cmdStartProxy"
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
# TODO:
# sleep 900; sh proxy_install.sh &

echo "WORK IN PROGRESS"
exit 1

# TODO: In each iteration obtain proxy certificate (if self-signed) and apply it as trusted
