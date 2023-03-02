set -o errexit
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

sudo lsblk -e7 -o name,size,model,serial $DEV
echo "ARE YOU SURE YOU WANT TO FORMAT THIS DEVICE? ALL DATA WILL BE LOST!!!"
read -p 'Type "confirm" to procede: ' ANSWER

if [ "$ANSWER" = "confirm" ]; then
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
  
  echo t # set type
  echo 1 # first partition
  echo 1 # EFI System
  
  echo t # set type
  echo 2 # second partition
  echo 19 # Linux swap
  
  echo t # set type
  echo 3 # third partition
  echo 20 # Linux Filesystem

  echo p # print layout

  echo w # write changes
) | sudo fdisk ${DEV}
else
  echo "cancelled."
  exit
fi

BOOT_PART=${DEV}1 #/dev/sdX1
SWAP_PART=${DEV}2 #/dev/sdX2
ROOT_PART=${DEV}3 #/dev/sdX3

echo "making filesystem on ${BOOT_PART}..."
sudo mkfs.fat -F 32 -n boot $BOOT_PART
echo "making filesystem on ${SWAP_PART}..."
sudo mkswap -L swap $SWAP_PART
echo "making filesystem on ${ROOT_PART}..."
sudo mkfs.ext4 -L nixos $ROOT_PART

echo "mountings filesystems..."
sudo mount $ROOT_PART /mnt
sudo mkdir /mnt/boot
sudo mount $BOOT_PART /mnt/boot
sudo swapon $SWAP_PART

STANDART_NIX_CONFIG_DIR=/mnt/etc/nixos
sudo mkdir -p $STANDART_NIX_CONFIG_DIR
echo "copying ${NIX_CONFIG_PATH} to ${STANDART_NIX_CONFIG_DIR}"
sudo cp -r ${NIX_CONFIG_DIR}/system/* ${STANDART_NIX_CONFIG_DIR}

sudo nixos-install

sudo cp -r ${NIX_CONFIG_DIR} /mnt/home/ivan/.nix-config

# Install a home manager bootstrap script along with config from iso
BOOTSTRAP_SCRIPT=/mnt/home/ivan/bootstrap_hm.sh
echo '
set -o errexit

nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

SCRIPT_DIR=$(dirname "$0")

home-manager switch -f ${SCRIPT_DIR}/.nix-config/home/home.nix

# Delete iso nix-config from home directory leaving with fresh-installed OS
sudo rm -rf ${SCRIPT_DIR}/.nix-config
sudo rm ${SCRIPT_DIR}/bootstrap_hm.sh' >  $BOOTSTRAP_SCRIPT

sudo chmod a+x $BOOTSTRAP_SCRIPT
