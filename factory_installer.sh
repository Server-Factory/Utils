#!/bin/sh

factoryType=$1
if test -e build.gradle && test -e Factory; then

  if which gradle; then
    if test -e gradlew; then

      echo "Gradle wrapper is available"
    else

      gradle wrapper --gradle-version 6.7
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

        case $SHELL in
        */zsh)

          echo "ZSH detected"
          profile_file="$(dirname ~)/$(basename ~)/.zshrc"
          ;;
        */bash)

          echo "BASH detected"
          profile_file="$(dirname ~)/$(basename ~)/.bashrc"
          ;;
        *)

          echo "WARNING: no ZSH or BASH detected"
          ;;
        esac

        if test -e "$profile_file"; then

          echo "$profile_file is present"
        else

          if touch "$profile_file"; then

            echo "$profile_file is created"
          else

            echo "ERROR: $profile_file was not created"
            exit 1
          fi
        fi

        export_path="export PATH=$factoryPath:\$PATH"

        profile_file_content=$(cat "$profile_file")
        if echo "$profile_file_content" | grep "$export_path"; then

          echo "Export path definition already exported: '$export_path'"
        else

          echo "Adding export path definition: '$export_path'"
          if echo "" >> "$profile_file" && echo "$export_path" >> "$profile_file"; then

            echo "Export path definition added into $profile_file"
          else

            echo "ERROR: export path definition was not added into $profile_file"
            exit 1
          fi
        fi

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
