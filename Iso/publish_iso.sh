#!/bin/sh

iso_sync_script="iso_sync.sh"
iso_location_settings="iso_location.settings"

if test -e "$iso_location_settings"; then

  source=$(cat "$iso_location_settings")
  if ! test -e "$source"; then

      echo "Synchronization path unavailable: $source"
  else

      if test -e "$iso_sync_script"; then

        if sh "$iso_sync_script" "$source/" "Images/Iso"; then

            echo "Sync. completed"
        else

            echo "Failed to synchronize iso(s)"
            exit 1
        fi
      else

        echo "ERROR: $iso_sync_script not available, please create sync. script and try again"
        exit 1
      fi
  fi
else

  echo "ERROR: $iso_location_settings not available, please create file and add absolute path to iso(s) to it"
  exit 1
fi