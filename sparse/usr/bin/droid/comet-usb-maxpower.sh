#!/bin/sh
# usb-moded uses gadget config c.1, which configfs creates with MaxPower=2.
# The kernel announces that as the configured draw, so Pixel's charger stays
# at the 100 mA SDP limit on PC ports. Android sets 900 (0x384) on its own
# config b.1 (init.zumapro.usb.rc); do the same for c.1 before usb-moded binds.
G=/sys/kernel/config/usb_gadget/g1
for i in $(seq 1 30); do [ -d $G/configs ] && break; sleep 1; done
[ -d $G/configs ] || exit 0
mkdir -p $G/configs/c.1
echo 900 > $G/configs/c.1/MaxPower
