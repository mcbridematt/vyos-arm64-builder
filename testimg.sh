#!/bin/sh
qemu-system-aarch64 -nographic \
    --enable-kvm \
    -cpu host -machine virt \
    -bios QEMU_EFI.fd \
    -smp 2 -m 1024 \
    -device virtio-rng-pci \
    -hda VyOS.qcow2 \
    -netdev user,id=testlan -net nic,netdev=testlan \
    -netdev user,id=testwan -net nic,netdev=testwan

