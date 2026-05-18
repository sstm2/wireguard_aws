#!/bin/bash
set -eo pipefail

echo This will bounce the VPN. Push [Enter] to continue, [Ctrl] + C to abort...
read
# Restart Wireguard
echo -n "Stopping...."
systemctl stop wg-quick@wg0
echo "[Done]"
echo -n "Starting...."
systemctl start wg-quick@wg0
echo "[Done]"

