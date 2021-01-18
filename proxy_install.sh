#!/bin/sh

host="$1"
port="$2"
account="$3"
password="$4"
isSelfSignedCA="$5"
scriptRoot="$6"

echo "Initializing Proxy"
echo "Parameters(1)(host=$host, port=$port, account=$account, password=$password)"
echo "Parameters(2)(isSelfSignedCA=$isSelfSignedCA, scriptRoot=$scriptRoot)"

if [ -n "$isSelfSignedCA" ]; then

  source=$(cat /root/.curlrc)
  if ! echo "$source" | grep -i "insecure" >/dev/null 2>&1; then

    echo "Enabling 'Insecure' setting for Curl"
    if echo insecure >>~/.curlrc; then

      echo "Enabled 'Insecure' setting for Curl"
    else

      echo "ERROR: could not enable 'Insecure' setting for Curl"
      exit 1
    fi
  else

    echo "'Insecure' setting for Curl is already set"
  fi
else

  echo "'Insecure' setting for Curl is not needed"
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

export proxy_url=\"\$host:\$port/\"
if ! [ \"\$account\" = \"_empty\" ]; then

  proxy_url=\"\$account:\$password@\$host:\$port/\"
fi

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

sh $startProxyScript
  """ >>"$etc_profile"; then

    echo "'start proxy' script has been installed"
  else

    echo "ERROR: 'start proxy' script has not been installed"
    exit 1
  fi
else

  echo "'start proxy' script is already installed"
fi

sh "$startProxyScript"

echo "WORK IN PROGRESS"
exit 1
