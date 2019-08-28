#!/bin/bash

set -o errexit

set -o nounset

set -o pipefail

set -o xtrace

BUILD_VERSION=2019.08.29
[[ -e build/_currentContainer ]] && CURRENT_CONTAINER=$(cat build/_currentContainer)
if [[ -z $CURRENT_CONTAINER ]]; then
	cn=$(buildah from golang:1.11.5)
	echo $cn > build/_currentContainer
else 
	cn=$CURRENT_CONTAINER
fi

m=$( buildah mount $cn )
mkdir -p "$m/go/src/github.com/subspacecloud/subspace"
cp -r *.go static templates email "$m/go/src/github.com/subspacecloud/subspace"
buildah umount $cn

buildah config --env GODEBUG="netdns=go http2server=0" --env GOPATH="/go" --env CGO_ENABLED=0 --env GOOS=linux --env GOARCH=amd64  --workingdir=/go/src/github.com/subspacecloud/subspace $cn

buildah run $cn -- apt-get update 
buildah run $cn -- apt-get install -y git 
buildah run $cn -- go get -v \
    github.com/jteeuwen/go-bindata/... \
    github.com/dustin/go-humanize \
    github.com/julienschmidt/httprouter \
    github.com/Sirupsen/logrus \
    github.com/gorilla/securecookie \
    golang.org/x/crypto/acme/autocert \
    golang.org/x/time/rate \
	golang.org/x/crypto/bcrypt \
    go.uber.org/zap \
	gopkg.in/gomail.v2 \
    github.com/crewjam/saml \
    github.com/dgrijalva/jwt-go \
    github.com/skip2/go-qrcode

buildah run $cn -- go-bindata --pkg main static/... templates/... email/... 
buildah run $cn -- go fmt 
buildah run $cn -- go vet --all
buildah run $cn -- go build -v --compiler gc --ldflags "-extldflags -static -s -w -X main.version=${BUILD_VERSION}" -o /usr/bin/subspace-linux-amd64
buildah run $cn -- find / -name subspace-linux-amd64

m=$(buildah mount $cn)
cp $m/usr/bin/subspace-linux-amd64 ./build

buildah umount $cn

#buildah rm $cn
#rm _currentContainer
