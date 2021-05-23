#!/bin/sh

if which git; then

  target="$1"
  repository="$2"

  echo "'$repository' installing into: $target"
  if test -e "$target"; then

    if ! rm -rf "$target"; then

      echo "ERROR: $target exists and cannot be deleted"
    fi
  fi

  if mkdir -p "$target"; then

    echo "$target: directory created"
  else

    echo "ERROR: $target directory was not created"
  fi

  if ! git clone --recurse-submodules "$repository" "$target"; then

    exit 1
  fi
else

  echo "ERROR: Git is not installed in the system"
  exit 1
fi