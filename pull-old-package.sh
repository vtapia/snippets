#!/bin/bash

URLBASE="https://launchpad.net/ubuntu"

# https://launchpad.net/ubuntu/xenial/amd64/libvirt0/1.3.1-1ubuntu10.12

RELEASE=$1
PACKAGE=$2
VERSION=$3
ARCH="amd64"

URL="${URLBASE}/${RELEASE}/${ARCH}/${PACKAGE}/${VERSION}"

PKGURL=$(curl -s ${URL} | grep http://launchpadlibrarian | awk -F\" '{print $4}')

wget ${PKGURL}

