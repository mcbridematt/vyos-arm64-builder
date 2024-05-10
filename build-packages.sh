#!/bin/bash
set -e
export DEBEMAIL="test@example.com"
BASEDIR=$(dirname $(readlink -f "$0"))
PATCHES_DIR=$(readlink -f "${BASEDIR}/patches")

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

git config --global --add safe.directory $(readlink -f "vyos-build")

PACKAGES_DIR=$(readlink -f "vyos-build/packages")
cd "${PACKAGES_DIR}"

for d in $(find -name Jenkinsfile -exec dirname {} \;); do
	echo "BUILDING PACKAGE ${d}"
	cd "${d}"
	lua ../../../runjenkins.lua || :
	find -name \*.deb -exec cp {} "${PACKAGES_DIR}" \;
	cd "${PACKAGES_DIR}"
done

cd "${BASEDIR}"
REPOS=$(cat repos.txt)
mkdir -p build
eval $(opam env --root=/opt/opam --set-root)
for i in $REPOS; do
	PACKAGENAME=$(echo "${i}" | awk -F ';' '{print $1}')
	PACKAGECOMMIT=$(echo "${i}" | awk -F ';' '{print $2}')
	if [[ "${PACKAGENAME}" = https://* ]]; then
		PACKAGE_FOLDER_NAME=$(echo "${PACKAGENAME}" | awk -F '/' '{print $NF}' | sed "s/\.git//g")
		git clone "${PACKAGENAME}" "build/${PACKAGE_FOLDER_NAME}"
		PACKAGENAME="${PACKAGE_FOLDER_NAME}"
	else
		git clone "https://github.com/vyos/${PACKAGENAME}.git" "build/${PACKAGENAME}"
	fi
	cd "build/${PACKAGENAME}"
	if [ -n "${PACKAGECOMMIT}" ]; then
		git checkout "${PACKAGECOMMIT}"
	fi
	if [ "${PACKAGENAME}" = "ipaddrcheck" ]; then
		rm src/*.o
	elif [ "${PACKAGENAME}" = "python-inotify" ]; then
		patch -p1 -i "${PATCHES_DIR}/python-inotify-disable-test_renames.patch"
	elif [ "${PACKAGENAME}" = "vyos-live-build" ]; then
		patch -p1 -i "${PATCHES_DIR}/vyos-live-build-traverse-only-disable-iso-secure-boot.patch"
	fi
	echo "y" | mk-build-deps --install --remove
	dpkg-buildpackage -b -us -uc -tc
	cd "${BASEDIR}"
done

# Use our copy of live-build to do image building
dpkg -i build/live-build*.deb
cp build/*.deb vyos-build/packages/
find vyos-build/packages/ -name '*-build-deps*deb' -exec rm {} \;
