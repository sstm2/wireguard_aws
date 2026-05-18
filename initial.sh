#!/bin/bash
set -eo pipefail

echo "# Installing Wireguard"

./remove.sh

./install.sh

./add-client.sh

echo "# Wireguard installed"
