#/usr/bin/env bash

export LFS=/mnt
export BLK

check_root() {
  (( $(id -u) == 0 )) || { echo "Only root can execute this script!"; exit 0; }
}

choice_blk() {
  lsblk -p
  read -p "What is your choice? (e.g. /dev/sdX): " BLK
  read -p "We will format '${BLK}', are you sure? (y/n): " sure
  [[ $sure == 'y' ]] || exit 0
}

format_blk() {
  # thx: https://superuser.com/a/984637
  # use sed to remove comment which starts with '#'
  sed -e 's/\(\s*#.*\)//' <<EOF | sfdisk ${BLK}
label: gpt
${BLK}1: size=512M, type=1  # EFI System
${BLK}2: size=1G, type=19   # Linux swap
${BLK}3: type=20            # Linux filesystem
EOF

  mkfs.fat -F32 ${BLK}1
  mkswap ${BLK}2
  mkfs.ext4 ${BLK}3
}

mount_blk() {
  mkdir -pv ${LFS}
  mount -v ${BLK}3 ${LFS}
  mkdir -pv ${LFS}/boot
  mount -v ${BLK}1 ${LFS}/boot
}

download_packages() {
  mkdir -pv ${LFS}/sources
  chmod -v a+wt ${LFS}/sources
  cp -vf sources/* ${LFS}/sources
}

install_preparations() {
  mkdir -pv ${LFS}/tools
}

install_binutils() {
  # Q: what is the "--target" option of configure?
  # thx: https://airs.com/ian/configure/configure_5.html

  cd ${LFS}/sources
  tar -Jxf binutils-2.31.1.tar.xz
  mkdir -v binutils-2.31.1/build
  cd binutils-2.31.1/build

  ../configure --prefix=${LFS}/tools \
               --with-sysroot=${LFS} \
               --with-lib-path=${LFS}/tools/lib \
               --disable-nls \
               --disable-werror
  make -j4
  cd ${LFS}/sources
}

umount_blk() {
  sync
  umount -v ${LFS}/boot
  umount -v ${LFS}
}

run() {
  check_root
  choice_blk
  format_blk
  mount_blk
  download_packages
  install_preparations
  install_binutils
  umount_blk
}

run
