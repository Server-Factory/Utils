#!/bin/sh

if systemctl is-active --quiet avahi-daemon; then

  echo "Avahi Daemon is running"
  if systemctl is-active --quiet iptables; then

    if systemctl stop iptables && systemctl disable iptables; then

      echo "Iptables service is disabled for Avahi mDNS"
    fi
  else

    echo "Iptables service is already disabled for Avahi mDNS"
  fi
fi
