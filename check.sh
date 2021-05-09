#!/bin/sh

ELAPSED=0
TIMEOUT=$2
CONTAINER=$1

until [ $ELAPSED -eq "${TIMEOUT}" ] || docker ps -a --filter "status=running" --filter "name=${CONTAINER}" | grep "${CONTAINER}"; do

  echo "Waiting for container to start: ${CONTAINER}, retry: $((ELAPSED = ELAPSED + 1))" && sleep 1
done

if test "$ELAPSED" -eq "${TIMEOUT}"
then

  echo "Container is not running: ${CONTAINER}"
  exit 1
else

  echo "${CONTAINER}: has started"

  echo "${CONTAINER}: checking"
  sleep 30

  if docker ps -a --filter "status=running" --filter "name=${CONTAINER}" | grep "${CONTAINER}"; then

    echo "${CONTAINER}: is running"
    exit 0
  else

    echo "ERROR: ${CONTAINER} is not running"
    exit 1
  fi
fi
