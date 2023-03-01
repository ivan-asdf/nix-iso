#!/bin/sh

echo "--------------------------------------------------------------------------------"
echo "Detected the following devices:"
sudo lsblk -e7 -o name,size,model,serial
# echo "Write name of device to install nixOS (WARNING!! WILL FORMAT DEVICE!!): "
printf "\n"

i=1
#for device in $(sudo fdisk -l | grep "^Disk /dev" | awk "{print \$2}" | sed "s/://"); do
for device in $(lsblk -o path,type | grep disk | awk "{print \$1}"); do
    echo "[$i] $device"
    i=$((i+1))
    DEVICES[$i]=$device
done

echo
read -p "Which device do you wish to install on? " DEVICE

DEV=${DEVICES[$(($DEVICE+1))]}
echo $DEV

ram_kB=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')


