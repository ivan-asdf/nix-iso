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
SWAP_SIZE=$((ram_kB + 2* 1000 * 1000)) # ram size + 2GB

( echo g # new gpt partition table echo n # new partition

  echo n # new partition
  echo   # default first partition
  echo   # default start sector
  echo +512M # 512MB efi partition

  echo n # new partition
  echo   # default second partition
  echo   # default start sector
  echo +${SWAP_SIZE}kB # swap parititon size

  echo n # new partition
  echo   # default second partition
  echo   # default start sector
  echo   # default end sector till end of disk (this is root parition)

  echo p # print layout

  echo w # write changes
) | sudo fdisk ${DEV}
