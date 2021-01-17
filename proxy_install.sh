#!/bin/sh

host="$1"
port="$2"
account="$3"
password="$4"
isSelfSignedCA="$5"
utilsRoot="$6"

echo "Initializing Proxy"
echo "Parameters(1)(host=$host, port=$port, account=$account, password=$password)"
echo "Parameters(2)(isSelfSignedCA=$isSelfSignedCA, utilsRoot=$utilsRoot)"

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

cmdStartProxy="start_proxy.sh"
startProxyScript="$utilsRoot"/"$cmdStartProxy"
echo """
#!/bin/sh

echo \"Setting up proxy\"

if [ \"$account\" = \"_empty\" ]; then

  PROXY_URL=\"$host:$port/\"
else

  PROXY_URL=\"$account:$password@$host:$port/\"
fi

echo \"Proxy URl is set to: $PROXY_URL\"

export http_proxy=\"$PROXY_URL\"
export https_proxy=\"$PROXY_URL\"
export ftp_proxy=\"$PROXY_URL\"
export no_proxy=\"127.0.0.1,localhost\"

export HTTP_PROXY=\"$PROXY_URL\"
export HTTPS_PROXY=\"$PROXY_URL\"
export FTP_PROXY=\"$PROXY_URL\"
export NO_PROXY=\"127.0.0.1,localhost\"
""" >"$startProxyScript"
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
