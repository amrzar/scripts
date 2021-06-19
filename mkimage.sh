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

sanitise_integer () {
    [[ ! -z "${1##*[!0-9]*}" ]] || die $2
}

parse_argument kernel:,parts:,labels:,bootp:,disk:,gpt,efi,output:,log:,help "$@"
if [[ $? -eq 0 ]]; then
    die "Use ''$PROGNAME --help'' for list of options!"
fi

get_argument kernel KERNEL
get_argument parts PARTITIONS
get_argument bootp BOOTP
get_argument gpt GPT
get_argument efi EFI
get_argument output OUTPUT "$PWD/DISK.img"
get_argument log LOG /dev/null
get_argument help HELP

# if [[ -v HELP || \
#     ! -v KERNEL || \
#     ! -v PARTITIONS || \
#     ! -v BOOTP]]; then
#     show_usage
#     exit 0
# fi

# if [[ ! -f "$KERNEL" ]]; then
#     die "''$KERNEL'' does not exist."
# fi

IFS=',' read -r -a PARTITIONS <<< "$PARTITIONS"
for i in "${!PARTITIONS[@]}"; do
    sanitise_integer "${PARTITIONS[$i]}" "''--parts'' needs comma-separated integers."
done

[[ $(printf '%s\n' "${PARTITIONS[@]}" | uniq -d) -eq 0 ]] ||
    die "''--parts'' needs uniqe entries."

readarray -t PARTITIONS < <(printf '%s\n' "${PARTITIONS[@]}" | sort -n)

get_argument labels LABELS
if [[ -v LABELS ]]; then
    IFS=',' read -r -a LABELS <<< "$LABELS"
    [[ ${#PARTITIONS[@]} -eq ${#LABELS[@]} ]] ||
        die "''--labels'' does not match partitions."
else
    for i in "${!PARTITIONS[@]}"; do
        LABELS[$i]="partition-$i"
    done
fi

sanitise_integer "$BOOTP" "''--bootp'' expect integer."
[[ $BOOTP -gt 0 && $BOOTP -le ${#PARTITIONS[@]} ]] ||
    die "range for ''--bootp'' is [1, ${#PARTITIONS[@]}]."

if [[ -v GPT ]]; then
    # ... get DISK size in MiB, otherwise uses ending ''PARTITIONS[-1]''
    # plus 1 MiB for secondary GPT table in place.

    get_argument disk DISKSIZE $((PARTITIONS[-1] + 1))
    sanitise_integer "$DISKSIZE" "''--disk'' expect integer."

    [[ $DISKSIZE -ge $((PARTITIONS[-1] + 1)) ]] ||
        die "the location of last partition is outside of the disk."

    info "Building ''DISK.img'' for ${DISKSIZE}MiB ..."
    dd if=/dev/zero of="$OUTPUT" count=$DISKSIZE bs=1M &>> "$LOG" ||
        die "''dd'' faild."

    info "Making GPT partition table ..."
    parted "$OUTPUT" --script mklabel gpt

    if [[ -v EFI ]]; then
        # ... EFI system partition with GPT
        LABELS[$((BOOTP - 1))]="EFI"
        FLAG=esp
    else
        # ... BIOS boot partition with GPT
        LABELS[$((BOOTP - 1))]="BIOS"
        FLAG=bios_grub
    fi

    START=0%
    for i in "${!PARTITIONS[@]}"; do
        info " partition $((i + 1))"  
        parted -a optimal "$OUTPUT" --script mkpart "${LABELS[$i]}" $START ${PARTITIONS[$i]}MiB 2>> "$LOG" ||
            die "''parted'' failed."

        if [[ $((i + 1)) -eq $BOOTP ]]; then
            info "  set $FLAG on"
            parted "$OUTPUT" --script set $BOOTP $FLAG on 2>> "$LOG" ||
                die "''parted'' failed."
        fi

        START=${PARTITIONS[$i]}MiB
    done
else
    info "Making BIOS partition table ..."
    parted "$OUTPUT" --script mklabel msdos
 # ... BIOS with MBR

 # ... UEFI with MBR
fi






#  # cleanup ...
# Err () {
#     rm "$OUTPUT"
#     die $1
# }

# parted --script "$OUTPUT" mklabel msdos \
#     mkpart p ext2 1 $BOOTPARTITION set 1 boot on &>> "$LOG" ||
#     Err "''parted'' failed."

# dev_loop=$(sudo losetup --partscan --find --show "$OUTPUT" 2>> "$LOG") || 
#     Err "''losetup'' failed."

# info "Formatting primary partition (${dev_loop}p1) ..."
# sudo mkfs -t ext2 ${dev_loop}p1 &>> "$LOG"
# if [[ $? -ne 0 ]]; then
#     sudo losetup --detach $dev_loop
#     Err "''mkfs'' failed."
# fi

# tmp_dir=$(mktemp -d -t disk-XXXX)
# if [[ $? -ne 0 ]]; then
#     sudo losetup --detach $dev_loop
#     Err "''mktemp'' failed."
# fi

# sudo mount ${dev_loop}p1 $tmp_dir &>> "$LOG"
# if [[ $? -ne 0 ]]; then
#     rm -rf $tmp_dir # ... remove temp directory.

#     sudo losetup --detach $dev_loop
#     Err "''mount'' failed."
# fi

# sudo mkdir -p $tmp_dir/$BOOT/grub
# sudo cp "$KERNEL" $tmp_dir/$BOOT

# sudo tee $tmp_dir/$BOOT/grub/$GRUBCONFIG >/dev/null <<EOF
#     set timeout=10
#     set default=0

#     menuentry "cyanea OS" {
#         multiboot2 /$BOOT/$(basename "$KERNEL")
#         boot
#     }
# EOF

# echo "(hd0) $dev_loop" > .device.map

# info "Installing GRUB..."
# sudo grub-install --no-floppy --grub-mkdevicemap=.device.map            \
#     --modules="biosdisk part_msdos ext2 configfile normal multiboot"    \
#     --boot-directory=$tmp_dir/${BOOT} --target=i386-pc $dev_loop &>> "$LOG"

# sleep 1 # ... make sure we are done.

# sudo umount $tmp_dir
# rm -rf $tmp_dir
# rm .device.map
 
# sudo losetup --detach $dev_loop
