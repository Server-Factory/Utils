#!/bin/sh

if which git; then

  if test -e Factory; then

    echo "Factory directory is already available. Please remove it and try again."
    exit 1
  else

    mkdir Factory && cd Factory && \
    git clone git@github.com:Server-Factory/Mail-Server-Factory.git . && \
    git submodule init && git submodule update && \
    ./installer.sh
  fi
else

  echo "No Git installation available"
  exit 1
fi