#!/bin/sh
qemu-system-aarch64 -nographic \
    --enable-kvm \
    -cpu host -machine virt \
    -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd  \
    -smp 2 -m 1024 \
    -device virtio-rng-pci \
    -hda vyos-drive.qcow2 \
    -cdrom vyos.iso \
    -netdev user,id=testlan -net nic,netdev=testlan \
    -netdev user,id=testwan -net nic,netdev=testwan

#    -cdrom vyos.iso \
