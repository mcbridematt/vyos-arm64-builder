#!/bin/sh
set -e
BUILD_BY="matt@traverse.com.au"

CURDIR_PATH=$(pwd)
CURDIR_UID=$(stat -c '%u' .)
CURDIR_GID=$(stat -c '%g' .)
CURDIR_GROUP=$(stat -c '%G' .)
CURDIR_USER=$(stat -c '%U' .)
echo "Will run container as ${CURDIR_UID}:${CURDIR_GID}"
#CONTAINER_NAME="vyos/vyos-build:current-arm64"
CONTAINER_NAME="vyos-arm64-libbpf"
docker build -t "${CONTAINER_NAME}" vyos-build/docker/
PKGBUILD_CONTAINER=$(docker create -it --privileged --sysctl net.ipv6.conf.lo.disable_ipv6=0 --entrypoint "/bin/bash" -v $(pwd):/tmp/vyos-build-arm64 "${CONTAINER_NAME}")
docker start "${PKGBUILD_CONTAINER}"
docker exec -i -t "${PKGBUILD_CONTAINER}" /bin/bash -c "groupadd -g ${CURDIR_GID} ${CURDIR_GROUP}; useradd -u ${CURDIR_UID} -g ${CURDIR_GID} -G sudo -m ${CURDIR_USER}"
docker exec -u "${CURDIR_UID}" -i -t "${PKGBUILD_CONTAINER}" /bin/bash -c "cd /tmp/vyos-build-arm64 && ./build-packages.sh"
docker exec -i -t "${PKGBUILD_CONTAINER}" /bin/bash -c "cd /tmp/vyos-build-arm64/vyos-build && ./build-vyos-image --architecture=arm64 --build-by="${BUILD_BY}" --debug --build-type=development iso"
docker stop "${PKGBUILD_CONTAINER}"
docker rm "${PKGBUILD_CONTAINER}"
