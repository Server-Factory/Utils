#!/bin/sh

here=$(dirname "$0")
proxy_home="$1"

echo "Proxy update for Docker executed"
echo "Parameters: here=$here proxy_home=$proxy_home"

sh "$here/proxy_update.sh" "$proxy_home" >/dev/null 2>&1 &
