# These and other macros are documented in ../droid-configs-device/droid-configs.inc
# Feel free to cleanup this file by removing comments, once you have memorised them ;)

%define device comet
%define vendor google

%define vendor_pretty Google
%define device_pretty Pixel 9 Pro Fold

%define android_version_major 16

# Community HW adaptations need this
%define community_adaptation 1

# No device reset
Provides: jolla-settings-system-reset

Requires: droid-system-%{device}

Requires: libgbinder-tools

# Device-specific ofono configuration
Provides: ofono-configs
Obsoletes: ofono-configs-mer
Obsoletes: ofono-configs-binder

# Pixel ratio 1.0 was originally jolla phone with 245ppi, and the devices
# should roughly have their ppi compared to that. Large displays can use
# bigger ratio if seen fit. Values are with 0.25 increments.
%define pixel_ratio 1.75

%include droid-configs-device/droid-configs.inc
%include patterns/patterns-sailfish-device-adaptation-comet.inc
%include patterns/patterns-sailfish-device-configuration-comet.inc

# IMPORTANT if you want to comment out any macros in your .spec, delete the %
# sign, otherwise they will remain defined! E.g.:
#define some_macro "I'll not be defined because I don't have % in front"

