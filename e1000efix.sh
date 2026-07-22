#!/usr/bin/env bash
set -eou pipefail

for dev in /sys/class/net/*; do
    if [ -e "$dev/device/driver" ] && [ "$(basename "$(readlink -f "$dev/device/driver")")" = "e1000e" ]; then
        NIC=$(basename "$dev")
        echo "Applying settings to $NIC..."
        ethtool -A "$NIC" rx off tx off
        ethtool -K "$NIC" tso off gso off gro off lro off
        # Helps keep it alive after re-plugs
        echo "on" > /sys/class/net/"${NIC}"/device/power/control
    fi
done

#############################
##  To make this permanent, add/update the following in /etc/network/interfaces:
##  todo: Add to pve-init or pve-base-config after testing
##  iface nic0 inet manual
##      offload-rx off
##      offload-tx off
#############################