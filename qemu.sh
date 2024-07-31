#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later

set -e

[[ $# -lt 2 ]] && {
    echo "${0##*/}: [UKERNEL] [DISK] -- [QEMU parameters]."
    exit 1
}

UKERNEL=${1}
if [ ! -f ${UKERNEL} ]; then
    echo "'${UKERNEL}' does not exist."
    exit 1
fi

shift 1

WORKSPACE=${1}
if [ ! -d ${WORKSPACE} ]; then
    echo "'${WORKSPACE}' does not exist."
    exit 1
fi

shift 1

# CREATE DISK.
DISK=${WORKSPACE}/disk.img
if [ ! -f ${DISK} ]; then
    echo "'${DISK}' does not exist."

    qemu-img create -f raw ${DISK} 50M

    parted ${DISK} --script -- mklabel gpt
    parted ${DISK} --script -- mkpart ESP fat32 1MiB 100%
    parted ${DISK} --script -- set 1 boot on

    DEVICE=$(sudo losetup -fP --show ${DISK})
    PART=${DEVICE}p1

    sudo mkfs.vfat -F 32 ${PART}
else
    DEVICE=$(sudo losetup -fP --show ${DISK})
    PART=${DEVICE}p1
fi

mkdir -p ${WORKSPACE}/mnt

# PREPARE DISK.
sudo mount ${PART} ${WORKSPACE}/mnt
sudo mkdir -p ${WORKSPACE}/mnt/EFI/BOOT
echo "  copy $(basename ${UKERNEL}) /EFI/BOOT/BOOTX64.EFI"
sudo cp ${UKERNEL} ${WORKSPACE}/mnt/EFI/BOOT/BOOTX64.EFI
sudo echo "fs0:\EFI\BOOT\BOOTX64.EFI" | sudo tee /mnt/startup.nsh
sudo umount ${WORKSPACE}/mnt

sudo losetup -d ${DEVICE}

COMMAND=${1}
shift 1

case ${COMMAND} in
    "--")
        echo "(Starting QEMU)"
        qemu-system-x86_64 \
            -drive file=${DISK},format=raw \
            -bios /usr/share/ovmf/OVMF.fd \
            $@
        ;;
    *)
        ;;
esac

exit 0