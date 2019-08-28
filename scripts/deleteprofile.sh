# WireGuard
Datadir="$1"
ProfileID="$2"
cd $Datadir/wireguard
peerid=$(cat peers/$ProfileID.conf | perl -ne 'print $1 if /PublicKey\s*=\s*(.*)/')
#wg set wg0 peer $peerid remove
rm peers/$ProfileID.conf
rm clients/$ProfileID.conf

