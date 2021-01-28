#!/bin/sh

if echo "$1" | awk '/^([0-9]{1,3}[.]){3}([0-9]{1,3})$/{print $1}' >/dev/null 2>&1; then

  echo "OK"
  exit 0
fi

echo "NOT OK"
exit 1