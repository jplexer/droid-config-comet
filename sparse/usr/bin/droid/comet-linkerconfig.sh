#!/bin/sh
# Post-droid-hal-init fixups that droid-hal-init's own triggers don't manage:
#  1. linkerconfig: droid-hal-init runs it before apexd has activated all
#     APEXes and ends up with an empty /linkerconfig/ld.config.txt (no sphal
#     namespace -> mapper.pixel.so not found).
#  2. insmod_sh_comet: init.comet.rc starts it "on early-boot" after
#     wait_for_prop vendor.common.modules.ready, which never fires under
#     droid-hal-init. It loads Wi-Fi, touch, speaker amps and haptics and
#     sets vendor.all.modules.ready.
exec >> /var/log/comet-linkerconfig.log 2>&1
waitprop() {   # waitprop <prop> <value...>; up to 60 s
    for i in $(seq 1 60); do
        v=$(getprop "$1" 2>/dev/null)
        for want in "$@"; do [ "$want" != "$1" ] && [ "$v" = "$want" ] && return 0; done
        sleep 1
    done
    return 1
}
date
waitprop apexd.status activated ready && echo "apexd.status=$(getprop apexd.status 2>/dev/null)" || echo "apexd timeout"
mkdir -p /linkerconfig
/usr/libexec/droid-hybris/system/bin/linkerconfig --target /linkerconfig
ls -la /linkerconfig/ld.config.txt

if waitprop vendor.common.modules.ready 1; then
    [ "$(getprop vendor.all.modules.ready 2>/dev/null)" = "1" ] || setprop ctl.start insmod_sh_comet
    waitprop vendor.all.modules.ready 1 && echo "device modules loaded" || echo "insmod_sh_comet timeout"
else
    echo "vendor.common.modules.ready timeout"
fi
grep -E "^N:" /proc/bus/input/devices

### Audio: the AoC firmware is booted by aocd (class late_start, which never
### starts here); the audio HAL needs the AoC sound card, so start it after.
setprop ctl.start aocd
for i in $(seq 1 30); do grep -q aoc /proc/asound/cards 2>/dev/null && break; sleep 1; done
cat /proc/asound/cards
setprop ctl.start vendor.audio-hal-aidl
echo "audio HAL: $(getprop init.svc.vendor.audio-hal-aidl 2>/dev/null)"
