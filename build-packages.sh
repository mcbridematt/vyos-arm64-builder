#!/bin/sh
set -e
export DEBEMAIL="test@example.com"
BASEDIR=$(dirname $(readlink -f "$0"))
sudo apt-get install -y clang llvm libpcap-dev xz-utils python-is-python3 libbpf-dev linux-libc-dev
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

PACKAGES_DIR=$(readlink -f "vyos-build/packages")
cd "${PACKAGES_DIR}"

for d in $(find -name Jenkinsfile -exec dirname {} \;); do
	echo "BUILDING PACKAGE ${d}"
	cd "${d}"
	lua ../../../runjenkins.lua || :
	find -name \*.deb -exec cp {} "${PACKAGES_DIR}" \;
	cd "${PACKAGES_DIR}"
done

# Workaround for XDP compilation (done by gcc-multilib on other platforms)
ln -s /usr/include/aarch64-linux-gnu/asm /usr/include/asm

cd "${BASEDIR}"
REPOS=$(cat repos.txt)
mkdir -p build
eval $(opam env --root=/opt/opam --set-root)
for i in $REPOS; do
	PACKAGENAME=$i
	if [[ "${i}" = https://* ]]; then
		PACKAGENAME=$(echo "${i}" | awk -F '/' '{print $NF}' | sed "s/\.git//g")
		git clone "${i}" "${PACKAGENAME}"
	else
		git clone "https://github.com/vyos/${i}.git" "build/${i}"
	fi
	cd "build/${PACKAGENAME}"
	if [ "${PACKAGENAME}" = "vyos-1x" ]; then
		patch -p1 -i ../../vyos-1x-disable-testsuite.patch
		patch -p1 -i ../../vyos-1x-enable-xdp-build.patch
	elif [ "${PACKAGENAME}" = "ipaddrcheck" ]; then
		rm src/*.o
	elif [ "${PACKAGENAME}" = "python-inotify" ]; then
		patch -p1 -i "../../python-inotify-disable-test_renames.patch"
	fi
	dpkg-buildpackage -b -us -uc -tc
	cd ../..
done

cp build/*.deb vyos-build/packages/

