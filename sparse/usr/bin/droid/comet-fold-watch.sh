#!/bin/sh
# jolla-home/Silica lay out for the screen size at startup only (Silica's
# Screen is read-only and doesn't follow QScreen changes), so after a
# fold/unfold restart the shell; the hwcomposer plugin then starts on the
# right display. Open apps are closed with it.
F=/sys/devices/platform/hall_sensor/state
last=$(cat "$F")
while sleep 0.3; do
    s=$(cat "$F") || continue
    [ "$s" = "$last" ] && continue
    sleep 0.5            # let the hinge settle; ignore quick bounces
    [ "$(cat "$F")" = "$s" ] || continue
    last=$s
    systemctl --user restart lipstick
done
