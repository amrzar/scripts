 #!/bin/bash

 #
 # Copyright 2020 Amirreza Zarrabi <amrzar@gmail.com>
 #
 # This program is free software; you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation; either version 2 of the License, or
 # (at your option) any later version.
 #
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 #

BOOT=boot
GRUBCONFIG=grub.cfg

 # include the 'shared' script.
source "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"/common.sh

show_usage () {
    cat <<EOF
$PROGNAME: generate a disk image using GRUB
    
Usage:
    $PROGNAME 

Options:
    --kernel=file      Path to kernel binary (multiboot2 compatible)
    --size=size         Disk image size
    --bp=size           Size of the bootable partition
    --output=path       Target directory for generated disk image
    
    --log=file          Log file
EOF
}

parse_argument kernel:,size:,bp:,output:,log:,help "$@"
if [[ $? -eq 0 ]]; then
    die "Use ''$PROGNAME --help'' for list of options!"
fi

get_argument output OUTPUT
get_argument log LOG 
get_argument size DISKSIZE
get_argument bp BOOTPARTITION
get_argument kernel KERNEL
get_argument help HELP

if [[ -v HELP || \
    ! -v DISKSIZE || \
    ! -v BOOTPARTITION || \
    ! -v KERNEL ]]; then
    show_usage
    exit 0
fi

if [[ -z ${DISKSIZE##*[!0-9]*} ]]; then
    die "''--size'' expect integer."
fi

if [[ -z ${BOOTPARTITION##*[!0-9]*} ]]; then
    die "''--bp'' expect integer."
fi

if [[ $BOOTPARTITION -gt $DISKSIZE ]]; then
    die "bootable partition is larger than disk size."
fi

if [[ ! -f "$KERNEL" ]]; then
    die "''$KERNEL'' does not exist."
fi

 # ... initialise defaults.
[[ -v OUTPUT ]] || OUTPUT="$PWD/DISK.img"
[[ -v LOG ]] || LOG=/dev/null

info "Building ''DISK.img'' ..."
dd if=/dev/zero of="$OUTPUT" count=$DISKSIZE bs=1M &>> "$LOG" || die "''dd'' faild."

 # cleanup ...
Err () {
    rm "$OUTPUT"
    die $1
}

parted --script "$OUTPUT" mklabel msdos \
    mkpart p ext2 1 $BOOTPARTITION set 1 boot on &>> "$LOG" ||
    Err "''parted'' failed."

dev_loop=$(sudo losetup --partscan --find --show "$OUTPUT" 2>> "$LOG") || 
    Err "''losetup'' failed."

info "Formatting primary partition (${dev_loop}p1) ..."
sudo mkfs -t ext2 ${dev_loop}p1 &>> "$LOG"
if [[ $? -ne 0 ]]; then
    sudo losetup --detach $dev_loop
    Err "''mkfs'' failed."
fi

tmp_dir=$(mktemp -d -t disk-XXXX)
if [[ $? -ne 0 ]]; then
    sudo losetup --detach $dev_loop
    Err "''mktemp'' failed."
fi

sudo mount ${dev_loop}p1 $tmp_dir &>> "$LOG"
if [[ $? -ne 0 ]]; then
    rm -rf $tmp_dir # ... remove temp directory.

    sudo losetup --detach $dev_loop
    Err "''mount'' failed."
fi

sudo mkdir -p $tmp_dir/$BOOT/grub
sudo cp "$KERNEL" $tmp_dir/$BOOT

sudo tee $tmp_dir/$BOOT/grub/$GRUBCONFIG >/dev/null <<EOF
    set timeout=10
    set default=0

    menuentry "cyanea OS" {
        multiboot2 /$BOOT/$(basename "$KERNEL")
        boot
    }
EOF

echo "(hd0) $dev_loop" > .device.map

info "Installing GRUB..."
sudo grub-install --no-floppy --grub-mkdevicemap=.device.map            \
    --modules="biosdisk part_msdos ext2 configfile normal multiboot"    \
    --boot-directory=$tmp_dir/${BOOT} --target=i386-pc $dev_loop &>> "$LOG"

sleep 1 # ... make sure we are done.

sudo umount $tmp_dir
rm -rf $tmp_dir
rm .device.map
 
sudo losetup --detach $dev_loop
