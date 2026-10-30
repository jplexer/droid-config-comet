#!/bin/sh
# Restart the home screen when the phone is folded/unfolded: the hwcomposer
# QPA plugin switches displays, but Silica's Screen is static. Silica also
# only knows one cutout/corner set, so write the one of the display that is
# about to be used first.
HALL=/sys/devices/platform/hall_sensor/state

silica_for() {   # $1: hall state, 1 = unfolded (inner), 0 = folded (outer)
    if [ "$1" = "1" ]; then
        # inner: punch-hole top right (needs the StatusArea side cutout patch)
        CUT='[[1944, 0, 88, 90]]'
        COR='[[85, 85, 85], [-85, 85, 85], [85, -85, 85], [-85, -85, 85]]'
    else
        # outer: centred punch-hole
        CUT='[[494, 0, 92, 132]]'
        COR='[[115, 115, 115], [-115, 115, 115], [115, -115, 115], [-115, -115, 115]]'
    fi
    changed=0
    [ "$(dconf read /desktop/sailfish/silica/cutouts)" = "$CUT" ] || { dconf write /desktop/sailfish/silica/cutouts "$CUT"; changed=1; }
    [ "$(dconf read /desktop/sailfish/silica/rounded_corners)" = "$COR" ] || { dconf write /desktop/sailfish/silica/rounded_corners "$COR"; changed=1; }
    return $changed
}

last=$(cat $HALL)
# values for the display we booted on; restart once if they were wrong
silica_for "$last" || systemctl --user restart lipstick

while sleep 0.3; do
    s=$(cat $HALL)
    [ "$s" = "$last" ] && continue
    sleep 0.5                      # debounce half-open states
    s=$(cat $HALL)
    [ "$s" = "$last" ] && continue
    last=$s
    silica_for "$s"
    systemctl --user restart lipstick
done
