#!/usr/bin/env bash
#
# usb-tether-status.sh - USB Tethering Status Monitor
# Displays current USB tethering connection status
#
# Author: derp
# License: MIT

set -euo pipefail

readonly LOGFILE="/var/log/usb-tethering.log"
readonly TIMEOUT=3

show_interface_details() {
    local iface="$1"

    echo "Interface: $iface"
    echo "$(printf '%.0s-' {1..40})"

    if ip link show "$iface" 2>/dev/null | grep -q "state UP"; then
        echo "  Link: UP"
    else
        echo "  Link: DOWN"
    fi

    local ip_addr
    ip_addr=$(ip addr show "$iface" 2>/dev/null | grep "inet " | awk '{print $2}')
    echo "  IP: ${ip_addr:-Not assigned}"

    local mac_addr
    mac_addr=$(ip link show "$iface" 2>/dev/null | grep "link/ether" | awk '{print $2}')
    echo "  MAC: ${mac_addr:-Unknown}"

    if ip route | grep -q "default.*$iface"; then
        local gateway
        gateway=$(ip route | grep "default.*$iface" | awk '{print $3}')
        echo "  Gateway: $gateway"
        echo "  Default Route: YES"
    fi

    if pgrep -f "dhcpcd.*$iface" >/dev/null; then
        echo "  DHCP Client: Running"
    else
        echo "  DHCP Client: Not running"
    fi

    echo ""
}

test_connectivity() {
    echo "Connectivity Test"
    echo "$(printf '%.0s-' {1..40})"

    if ping -c 2 -W "$TIMEOUT" 8.8.8.8 >/dev/null 2>&1; then
        echo "  Internet: ✓ Working"
    else
        echo "  Internet: ✗ Not working"
    fi

    if ping -c 2 -W "$TIMEOUT" google.com >/dev/null 2>&1; then
        echo "  DNS: ✓ Working"
    else
        echo "  DNS: ✗ Not working"
    fi

    echo ""
}

show_public_ip() {
    echo "Public IP"
    echo "$(printf '%.0s-' {1..40})"

    local public_ip
    public_ip=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "Unknown")
    echo "  $public_ip"
    echo ""
}

show_recent_logs() {
    echo "Recent Logs"
    echo "$(printf '%.0s-' {1..40})"

    if [ -f "$LOGFILE" ]; then
        tail -5 "$LOGFILE"
    else
        echo "  No log file found"
    fi

    echo ""
}

main() {
    echo "USB Tethering Status"
    echo "========================================"
    echo ""

    local iface found=0

    for iface in /sys/class/net/*; do
        iface=$(basename "$iface")

        case "$iface" in
            usb*|rndis*|enp0s*u*)
                show_interface_details "$iface"
                found=1
                ;;
        esac
    done

    if [ "$found" -eq 0 ]; then
        echo "Status: NOT CONNECTED"
        echo ""
        echo "No USB tethering interface detected"
        echo ""
        echo "To connect:"
        echo "  1. Connect Android phone via USB"
        echo "  2. Enable USB tethering in phone settings"
        echo "  3. Run: usb-tether-connect.sh"
        return 0
    fi

    echo "Status: CONNECTED"
    echo ""

    test_connectivity
    show_public_ip
    show_recent_logs
}

main "$@"
