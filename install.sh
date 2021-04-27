#!/bin/sh
echo -e "Hi. This is prototype script for seting up arch linux without DE.\n"
echo -n "To continue with installation press [Enter] or type [q] to exit > "; read enter

if [[ $enter = 'q' ]]; then echo "exiting..."; exit; fi

# setting timedate

echo -e "\n* setting time and date with \`timedate set-ntp true\`"
# timedate set-ntp true

echo -e "\nFormat partitions\n"

echo -e "For this part you have to manually create partitions."
echo -e "\nExample 1\n"
echo -e "/dev/sda1 - boot (200mb)"
echo -e "/dev/sda2 - swap (double your ram or same as ram)"
echo -e "/dev/sda3 - root (40-50gb)"
echo -e "/dev/sda4 - home (everything left)"
echo -e "\nor\n"
echo -e "\nExample\n"
echo -e "/dev/sda1 - boot (200mb)"
echo -e "/dev/sda2 - swap (double your ram or same as ram)"
echo -e "/dev/sda3 - root+home (everything left)"
echo -e "/dev/sda4 - left for something else (windows ...)"
echo -e "\nPress [Enter] to continue. After finishing type [fg] in terminal to continue this script."
read enter
set -m
suspend

disks="disks"
lsblk --json | jq -r '.blockdevices[].name' > disks
while read line; do
	devices+=( $line )
done < $disks
rm $disks

counter=0
echo -e "\nChoose formated disk from list"
for index in ${!devices[@]}; do
	echo "[$index] - ${devices[$index]}"
	indexes+=( $index )
done

choosedisk() {
	echo -n "> "; read disk
	for index in ${indexes[@]}; do
		if [[ $disk = $index ]]; then
			exists=true
		fi
	done
	if [[ ! $exists ]]; then
		choosedisk
	fi
}
choosedisk

diskname=${devices[$disk]}
echo -e "\nYou choose $diskname"

echo -e "\nEnter numbers of partitions in $diskname"
echo -n "boot > "; read boot
echo -n "swap > "; read swap
echo -n "root > "; read root
echo -n "home > "; read home

echo "Formating partitions"
yes | mkfs.ext4 /dev/$diskname$boot
yes | mkfs.ext4 /dev/$diskname$root
if [[ $home != $root ]]; then
	yes | mkfs.ext4 /dev/$diskname$home
fi
mkswap /dev/$diskname$swap ; swapon /dev/$diskname$swap

# mount partitions

echo -e "Mounting partitions"
echo 'Mounting root...'
mount /dev/$diskname$root /mnt
echo 'Mounting boot...'
mkdir /mnt/boot ; mount /dev/$diskname$boot /mnt/boot
if [[ $home != $root ]]; then
	echo 'Mounting home...'
	mkdir /mnt/home ; mount /dev/sda4 /mnt/home
fi

# configure mirrorlist
echo -e "Select prefered editor [default=vim]"
echo -e "[1] vim"
echo -e "[2] nano"
echo -n "> "; read input
case $input in
	1) editor=vim;;
	2) editor=nano;;
	"") editor=vim;;
esac
echo -e "Edit mirrorlsit to your preference, save and quit"
$editor /etc/pacman.d/mirrorlist

# install base packages

echo "Installing base packages"
pacstrap /mnt base base-devel linux linux-headers linux-firmware intel-ucode $editor

# generate fstab

echo 'Generating fstab...'
genfstab -U /mnt >> /mnt/etc/fstab

# move script for root

cp root-install.sh /mnt

# change root to /mnt

echo 'Changing root...'
arch-chroot /mnt
