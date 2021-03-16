#!/bin/sh
set -e
BUILD_BY="matt@traverse.com.au"

if [ ! -f "/sbin/kpartx" ]; then
	apt-get install -y kpartx
fi
if [ ! -f "/sbin/parted" ]; then
	apt-get install -y parted
fi

#CONTAINER_NAME="vyos/vyos-build:current-arm64"
CONTAINER_NAME="vyos-arm64-libbpf"
PKGBUILD_CONTAINER=$(docker create -it --privileged --entrypoint "/bin/bash" -v $(pwd):/tmp/vyos-build-arm64 "${CONTAINER_NAME}")
docker start "${PKGBUILD_CONTAINER}"
docker exec -i -t "${PKGBUILD_CONTAINER}" /bin/bash -c 'cd /tmp/vyos-build-arm64 && ./build-packages.sh'
docker stop "${PKGBUILD_CONTAINER}"
docker rm "${PKGBUILD_CONTAINER}"

cd vyos-build
./configure --build-by="${BUILD_BY}" --architecture "arm64"
make arm64
