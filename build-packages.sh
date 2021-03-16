#!/bin/sh
set -e
BASEDIR=$(dirname $(readlink -f "$0"))
sudo apt-get install -y clang llvm libpcap-dev
# Do linux kernel first as we need our kernel headers
# for XDP
pwd
if [ ! -d "vyos-build" ]; then
	echo "ERROR: No vyos-build found"
	pwd
	ls -la .
	exit 1
	git clone https://github.com/vyos/vyos-build
fi

cd vyos-build/packages/linux-kernel

rm -rf linux
KERNEL_VER=$(cat ../../data/defaults.json | jq -r .kernel_version)
if [ ! -f "linux-${KERNEL_VER}.tar.xz" ]; then
	curl -OL https://www.kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VER}.tar.xz
fi

tar -Jxf "linux-${KERNEL_VER}".tar.xz
mv "linux-${KERNEL_VER}" linux

./build-kernel.sh

dpkg -i ../linux-headers*.deb
dpkg -i ../linux-libc-dev*.deb

ln -s /usr/include/aarch64-linux-gnu/asm /usr/include/asm

git clone https://github.com/accel-ppp/accel-ppp.git
git -C accel-ppp checkout 59f8e1bc3f199c8d0d985253e19a74ad87130179
./build-accel-ppp.sh
cp accel-ppp*.deb ..

cd ../frr/
git clone --branch "stable/7.5" https://github.com/FRRouting/frr.git
./build-frr.sh
cp frr*.deb ..

cd "${BASEDIR}"
pwd

REPOS=$(cat repos.txt)
mkdir -p build
eval $(opam env --root=/opt/opam --set-root)
for i in $REPOS; do
	git clone "https://github.com/vyos/${i}.git" "build/${i}"
	cd "build/${i}"
	if [ "${i}" == "vyos-1x" ]; then
		patch -p1 -i ../../vyos-1x-disable-testsuite.patch
		patch -p1 -i ../../vyos-1x-enable-xdp-build.patch
	fi
	dpkg-buildpackage -b -us -uc -tc
	cd ../..
done


cp build/*.deb vyos-build/packages/
