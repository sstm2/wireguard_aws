#!/bin/bash
set -eo pipefail

WG_CONF_DIR="/etc/wireguard"
DEFAULT_CONF="wg0"

# input param is config name
CONF_NAME="${1:-$DEFAULT_CONF}"
CONF_FILE="${CONF_NAME}.conf"

# testing
# CONF_FILE="${CONF_FILE}.test"


# should fail if not root
cd "$WG_CONF_DIR"


_replace_text_file()
{
  local -r DESC="$1"
  local -r FILE="$2"
  local -r NEW_FILE="$3"

  if [[ -f "$FILE" ]]; then
    if diff "$FILE" "$NEW_FILE"; then
      rm "$NEW_FILE"
      echo "No differences found, existing $DESC file '$FILE' not replaced"
    else
      echo
      local -r FILE_DATE="${FILE}.$( date -r "$FILE" "+%Y%m%d" )"
      if ls "$FILE_DATE"* &>/dev/null; then
        if [[ -f "$FILE_DATE" ]]; then
          local -r FILE_DATETIME="${FILE_DATE}-$( date -r "$FILE_DATE" "+%H%M%S" )"
          mv "$FILE_DATE" "$FILE_DATETIME"
          echo "Existing $DESC backup file '$FILE_DATE' renamed to '$FILE_DATETIME'"
        fi
        local -r FILE_BACKUP="${FILE_DATE}-$( date -r "$FILE" "+%H%M%S" )"
      else
        local -r FILE_BACKUP="$FILE_DATE"
      fi
      cp -p "$FILE" "$FILE_BACKUP"
      echo "Differences found, existing $DESC file '$FILE' backed up to '$FILE_BACKUP'"
    fi
  fi

  if [[ -f "$NEW_FILE" ]]; then
    mv "$NEW_FILE" "$FILE"
    echo "New $DESC file '$FILE' created"
  fi
}


echo "Rebuilding config '$CONF_NAME' to file: $WG_CONF_DIR/$CONF_FILE"

CONF_FILE_NEW="${CONF_FILE}.new"


INT_ADDRESS="$( cat ./vpn_subnet.var )1"
INT_PRIV_KEY="$( cat ./server_private.key )"
INT_LISTEN_PORT="$( cut -d: -f2 ./endpoint.var )"

# init with server interface
cat > "$CONF_FILE_NEW" << EOF
[Interface]
# main interface
Address = $INT_ADDRESS
SaveConfig = false
PrivateKey = $INT_PRIV_KEY
ListenPort = $INT_LISTEN_PORT
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE;
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ens5 -j MASQUERADE;

EOF


# add each client based on stored conf
for CLIENT_DIR in $( ls -Adrt ./clients/* ); do
#  echo "$CLIENT_DIR"

  CLIENT_NAME="$( basename "$CLIENT_DIR" )"
  CLIENT_CONF_FILE="./clients/${CLIENT_NAME}/${CLIENT_NAME}.conf"
#  echo "$CLIENT_CONF_FILE"

  # grep conf values from file
  CLIENT_PRIV_KEY="$( grep -E "^PrivateKey = " "$CLIENT_CONF_FILE" | cut -d= -f2- )"
  CLIENT_ADDRESS="$( grep -E "^Address = " "$CLIENT_CONF_FILE" | cut -d= -f2- )"
  CLIENT_PRESHARED_KEY="$( grep -E "^PresharedKey = " "$CLIENT_CONF_FILE" | cut -d= -f2- )"

  # gen pub key from private
  CLIENT_PUB_KEY="$( echo "${CLIENT_PRIV_KEY#[[:space:]]}" | wg pubkey )"

  # add client to conf file
  cat >> "$CONF_FILE_NEW" << EOF
[Peer]
# $CLIENT_NAME
PublicKey = ${CLIENT_PUB_KEY#[[:space:]]}
PresharedKey = ${CLIENT_PRESHARED_KEY#[[:space:]]}
AllowedIPs = ${CLIENT_ADDRESS#[[:space:]]}

EOF
done


# cat "$CONF_FILE_NEW"

_replace_text_file "'$CONF_NAME' config" "$CONF_FILE" "$CONF_FILE_NEW"
