#!/bin/sh
# bcmdhd registers wlan0 with the Broadcom default MAC (00:90:4c:...) and only
# applies the real MAC from the chip when the firmware is first brought up.
# ConnMan keys its device and saved networks on the MAC it sees first, so
# saved networks get "forgotten" and show up twice. Bring the firmware up
# once, wait for the real MAC, then let ConnMan pick up the device again.
exec >> /var/log/comet-wifi-mac.log 2>&1
date
for i in $(seq 1 120); do [ -e /sys/class/net/wlan0/address ] && break; sleep 1; done
mac() { cat /sys/class/net/wlan0/address 2>/dev/null; }
link() {
    if command -v ip >/dev/null 2>&1; then ip link set wlan0 "$1"
    else /bin/busybox-static ifconfig wlan0 "$1"; fi
}
echo "wlan0 at start: $(mac)"
case "$(mac)" in 00:90:4c:*) ;; *) echo "real MAC already set"; exit 0 ;; esac
link up
for i in $(seq 1 30); do case "$(mac)" in 00:90:4c:*) sleep 1 ;; *) break ;; esac; done
link down
echo "wlan0 now: $(mac)"
systemctl restart connman.service
