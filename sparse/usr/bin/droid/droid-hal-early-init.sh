#!/bin/sh
# Map Android dynamic partitions from super and mount them for droid-hal-init
exec >> /var/log/droid-early-init.log 2>&1
set -x

SLOT=$(sed -n 's/^androidboot.slot_suffix = "\(.*\)"/\1/p' /proc/bootconfig 2>/dev/null)
[ -n "$SLOT" ] || SLOT=$(sed -n 's/.*androidboot.slot_suffix=\([^ ]*\).*/\1/p' /proc/cmdline)
SUPER=$(ls /dev/block/platform/*/by-name/super /dev/block/by-name/super 2>/dev/null | head -1)

if [ ! -e "/dev/mapper/dynpart-system$SLOT" ]; then
    dmsetup create --concise "$(parse-android-dynparts "$SUPER")"
fi

# Android partitions: use the slot that actually has them (vendor is the marker)
OTHER=$([ "$SLOT" = "_a" ] && echo _b || echo _a)
if [ -e "/dev/mapper/dynpart-vendor$SLOT" ]; then ASLOT=$SLOT; else ASLOT=$OTHER; fi
echo "boot slot $SLOT, android partitions from $ASLOT"

mnt() {   # mnt <name> <mountpoint> <slot>
    [ -e "/dev/mapper/dynpart-$1$3" ] || return 0
    mkdir -p "$2"
    mountpoint -q "$2" || mount -o ro "/dev/mapper/dynpart-$1$3" "$2"
}

mnt system      /system_root $ASLOT
mkdir -p /system
mountpoint -q /system || mount --bind /system_root/system /system
mnt vendor      /vendor      $ASLOT
mnt system_ext  /system_ext  $ASLOT
mnt product     /product     $ASLOT
mnt vendor_dlkm /vendor_dlkm $SLOT
mnt system_dlkm /system_dlkm $SLOT

ls -la /system/bin/bootstrap/ 2>&1
grep -E " /system| /vendor| /product| /system_ext" /proc/mounts
ls /dev/mapper/
