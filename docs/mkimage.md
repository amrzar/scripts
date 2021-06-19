### NAME

mkimage -- generate a disk image using GRUB

### SYNOPSIS

**mkimage** --kernel file --size size --bootable-partition size [--output path] [--log file]

### DESCRIPTION

Create a disk image using a multiboot2 compatible kernel ELF binary. It uses MBR disk (msdos) with a single primary partition formatted as *ext2* with a bootable attribute set.
GRUB will be installed in the 'boot' directory in this partition. The remaining part of the disk remains unused and can be used to allocated other partitions.


also see [GPT](https://en.wikipedia.org/wiki/GUID_Partition_Table "GPT"), [MBR](https://en.wikipedia.org/wiki/Master_boot_record "MBR"), [EFI system partition (ESP)](https://en.wikipedia.org/wiki/EFI_system_partition "EFI system partition (ESP)"), and [BIOS boot partition](https://en.wikipedia.org/wiki/BIOS_boot_partition "BIOS boot partition")


**--kernel**\
path to (multiboot2 compatible) kernel ELF binary file

**--size**\
size of the disk image in megabytes

**--bootable-partition**\
size of the bootable partition used to install GRUB

**--output**\
target directory to store the disk image

**--log**\
log file
