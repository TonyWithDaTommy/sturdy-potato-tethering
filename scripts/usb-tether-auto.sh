#!/usr/bin/env bash
#
# usb-tether-auto.sh - Automatic USB Tethering Connection
# Triggered by udev when Android device is connected
#
# Author: derp
# License: MIT

set -euo pipefail

readonly LOGFILE="/var/log/usb-tethering.log"
readonly NOTIFICATION_USER="${SUDO_USER:-derp}"

log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $*" | sudo tee -a "$LOGFILE" >/dev/null
}

notify_user() {
    local title="$1"
    local message="$2"

    if [ -n "${DISPLAY:-}" ]; then
        sudo -u "$NOTIFICATION_USER" \
            DISPLAY=:0 \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
            notify-send -u normal "$title" "$message" 2>/dev/null || true
    fi
}

detect_usb_interface() {
    local iface

    for iface in /sys/class/net/*; do
        iface=$(basename "$iface")

        case "$iface" in
            usb*|rndis*|enp0s*u*)
                if [ -d "/sys/class/net/$iface" ]; then
                    echo "$iface"
                    return 0
                fi
                ;;
        esac
    done

    return 1
}

configure_interface() {
    local iface="$1"

    sudo ip link set "$iface" up
    sleep 2

    sudo pkill -f "dhcpcd.*$iface" 2>/dev/null || true
    sleep 1

    if sudo dhcpcd "$iface" >/dev/null 2>&1; then
        sleep 3
        return 0
    fi

    return 1
}

main() {
    sleep 2

    log "Auto-connect triggered"

    local iface
    if ! iface=$(detect_usb_interface); then
        log "No USB tethering interface detected"
        exit 0
    fi

    log "Detected interface: $iface"

    if ! configure_interface "$iface"; then
        log "DHCP configuration failed on $iface"
        exit 1
    fi

    local ip_addr
    ip_addr=$(ip addr show "$iface" | grep "inet " | awk '{print $2}')

    if [ -n "$ip_addr" ]; then
        log "Connected: $iface - $ip_addr"
        notify_user "USB Tethering Connected" "Interface: $iface\nIP: $ip_addr"
    else
        log "Failed to obtain IP on $iface"
    fi
}

main "$@"
