echo "# Removing"
set -eo pipefail

echo "Are you sure you want to remove wireguard? Press [Enter] to continue or [Ctrl]+C to abort..."
read
echo "Are you really sure?"
read

wg-quick down wg0
systemctl stop wg-quick@wg0
systemctl disable wg-quick@wg0

yes | apt autoremove wireguard wireguard-dkms wireguard-tools
#yes | apt autoremove software-properties-common
yes | apt update

rm -rf /etc/wireguard

echo "# Removed"
