Datadir=$1 
ProfileID=$2
ProfileNumber=$3
Domain=$4

cd $Datadir/wireguard
wg_private_key="$(wg genkey)"
wg_public_key="$(echo $wg_private_key | wg pubkey)"

#wg set wg0 peer ${wg_public_key} allowed-ips 10.99.97.$ProfileNumber/32,fd00::10:97:$ProfileNumber/128

cat <<WGPEER >peers/$ProfileID.conf
[Peer]
PublicKey = ${wg_public_key}
AllowedIPs = 10.99.97.$ProfileNumber/32,fd00::10:97:$ProfileNumber/128

WGPEER

cat <<WGCLIENT >clients/$ProfileID.conf
[Interface]
PrivateKey = ${wg_private_key}
DNS = 10.99.97.1, fd00::10:97:1
Address = 10.99.97.$ProfileNumber/22,fd00::10:97:$ProfileNumber/112

[Peer]
PublicKey = $(cat server.public)
Endpoint = $Domain:51820
AllowedIPs = 0.0.0.0/0, ::/0
WGCLIENT

