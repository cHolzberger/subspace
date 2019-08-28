#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

/usr/local/bin/init.sh
# Require environment variables.
if [ -z "${SUBSPACE_HTTP_HOST-}" ] ; then
 #   echo "Environment variable SUBSPACE_HTTP_HOST required. Exiting."
#    exit 1
export SUBSPACE_HTTP_HOST="ch-clr.ad.mosaiksoftware.de"
fi

# Optional environment variables.
if [ -z "${SUBSPACE_BACKLINK-}" ] ; then
    export SUBSPACE_BACKLINK=""
fi

if [ -z "${SUBSPACE_LETSENCRYPT-}" ] ; then
    export SUBSPACE_LETSENCRYPT="false"
fi

if [ -z "${SUBSPACE_HTTP_ADDR-}" ] ; then
    export SUBSPACE_HTTP_ADDR=":80"
fi

if [ -z "${SUBSPACE_HTTP_INSECURE-}" ] ; then
    export SUBSPACE_HTTP_INSECURE="true"
fi

export NAMESERVER="1.1.1.1"
export DEBIAN_FRONTEND="noninteractive"

# Set DNS server
echo "nameserver ${NAMESERVER}" >/etc/resolv.conf

# dnsmasq service
if ! test -d /etc/sv/dnsmasq ; then
    cat <<DNSMASQ >/etc/dnsmasq.conf
    # Only listen on necessary addresses.
    listen-address=127.0.0.1,10.99.97.1,fd00::10:97:1

    # Never forward plain names (without a dot or domain part)
    domain-needed

    # Never forward addresses in the non-routed address spaces.
    bogus-priv
DNSMASQ

    mkdir /etc/sv/dnsmasq
    cat <<RUNIT >/etc/sv/dnsmasq/run
#!/bin/sh
exec /usr/sbin/dnsmasq --no-daemon
RUNIT
    chmod +x /etc/sv/dnsmasq/run

# dnsmasq service log
    mkdir /etc/sv/dnsmasq/log
    mkdir /etc/sv/dnsmasq/log/main
    cat <<RUNIT >/etc/sv/dnsmasq/log/run
#!/bin/sh
exec svlogd -tt ./main
RUNIT
    chmod +x /etc/sv/dnsmasq/log/run
    ln -s /etc/sv/dnsmasq /etc/service/dnsmasq
fi

# subspace service
if ! test -d /etc/sv/subspace ; then
    mkdir /etc/sv/subspace
    cat <<RUNIT >/etc/sv/subspace/run
#!/bin/sh
exec /usr/bin/subspace \
    "--http-host=${SUBSPACE_HTTP_HOST}" \
    "--http-addr=${SUBSPACE_HTTP_ADDR}" \
    "--http-insecure=${SUBSPACE_HTTP_INSECURE}" \
    "--backlink=${SUBSPACE_BACKLINK}" \
    "--letsencrypt=${SUBSPACE_LETSENCRYPT}"
RUNIT
    chmod +x /etc/sv/subspace/run

    # subspace service log
    mkdir /etc/sv/subspace/log
    mkdir /etc/sv/subspace/log/main
    cat <<RUNIT >/etc/sv/subspace/log/run
#!/bin/sh
exec svlogd -tt ./main
RUNIT
    chmod +x /etc/sv/subspace/log/run
    ln -s /etc/sv/subspace /etc/service/subspace
fi

exec $@
