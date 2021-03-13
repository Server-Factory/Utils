#!/bin/sh

proxy_host="$1"
proxy_port="$2"
proxy_account="$3"
proxy_password="$4"
docker_restart="$5"

system_default_dir="/etc/system/default"
docker_env_file="$system_default_dir/docker.proxy.env"
docker_service_dir="/etc/systemd/system/docker.service.d"
docker_service_env_file="$docker_service_dir/environment.conf"

if [ -z "$proxy_host" ]; then

  echo "No Proxy configuration to set for the Docker"

  if test -e "$docker_env_file"; then

    if ! echo "" > "$docker_env_file"; then

      echo "ERROR: $docker_env_file could not be cleared"
      exit 1
    fi

    if [ -z "$docker_restart" ]; then

      echo "Docker will not be restarted (1)"
    else

      if systemctl daemon-reload && sudo systemctl restart docker; then

        echo "Docker has been restarted with success (1)"
      else

        echo "ERROR: Docker failed to restart (1)"
        exit 1
      fi
    fi
  fi

  exit 0
fi

proxy_prefix=""
if [ -z "$proxy_account" ]; then

  proxy_prefix="http://"
else

  proxy_prefix="http://$proxy_account:$proxy_password@"
fi

proxy="$proxy_prefix$proxy_host:$proxy_port"

if ! test -e "$system_default_dir"; then

  if mkdir -p "$system_default_dir"; then

    echo "$system_default_dir: has been created"
  else

    echo "ERROR: $system_default_dir has not been created"
    exit 1
  fi
fi

if echo "http_proxy=\"$proxy\"" > "$docker_env_file"; then

  echo "$docker_env_file: has been created" && cat "$docker_env_file"
else

  echo "ERROR: $docker_env_file has not been created"
  exit 1
fi

if test -e "$docker_service_dir"; then

  echo "$docker_service_dir: already exists"
else

  if mkdir -p "$docker_service_dir"; then

    echo "$docker_service_dir: has been created"
  else

    echo "ERROR: $docker_service_dir has not been created"
    exit 1
  fi
fi

if echo """
[Service]
EnvironmentFile=$docker_env_file
""" > "$docker_service_env_file"; then

  echo "$docker_service_env_file: has been created"
else

  echo "ERROR: $docker_service_env_file has not been created"
  exit 1
fi

if [ -z "$docker_restart" ]; then

  echo "Docker will not be restarted (2)"
else

  if systemctl daemon-reload && sudo systemctl restart docker; then

    echo "Docker has been restarted with success (2)"
  else

    echo "ERROR: Docker failed to restart (2)"
    exit 1
  fi
fi