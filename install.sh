#/usr/bin/env bash

(( $(id -u) == 0 )) || { echo "Only root can execute this script!"; exit 0; }

lsblk -p
read -p "What is your choice? (e.g. /dev/sdX): " blk
read -p "We will format '$blk', are you sure? (y/n): " sure

[[ $sure == 'y' ]] || exit 0

# thx: https://superuser.com/a/984637
# use sed to remove comment which starts with '#'
sed -e 's/\(\s*#.*\)//' <<EOF | sfdisk -n $blk
label: gpt
${blk}1: size=512M, type=1  # EFI System
${blk}2: size=1G, type=19   # Linux swap
${blk}3: type=20            # Linux filesystem
EOF
