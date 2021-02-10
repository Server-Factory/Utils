#!/bin/sh

working_directory="$1"
log="$working_directory"/proxy_update.log
date > "$log"

echo "" >> "$log"
config=$(cat "$working_directory"/proxy.cfg)
echo "Configuration:" >> "$log"
echo "$config" >> "$log"


# TODO: Load configuration from .cfg file

