#!/usr/bin/env bash
#
# install.sh - USB Tethering Installation Script
#
# Author: derp
# License: MIT

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALL_DIR="/usr/local/bin"
readonly UDEV_DIR="/etc/udev/rules.d"

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: This script must be run as root"
        echo "Usage: sudo $0"
        exit 1
    fi
}

check_dependencies() {
    if ! command -v dhcpcd &>/dev/null; then
        echo "Error: dhcpcd is not installed"
        echo "Install with: sudo pacman -S dhcpcd"
        exit 1
    fi
}

install_files() {
    echo "Installing USB tethering scripts..."

    install -m 755 "$SCRIPT_DIR/scripts/usb-tether-connect.sh" "$INSTALL_DIR/"
    install -m 755 "$SCRIPT_DIR/scripts/usb-tether-auto.sh" "$INSTALL_DIR/"
    install -m 755 "$SCRIPT_DIR/scripts/usb-tether-disconnect.sh" "$INSTALL_DIR/"
    install -m 755 "$SCRIPT_DIR/scripts/usb-tether-status.sh" "$INSTALL_DIR/"

    install -m 644 "$SCRIPT_DIR/udev/99-usb-tethering.rules" "$UDEV_DIR/"

    touch /var/log/usb-tethering.log
    chmod 666 /var/log/usb-tethering.log
}

reload_udev() {
    echo "Reloading udev rules..."
    udevadm control --reload-rules
    udevadm trigger
}

show_completion() {
    cat <<EOF

Installation complete!

USB Tethering is now configured.

AUTOMATIC MODE:
  1. Connect your Android phone via USB
  2. Enable USB tethering in phone settings
  3. Connection happens automatically

MANUAL MODE:
  Connect:    usb-tether-connect.sh
  Disconnect: usb-tether-disconnect.sh
  Status:     usb-tether-status.sh

PHONE SETUP:
  Settings → Network & Internet → Hotspot & tethering → USB tethering

View logs: tail -f /var/log/usb-tethering.log

EOF
}

main() {
    check_root
    check_dependencies
    install_files
    reload_udev
    show_completion
}

main "$@"
