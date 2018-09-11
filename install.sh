#!/usr/bin/env bash

PWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

export BLOCK
export LFS=/mnt
export SOURCES_DIR=${PWD}/sources
export INSTALLATIONS_DIR=${PWD}/installations

check_root() {
  (( $(id -u) == 0 )) || { echo "Only root can execute this script!"; exit 0; }
}

choice_block() {
  lsblk -p
  read -p "What is your choice? (e.g. /dev/sdX): " BLOCK
  read -p "We will format '${BLOCK}', are you sure? (y/n): " sure
  [[ $sure == 'y' ]] || exit 0
}

format_block() {
  # thx: https://superuser.com/a/984637
  # use sed to remove comment which starts with '#'
  sed -e 's/\(\s*#.*\)//' <<EOF | sfdisk ${BLOCK}
label: gpt
${BLOCK}1: size=512M, type=1  # EFI System
${BLOCK}2: size=1G, type=19   # Linux swap
${BLOCK}3: type=20            # Linux filesystem
EOF

  mkfs.fat -F32 ${BLOCK}1
  mkswap ${BLOCK}2
  mkfs.ext4 ${BLOCK}3
}

mount_block() {
  mkdir -pv ${LFS} && mount -v ${BLOCK}3 ${LFS}
  mkdir -pv ${LFS}/boot && mount -v ${BLOCK}1 ${LFS}/boot

  mkdir -pv ${LFS}/sources && chmod -v a+wt ${LFS}/sources
  mkdir -pv ${LFS}/tools
}

copy_packages() {
  cp -vf ${SOURCES_DIR}/* ${LFS}/sources
}

umount_block() {
  sync
  umount -v ${LFS}/boot
  umount -v ${LFS}
}

run() {
  check_root || exit 1
  choice_block || exit 2
  format_block || exit 3
  mount_block || exit 4
  copy_packages || exit 5

  . ${INSTALLATIONS_DIR}/binutils.sh || exit 6
  . ${INSTALLATIONS_DIR}/gcc.sh || exit 7
  . ${INSTALLATIONS_DIR}/linux.sh || exit 8

  umount_block || exit 99
}

run
