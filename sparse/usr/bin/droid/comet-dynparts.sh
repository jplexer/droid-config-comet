#!/bin/sh
# comet: map Android dynamic partitions from super, mount them, and set up
# what droid-hal-init's services expect (SELinux policy, cgroup v1 paths).
exec >> /var/log/comet-dynparts.log 2>&1
set -x

### dynamic partitions
SLOT=$(sed -n 's/^androidboot.slot_suffix = "\(.*\)"/\1/p' /proc/bootconfig 2>/dev/null)
[ -n "$SLOT" ] || SLOT=$(sed -n 's/.*androidboot.slot_suffix=\([^ ]*\).*/\1/p' /proc/cmdline)
SUPER=$(ls /dev/block/platform/*/by-name/super /dev/block/by-name/super 2>/dev/null | head -1)
if [ ! -e "/dev/mapper/dynpart-system$SLOT" ]; then
    dmsetup create --concise "$(parse-android-dynparts "$SUPER")"
fi
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

### SELinux: service managers need selinuxfs + a loaded policy.
### Kernel starts permissive (SELINUX_DEVELOP, no enforcing=1), so nothing is blocked.
mountpoint -q /sys/fs/selinux || mount -t selinuxfs selinuxfs /sys/fs/selinux
if [ "$(cat /sys/fs/selinux/enforce)" = "0" ] && [ -z "$(ls /sys/fs/selinux/class 2>/dev/null)" ]; then
    # must be a single write(), hence dd with a big block size
    dd if=/vendor/etc/selinux/precompiled_sepolicy of=/sys/fs/selinux/load bs=4M
fi

### cgroups: Android expects v1 hierarchies at the paths in cgroups.json,
### systemd already mounted them under /sys/fs/cgroup -> bind them over.
bindcg() {   # bindcg <systemd hierarchy> <android path> <groups...>
    [ -d "/sys/fs/cgroup/$1" ] || return 0
    mkdir -p "$2"
    mountpoint -q "$2" || mount --bind "/sys/fs/cgroup/$1" "$2"
    d=$2; shift 2
    for g in "$@"; do
        mkdir -p "$d/$g"
        # only Android's groups belong to system; systemd's own slices must stay
        # root-owned or the user manager can't take over its delegated cgroup
        chown -R 1000:1000 "$d/$g"
        find "$d/$g" \( -name tasks -o -name cgroup.procs \) -exec chmod 0664 {} +
    done
}
bindcg cpuset      /dev/cpuset foreground background system-background top-app restricted camera-daemon
for g in foreground background system-background top-app restricted camera-daemon; do
    cat /dev/cpuset/cpuset.cpus > /dev/cpuset/$g/cpuset.cpus
    cat /dev/cpuset/cpuset.mems > /dev/cpuset/$g/cpuset.mems
done
bindcg cpu,cpuacct /dev/cpuctl background foreground top-app system system-background rt dex2oat camera-daemon
bindcg blkio       /dev/blkio  background
for d in /dev/cpuset /dev/cpuctl /dev/blkio; do
    [ -d "$d" ] || continue
    chown -R 1000:1000 "$d"                       # system:system
    find "$d" \( -name tasks -o -name cgroup.procs \) -exec chmod 0664 {} +
done

### debug output
grep -E " /system| /vendor| /product| /system_ext|cgroup|selinux" /proc/mounts
ls /sys/fs/selinux/class | wc -l
