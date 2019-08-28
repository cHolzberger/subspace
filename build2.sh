#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace
cn=$(buildah from clearlinux:base)
m=$(buildah mount $cn)

[[ -z $m ]] && echo "error nonexisting $m" && exit -1

mkdir -p $m/usr/local/bin $m/data $m/etc/sv $m/etc/service

cp build/subspace-linux-amd64 $m/usr/bin/subspace
cp scripts/* $m/usr/local/bin/
chmod +x $m/usr/bin/subspace $m/usr/local/bin/*

buildah umount $cn
buildah run $cn -- swupd bundle-add  dhcp-server iptables iproute2 network-basic

#NTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

#MD [ "/sbin/my_init" ]

buildah commit $cn  "mosaiksoftware/subspace:latest"
buildah commit $cn  "docker.io/cholzberger/subspace:latest"
