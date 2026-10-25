#!/bin/sh
# droid-hal-init runs linkerconfig before apexd has activated all APEXes and
# ends up with an empty /linkerconfig/ld.config.txt (no sphal namespace ->
# mapper.pixel.so not found). Regenerate once apexd is done.
exec >> /var/log/comet-linkerconfig.log 2>&1
for i in $(seq 1 60); do
    s=$(getprop apexd.status 2>/dev/null)
    [ "$s" = "activated" ] || [ "$s" = "ready" ] && break
    sleep 1
done
echo "$(date) apexd.status=$s after $i s"
mkdir -p /linkerconfig
/usr/libexec/droid-hybris/system/bin/linkerconfig --target /linkerconfig
ls -la /linkerconfig/ld.config.txt
