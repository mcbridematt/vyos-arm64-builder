#!/bin/sh
set -e
BUILD_BY="matt@traverse.com.au"

apt-get install -y kpartx make live-build pbuilder devscripts python3-pystache python3-git python3-setuptools parted dosfstools python3-toml python3-jinja2
#CONTAINER_NAME="vyos/vyos-build:current-arm64"
CONTAINER_NAME="vyos-arm64-libbpf"
docker build -t "${CONTAINER_NAME}" vyos-build/docker/
PKGBUILD_CONTAINER=$(docker create -it --privileged --entrypoint "/bin/bash" -v $(pwd):/tmp/vyos-build-arm64 "${CONTAINER_NAME}")
docker start "${PKGBUILD_CONTAINER}"
docker exec -i -t "${PKGBUILD_CONTAINER}" /bin/bash -c 'cd /tmp/vyos-build-arm64 && ./build-packages.sh'
docker stop "${PKGBUILD_CONTAINER}"
docker rm "${PKGBUILD_CONTAINER}"

cd vyos-build
##export VYOS_BUILD_FLAVOUR=generic-arm64
./build-vyos-image --architecture=arm64 --build-by="${BUILD_BY}" --debug --build-type=development iso
