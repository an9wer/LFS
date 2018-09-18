#!/usr/bin/env bash

PWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

export BLOCK
export LFS=/mnt
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export SOURCES_DIR=${PWD}/sources
export INSTALLATIONS_DIR=${PWD}/installations

check_root() {
  (( $(id -u) == 0 )) || { echo "Only root can execute this script!"; exit 0; }
} 
choice_block() {
  lsblk -p
  read -p "What is your choice? (e.g. /dev/sdX): " BLOCK
}

format_block() {
  read -p "We will format '${BLOCK}', are you sure? (y/n): " SURE
  [[ ${SURE} == 'y' ]] || exit 0

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
  sync
}

umount_block() {
  sync
  umount -v ${LFS}/boot
  umount -v ${LFS}
}

run() {
  set -e
  check_root || exit 1
  choice_block || exit 2
  format_block || exit 3
  mount_block || exit 4
  copy_packages || exit 5

  . ${INSTALLATIONS_DIR}/binutils.sh || exit 6
  . ${INSTALLATIONS_DIR}/gcc.sh || exit 7
  . ${INSTALLATIONS_DIR}/linux.sh || exit 8
  . ${INSTALLATIONS_DIR}/glibc.sh || exit 9
  #. ${INSTALLATIONS_DIR}/libstdc++.sh || exit 10
  #. ${INSTALLATIONS_DIR}/binutils2.sh || exit 11

  umount_block || exit 99
  set +e

  exit 0
}

run_step() {
  set -e
  check_root || exit 1
  cat <<EOF
step  1: binutils
step  2: gcc
step  3: linux
step  4: glibc
step  5: libstdc++
step  6: binutils2
EOF

  read -p "Which step do you want to execute? " STEP
  choice_block || exit 2
  mount_block || exit 4
  case ${STEP} in
    1) . ${INSTALLATIONS_DIR}/binutils.sh || exit 6 ;;
    2) . ${INSTALLATIONS_DIR}/gcc.sh || exit 7 ;;
    3) . ${INSTALLATIONS_DIR}/linux.sh || exit 8 ;;
    4) . ${INSTALLATIONS_DIR}/glibc.sh || exit 9 ;;
    5) . ${INSTALLATIONS_DIR}/libstdc++.sh || exit 10 ;;
    6) . ${INSTALLATIONS_DIR}/binutils2.sh || exit 11 ;;
    *) echo "unknown step";;
  esac
  umount_block || exit 99
  set +e

  exit 0
}

usage() {
  cat <<EOF
1. without options, it'll execute all steps.
2. with '-s' option, it'll execute the step you select.
EOF

  exit 0
}

while getopts ":s" option; do
  [[ ${option} == s ]] && run_step || usage
done
run
