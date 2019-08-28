#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

#
# WireGuard (10.99.97.0/24)
#
if ! test -d /data/wireguard ; then
    mkdir /data/wireguard
    cd /data/wireguard
    
    mkdir clients
    touch clients/null.conf # So you can cat *.conf safely
    mkdir peers
    touch peers/null.conf # So you can cat *.conf safely

    chmod a+rxw /data/wireguard/*
    # Generate public/private server keys.
    wg genkey | tee server.private | wg pubkey > server.public
fi

cat <<WGSERVER >/data/wireguard/server.conf
[Interface]
PrivateKey = $(cat /data/wireguard/server.private)
ListenPort = 51820

WGSERVER
cat /data/wireguard/peers/*.conf >>/data/wireguard/server.conf
