#!/bin/bash

set -xe
BDRIVE="$1"
CDROM="$2"
shift

qemu-system-x86_64 -enable-kvm -boot menu=on \
  -cpu host \
	-m 1024 \
	-net nic,model=virtio \
	-net user,hostfwd=tcp::10022-:22 \
	-drive format=qcow2,file="$BDRIVE",media=disk,if=virtio \
	-cdrom "$CDROM" \
  -vga virtio \
  -bios /usr/share/OVMF/x64/OVMF.fd 
"$@"

