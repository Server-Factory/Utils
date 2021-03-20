#!/bin/sh

stop_ip_tables="$1"

if systemctl is-active --quiet avahi-daemon; then

  echo "Avahi Daemon is running, stop ip tables: '$stop_ip_tables'"
  if systemctl is-active --quiet iptables; then

    if [ "$stop_ip_tables" = "true" ]; then

      if systemctl stop iptables && systemctl disable iptables; then

        echo "Iptables service is disabled for Avahi mDNS"
      fi
    else

      echo "Iptables service Avahi mDNS will not be stopped"
    fi
  else

    echo "Iptables service is stopped for Avahi mDNS"
  fi
fi
