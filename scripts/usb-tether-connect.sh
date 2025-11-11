#!/usr/bin/env bash
#
# usb-tether-connect.sh - Manual USB Tethering Connection
# Detects and connects to Android USB tethering interface
#
# Author: derp
# License: MIT

set -euo pipefail

readonly LOGFILE="/var/log/usb-tethering.log"
readonly TIMEOUT=3

log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $*" | tee -a "$LOGFILE"
}

detect_usb_interface() {
    local iface

    for iface in /sys/class/net/*; do
        iface=$(basename "$iface")

        case "$iface" in
            usb*|rndis*|enp0s*u*)
                if [ -f "/sys/class/net/$iface/carrier" ]; then
                    if [ "$(cat "/sys/class/net/$iface/carrier" 2>/dev/null || echo 0)" = "1" ]; then
                        echo "$iface"
                        return 0
                    fi
                fi

                if ip link show "$iface" 2>/dev/null | grep -qE "state UP|state UNKNOWN"; then
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

    echo "Bringing up interface: $iface"
    sudo ip link set "$iface" up
    sleep 2

    echo "Requesting IP via DHCP..."
    sudo pkill -f "dhcpcd.*$iface" 2>/dev/null || true
    sleep 1

    if ! sudo dhcpcd "$iface"; then
        return 1
    fi

    sleep "$TIMEOUT"
}

verify_connection() {
    local iface="$1"
    local ip_addr gateway

    ip_addr=$(ip addr show "$iface" | grep "inet " | awk '{print $2}')

    if [ -z "$ip_addr" ]; then
        return 1
    fi

    echo ""
    echo "✓ Connection established"
    echo "  Interface: $iface"
    echo "  IP: $ip_addr"

    gateway=$(ip route | grep "default.*$iface" | awk '{print $3}')
    if [ -n "$gateway" ]; then
        echo "  Gateway: $gateway"
    fi

    test_connectivity

    log "USB tethering connected: $iface - $ip_addr"
}

test_connectivity() {
    echo ""
    echo "Testing connectivity..."

    if ping -c 2 -W "$TIMEOUT" 8.8.8.8 >/dev/null 2>&1; then
        echo "  ✓ Internet connection working"

        if ping -c 2 -W "$TIMEOUT" google.com >/dev/null 2>&1; then
            echo "  ✓ DNS resolution working"
        else
            echo "  ⚠ DNS may not be working"
        fi
    else
        echo "  ⚠ Cannot reach internet"
    fi
}

show_instructions() {
    cat <<EOF
Error: No USB tethering interface detected

Please ensure:
  1. Android phone is connected via USB
  2. USB tethering is enabled:
     Settings → Network & Internet → Hotspot & tethering → USB tethering
  3. Phone is unlocked
  4. USB cable supports data transfer

EOF
}

main() {
    echo "USB Tethering Connection"
    echo "========================"
    echo ""

    local iface
    if ! iface=$(detect_usb_interface); then
        show_instructions
        log "ERROR: No USB tethering interface found"
        exit 1
    fi

    log "Detected interface: $iface"

    if ! configure_interface "$iface"; then
        echo "Error: DHCP configuration failed" >&2
        log "ERROR: DHCP failed on $iface"
        exit 1
    fi

    if ! verify_connection "$iface"; then
        echo "Error: Failed to obtain IP address" >&2
        log "ERROR: No IP assigned to $iface"
        exit 1
    fi

    echo ""
    echo "To disconnect: sudo dhcpcd -k $iface && sudo ip link set $iface down"
}

main "$@"
