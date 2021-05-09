#!/bin/sh

stop_ip_tables="$1"

if systemctl is-active --quiet avahi-daemon; then

  echo "Avahi Daemon is running, stop_ip_tables: '$stop_ip_tables'"
  if systemctl is-active --quiet iptables; then

    if [ "$stop_ip_tables" = "true" ]; then

      if systemctl stop iptables && systemctl disable iptables >/dev/null 2>&1; then

        echo "Iptables service is disabled for Avahi mDNS"
        systemctl restart avahi-daemon.service >/dev/null 2>&1
      fi
    else

      echo "Iptables service Avahi mDNS will not be stopped"
    fi
  else

    echo "Iptables service is not running for Avahi mDNS"
  fi

  if systemctl is-active --quiet firewalld; then

    if [ "$stop_ip_tables" = "true" ]; then

      if firewall-cmd --add-service=mdns >/dev/null 2>&1 && \
        firewall-cmd --permanent --add-service=mdns >/dev/null 2>&1; then

        echo "Firewalld service is ready for Avahi mDNS"
        systemctl restart avahi-daemon.service >/dev/null 2>&1;
      fi
    else

      echo "Firewalld service will not be modified for Avahi mDNS"
    fi
  else

    echo "Firewalld service is not running for Avahi mDNS"
  fi
fi
