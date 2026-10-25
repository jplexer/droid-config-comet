#!/bin/sh
# MCE drives only panel0-backlight (inner display) through the lights HAL.
# While folded (outer display active), mirror its brightness onto
# panel1-backlight (outer display), scaled to that panel's range.
IN=/sys/class/backlight/panel0-backlight
OUT=/sys/class/backlight/panel1-backlight
HALL=/sys/devices/platform/hall_sensor/state
in_max=$(cat $IN/max_brightness)
out_max=$(cat $OUT/max_brightness)
last=""
while sleep 0.2; do
    [ "$(cat $HALL)" = "0" ] || { last=""; continue; }   # only while folded
    v=$(cat $IN/brightness) || continue
    [ "$v" = "$last" ] && continue
    last=$v
    echo $(( v * out_max / in_max )) > $OUT/brightness
done
