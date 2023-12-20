#!/bin/sh
set -e
BUILD_BY="matt@traverse.com.au"

#apt-get install -y kpartx make pbuilder devscripts python3-pystache python3-git python3-setuptools parted dosfstools python3-toml python3-jinja2
#CONTAINER_NAME="vyos/vyos-build:current-arm64"
CONTAINER_NAME="vyos-build-arm64"
docker build -t "${CONTAINER_NAME}" vyos-build/docker/
PKGBUILD_CONTAINER=$(docker create -it --privileged --sysctl net.ipv6.conf.lo.disable_ipv6=0 --entrypoint "/bin/bash" -v $(pwd):/tmp/vyos-build-arm64 "${CONTAINER_NAME}")
docker start "${PKGBUILD_CONTAINER}"
docker exec -i -t "${PKGBUILD_CONTAINER}" /bin/bash -c 'cd /tmp/vyos-build-arm64 && ./build-packages.sh'
docker exec -i -t "${PKGBUILD_CONTAINER}" /bin/bash -c "cd /tmp/vyos-build-arm64/vyos-build && ./build-vyos-image --architecture=arm64 --build-by="${BUILD_BY}" --debug --build-type=development iso"
docker stop "${PKGBUILD_CONTAINER}"
docker rm "${PKGBUILD_CONTAINER}"
