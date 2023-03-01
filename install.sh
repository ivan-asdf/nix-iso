#!/bin/sh

echo "--------------------------------------------------------------------------------"
echo "Detected the following devices:"
sudo lsblk -e7 -o name,size,model,serial
printf "\n"

i=1
for device in $(lsblk -o path,type | grep disk | awk "{print \$1}"); do
    echo "[$i] $device"
    i=$((i+1))
    DEVICES[$i]=$device
done

echo
read -p "Which device do you wish to install on? " DEVICE

DEV=${DEVICES[$(($DEVICE+1))]}

RAM_SIZE=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}') # in kB
SWAP_SIZE=$((RAM_SIZE + 2 * 1024 * 1024)) # ram size + 2GB

( echo g # new gpt partition table

  echo n # new partition
  echo   # default first partition
  echo   # default start sector
  echo +512M # 512MB efi partition

  echo n # new partition
  echo   # default second partition
  echo   # default start sector
  echo +${SWAP_SIZE}kB # swap parititon size

  echo n # new partition
  echo   # default third partition
  echo   # default start sector
  echo   # default end sector till end of disk (this is root parition)

  echo p # print layout

  echo w # write changes
) | sudo fdisk ${DEV}

BOOT_PART=${DEV}1 #/dev/sdX1
SWAP_PART=${DEV}2 #/dev/sdX2
ROOT_PART=${DEV}3 #/dev/sdX3

echo "making filesystem on ${BOOT_PART}..."
mkfs.fat -F 32 -n boot $BOOT_PART
echo "making filesystem on ${SWAP_PART}..."
mkswap -L swap $SWAP_PART
echo "making filesystem on ${ROOT_PART}..."
mkfs.ext4 -L nixos $ROOT_PART

echo "mountings filesystems..."
mount $ROOT_PART /mnt
mount $BOOT_PART /mnt/boot
swapon $SWAP_PART
