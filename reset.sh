echo "# Resetting..."
set -eo pipefail

echo "Are you sure you want to delete all clients and put the server back to initial state? Press [Enter] to continue or [Ctrl]+C to abort..."
read
echo "Are you really sure?"
read

cd /etc/wireguard

# Delete the folder with customer data
rm -rf ./clients

# Zero IP counter
echo "1" > last_used_ip.var

# Resetting the server configuration template to default settings
cp -f wg0.conf.def wg0.conf

systemctl stop wg-quick@wg0
wg-quick down wg0

echo "# Resetted"
