# Android USB Tethering

Automatic USB tethering system for Android devices with detection, connection, and monitoring.

## Overview

Connect your Android phone via USB and automatically use its mobile data connection on your Arch Linux system.

**Features:**
- Automatic detection and connection
- Manual control mode
- Status monitoring
- Desktop notifications
- Works with all major Android manufacturers
- Comprehensive logging

## Installation

```bash
sudo ./install.sh
```

This will:
- Install scripts to `/usr/local/bin/`
- Install udev rules for automatic detection
- Create log file at `/var/log/usb-tethering.log`
- Reload udev rules

### Prerequisites

Install dhcpcd:
```bash
sudo pacman -S dhcpcd
```

## Usage

### Automatic Mode (Recommended)

After installation, USB tethering works automatically:

1. Connect your Android phone via USB
2. Unlock the phone
3. Enable USB tethering:
   - **Settings → Network & Internet → Hotspot & tethering → USB tethering**
4. Wait 3-5 seconds for automatic connection
5. You'll receive a desktop notification when connected

### Manual Mode

If you prefer manual control:

```bash
# Connect
usb-tether-connect.sh

# Disconnect
usb-tether-disconnect.sh

# Check status
usb-tether-status.sh
```

## Android Phone Setup

### Enable USB Tethering

**Stock Android / Pixel:**
```
Settings → Network & Internet → Hotspot & tethering → USB tethering (toggle ON)
```

**Samsung:**
```
Settings → Connections → Mobile Hotspot and Tethering → USB tethering (toggle ON)
```

**OnePlus:**
```
Settings → Wi-Fi & Network → Hotspot & tethering → USB tethering (toggle ON)
```

**Xiaomi:**
```
Settings → Connection & sharing → Portable hotspot → USB tethering (toggle ON)
```

## Scripts

### usb-tether-connect.sh

Manual connection script with detailed feedback.

**Output:**
- Interface detection
- DHCP configuration
- IP address assignment
- Connectivity tests
- DNS verification

### usb-tether-disconnect.sh

Disconnects all active USB tethering interfaces.

### usb-tether-status.sh

Displays comprehensive connection status:
- Interface details
- IP configuration
- DHCP client status
- Internet connectivity
- DNS resolution
- Public IP address
- Recent log entries

### usb-tether-auto.sh

Automatic connection script triggered by udev. Not meant to be run manually.

## Troubleshooting

### No Interface Detected

**Check USB cable:**
- Must support data transfer (not charging-only)
- Try different USB port
- Try different cable

**Check phone:**
- Phone must be unlocked
- USB tethering must be enabled
- Some phones require "File Transfer" mode

**Verify interface:**
```bash
ls /sys/class/net/
# Look for: usb0, rndis0, or similar
```

### DHCP Fails

**Manual IP configuration:**
```bash
# Find interface
USB_IFACE=$(ls /sys/class/net/ | grep usb)

# Configure manually
sudo ip addr add 192.168.42.100/24 dev $USB_IFACE
sudo ip link set $USB_IFACE up
sudo ip route add default via 192.168.42.1 dev $USB_IFACE
```

**Check dhcpcd:**
```bash
sudo pacman -S dhcpcd
```

### Connection Drops

**Enable "Stay awake" on phone:**
```
Developer options → Stay awake (keeps phone on while charging)
```

**Disable USB autosuspend:**
```bash
echo -1 | sudo tee /sys/module/usbcore/parameters/autosuspend
```

### Automatic Mode Not Working

**Check udev rules:**
```bash
cat /etc/udev/rules.d/99-usb-tethering.rules
```

**Reload udev:**
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

**Test manually:**
```bash
usb-tether-connect.sh
```

## Advanced Usage

### Priority Routing

If you have both WiFi and USB tethering:

**Make USB primary:**
```bash
USB_IFACE=$(ls /sys/class/net/ | grep usb)
sudo ip route del default
sudo ip route add default via 192.168.42.1 dev $USB_IFACE
```

### Use with VPN

```bash
# Start USB tethering
usb-tether-connect.sh

# Route specific apps through VPN
vopono-random-usa.sh firefox
```

### Monitor Data Usage

```bash
# Show interface statistics
ip -s link show $(ls /sys/class/net/ | grep usb)
```

## Network Configuration

### Default Settings

Android USB tethering typically uses:
- **Phone IP:** 192.168.42.1 (gateway)
- **Computer IP:** 192.168.42.xxx (DHCP assigned)
- **Subnet:** 192.168.42.0/24
- **DNS:** Google DNS or carrier DNS

### Supported Interfaces

- `usb0`, `usb1` - Standard USB network devices
- `rndis0` - RNDIS protocol (most Android devices)
- `enp0s20u1` - Systemd predictable naming

## Logs and Monitoring

### View Real-time Logs

```bash
tail -f /var/log/usb-tethering.log
```

### Check Connection Events

```bash
# Recent logs
tail -20 /var/log/usb-tethering.log

# USB kernel messages
dmesg | grep -i usb | tail -20

# Network interface logs
journalctl -u NetworkManager | tail -20
```

## Uninstall

```bash
# Remove udev rules
sudo rm /etc/udev/rules.d/99-usb-tethering.rules

# Remove scripts
sudo rm /usr/local/bin/usb-tether-*.sh

# Reload udev
sudo udevadm control --reload-rules

# Disconnect active connections
usb-tether-disconnect.sh
```

## Security Considerations

- USB tethering uses your phone's mobile data plan
- More secure than public WiFi (direct connection)
- No encryption between phone and computer (local link only)
- Firewall rules apply to USB interface

## Requirements

- Android 5.0+ with USB tethering support
- dhcpcd
- udev
- sudo privileges
- libnotify (optional, for notifications)

## Supported Devices

All major Android manufacturers:
- Google (Pixel, Nexus)
- Samsung
- OnePlus
- Xiaomi
- Motorola
- LG
- Sony
- HTC
- Huawei

## License

MIT License
