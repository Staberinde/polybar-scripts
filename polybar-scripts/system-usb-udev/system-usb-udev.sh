#!/bin/env bash

usb_print() {
    output=""
    counter=0
    # based on https://unix.stackexchange.com/questions/119759/removable-usb-stick-listed-as-non-removable-in-sys-block
    usbstorage=$(
        echo /sys/block/* | xargs -n1 readlink |
        sed -ne 's+^.*/usb[0-9].*/\([^/]*\)$+/sys/block/\1/device/uevent+p' |
        xargs grep -H ^DRIVER=sd |
        sed 's/device.uevent.*$/size/' |
        xargs grep -Hv '^0$' |
        cut -d / -f 4 |
        xargs -I{} echo '/dev/{}'
    )

    if [[ ${usbstorage} == "" ]]; then
        return 0
    fi

    devices="$(lsblk -Jplno NAME,TYPE,RM,SIZE,MOUNTPOINT,VENDOR ${usbstorage[*]})"

    for unmounted in $(echo "$devices" | jq -r '.blockdevices[] | select(.type == "part") | select(.mountpoint == null) | .name'); do
        unmounted=$(echo "$unmounted" | tr -d "[:digit:]")
        unmounted=$(echo "$devices" | jq -r '.blockdevices[] | select(.name == "'"$unmounted"'") | .vendor')
        unmounted=$(echo "$unmounted" | tr -d ' ')

        if [ $counter -eq 0 ]; then
            space=""
        else
            space="   "
        fi
        counter=$((counter + 1))

        output="$output$space#1 $unmounted"
    done

    for mounted in $(echo "$devices" | jq -r '.blockdevices[] | select(.type == "part") | select(.mountpoint != null) | .size'); do
        if [ $counter -eq 0 ]; then
            space=""
        else
            space="   "
        fi
        counter=$((counter + 1))

        output="$output$space#2 $mounted"
    done

    echo "$output"
}

usb_update() {
    pid=$(cat "$path_pid")

    if [ "$pid" != "" ]; then
        kill -10 "$pid"
    fi
}

path_pid="$HOME/.config/polybar/system-usb-udev.pid"

case "$1" in
    --update)
        usb_update
        ;;
    --mount)
        devices=$(lsblk -Jplno NAME,TYPE,RM,MOUNTPOINT)

        for mount in $(echo "$devices" | jq -r '.blockdevices[] | select(.type == "part") | select(.mountpoint == null) | .name'); do
            # udisksctl mount --no-user-interaction -b "$mount"

            # mountpoint=$(udisksctl mount --no-user-interaction -b $mount)
            # mountpoint=$(echo $mountpoint | cut -d " " -f 4 | tr -d ".")
            # terminal -e "bash -lc 'filemanager $mountpoint'"

            mountpoint=$(udisksctl mount --no-user-interaction -b "$mount")
            mountpoint=$(echo "$mountpoint" | cut -d " " -f 4 | tr -d ".")
            bash -lc 'mc $mountpoint' &
        done

        usb_update
        ;;
    --unmount)
        devices=$(lsblk -Jplno NAME,TYPE,RM,MOUNTPOINT)

        for unmount in $(echo "$devices" | jq -r '.blockdevices[] | select(.type == "part") | select(.mountpoint != null) | .name'); do
            udisksctl unmount --no-user-interaction -b "$unmount"
            udisksctl power-off --no-user-interaction -b "$unmount"
        done

        usb_update
        ;;
    *)
        echo $$ > $path_pid

        trap exit INT
        trap "echo" USR1

        while true; do
            usb_print

            sleep 60 &
            wait
        done
        ;;
esac
