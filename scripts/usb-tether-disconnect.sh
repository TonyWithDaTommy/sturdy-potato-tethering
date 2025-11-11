#!/usr/bin/env bash
#
# usb-tether-disconnect.sh - USB Tethering Disconnection
# Disconnects all active USB tethering interfaces
#
# Author: derp
# License: MIT

set -euo pipefail

readonly LOGFILE="/var/log/usb-tethering.log"

log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $*" | tee -a "$LOGFILE"
}

disconnect_interface() {
    local iface="$1"

    echo "Disconnecting: $iface"

    sudo pkill -f "dhcpcd.*$iface" 2>/dev/null || true
    sudo ip link set "$iface" down 2>/dev/null || true

    echo "  ✓ Disconnected"
    log "Disconnected interface: $iface"
}

main() {
    echo "USB Tethering Disconnect"
    echo "========================"
    echo ""

    local iface found=0

    for iface in /sys/class/net/*; do
        iface=$(basename "$iface")

        case "$iface" in
            usb*|rndis*|enp0s*u*)
                disconnect_interface "$iface"
                found=1
                ;;
        esac
    done

    if [ "$found" -eq 0 ]; then
        echo "No USB tethering interfaces found"
    else
        echo ""
        echo "All USB tethering interfaces disconnected"
    fi
}

main "$@"
