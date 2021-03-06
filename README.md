# ARM64 Bootstrap for VyOS

This repo can assist in bootstrapping a VyOS image for arm64, without
depending on the artifacts already generated by Jenkins.

The generated image is a qcow2 that will boot on ARM
Embedded and Server Base Boot systems (e.g those
that use EFI)

There are also a few minor hacks/patches applied which
should be upstreamed shortly.

If you are unfamiliar with the VyOS build process, see
the [Build VyOS](https://docs.vyos.io/en/latest/contributing/build-vyos.html)
page in the documentation.

Current hardware targets:
* QEMU ARM64 Virtual Machine with EDKII
* Traverse Technologies Ten64

**Note: only basic routing and NAT functionality
has been tested at this time.**

Build requirements:
* ARM64 host (no cross compiling)

* It is best to use a Debian machine as the
build host. Issues have been encountered with
AppArmor on Ubuntu

* Working docker installation

* sudo access from the current user

# Usage:
Run ./build.sh to build the 'vyos-build' container
and then packages and image.

```
./build.sh
```

A qcow2 image will be generated under vyos-build/build/VyOS-YYYYMMDD.qcow2

# Testing inside a VM
The `./testimg.sh` script can be used to boot
the generated qcow2 image as a QEMU/KVM virtual machine.

You need to run the script on a genuine arm64 host with virtualization
capabilities.

(It is possible to run it under emulation, but YMMV).

An EDK2 "bios" binary is required, under Debian you can use
the [qemu-efi-aarch64](https://packages.debian.org/buster/qemu-efi-aarch64) package
or grab a build from [retrage/edk2-nightly](https://retrage.github.io/edk2-nightly/).

```
cp vyos-build/build/VyOS-YYYYMMDD.qcow2 VyOS.qcow2
sudo ./testimg.sh
```
(Hint: Use Ctrl-X to immediately exit qemu).

# Known issues:

* It should be possible to generate an ISO image using
the usual `make iso`, however, there appears to be issues
with the syslinux setup.
