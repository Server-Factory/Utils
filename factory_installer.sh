#!/bin/sh

factoryType=$1
if test -e build.gradle && test -e Factory; then

  if which gradle; then
    if test -e gradlew; then

      echo "Gradle wrapper is available"
    else

      gradle wrapper
    fi

    ./gradlew clean && ./gradlew install
  fi
fi

if test Application/Release/Application.jar; then

  factoryPath="$2"
  if cp -f Application/Release/Application.jar "$factoryPath/factory_$factoryType.jar" &&
    cp -f Core/Utils/factory.sh "$factoryPath/factory_$factoryType.sh"; then

    definitions="$factoryPath/Definitions"
    detailsJson="$definitions/Details.json"
    if test -e "$detailsJson"; then
      # shellcheck disable=SC2002
      if cat "$detailsJson" | grep "repository_version" >/dev/null 2>&1; then

        echo "Existing software definitions found, cleaning up"
        if rm -rf "$definitions"; then

          echo "Clean up completed"
        else

          echo "Clean up failed"
          exit 1
        fi
      fi
    fi

    coreRoot="$factoryPath/Core"
    coreUtils="$coreRoot/Utils"
    coreUtilsReadme="$coreUtils/README.md"
    if test -e "$coreUtilsReadme"; then
      # shellcheck disable=SC2002
      if cat "$coreUtilsReadme" | grep "Server Factory Utils" >/dev/null 2>&1; then

        echo "Existing core utils found, cleaning up"
        if rm -rf "$coreUtils"; then

          echo "Clean up completed"
        else

          echo "Clean up failed"
          exit 1
        fi
      fi
    fi

    mkdir -p "$coreRoot"
    if cp -R Core/Utils "$coreRoot" && chmod -R 750 "$coreRoot" &&
      chmod -R 750 "$coreRoot"; then

      echo "Core utils have been installed with success"
      if cp -R Definitions "$definitions" &&
        chmod -R 750 "$definitions"; then

        echo "Software has been installed with success"
      else

        echo "Software installation failed, could not copy software definitions"
      fi
    else

      echo "Core utils installation failed, could not copy files"
    fi
  else

    echo "Software installation failed"
    exit 1
  fi
else

  echo "No Application.jar found"
  exit 1
fi
