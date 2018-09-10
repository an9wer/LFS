#!/usr/bin/env bash

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

# Q: what is the "--target" option of configure?
# thx: https://airs.com/ian/configure/configure_5.html

install_binutils() {

  cd ${LFS}/sources
  BINUTILS_DIR=binutils

  mkdir -pv ${BINUTILS_DIR} && \
    tar -xf binutils-2.31.1.tar.xz -C ${BINUTILS_DIR} --strip-components=1

  mkdir -pv ${BINUTILS_DIR}/build && cd ${BINUTILS_DIR}/build
  ../configure \
    --prefix=${LFS}/tools \
    --with-sysroot=${LFS} \
    --with-lib-path=${LFS}/tools/lib \
    --disable-nls \
    --disable-werror
  make -j4 && make -j4 install

  unset BINUTILS_DIR
  cd ${LFS}/sources
}

install_gcc() {
  cd ${LFS}/sources
  GCC_DIR=gcc
  MPFR_DIR=${GCC_DIR}/mpfr GMP_DIR=${GCC_DIR}/gmp MPC_DIR=${GCC_DIR}/mpc

  mkdir -pv ${GCC_DIR} && \
    tar -xf gcc-8.2.0.tar.xz -C ${GCC_DIR} --strip-components=1
  mkdir -pv ${MPFR_DIR} && \
    tar -xf mpfr-4.0.1.tar.xz -C ${MPFR_DIR} --strip-components=1
  mkdir -pv ${GMP_DIR} && \
    tar -xf gmp-6.1.2.tar.xz -C ${GMP_DIR} --strip-components=1
  mkdir -pv ${MPC_DIR} && \
    tar -xf mpc-1.1.0.tar.gz -C ${MPC_DIR} --strip-components=1

  for file in ${GCC_DIR}/gcc/config/{linux,i386/linux{,64}}.h; do
    cp -uv ${file}{,.orig}
    sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
        -e 's@/usr@/tools@g' $file.orig > $file
    echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
    touch ${file}.orig
  done

  case $(uname -m) in
    x86_64)
      sed -e '/m64=/s/lib64/lib/' \
          -i.orig ${GCC_DIR}/gcc/config/i386/t-linux64
       ;;
  esac

  mkdir -pv ${GCC_DIR}/build && cd ${GCC_DIR}/build
  ../configure \
    --prefix=${LFS}/tools \
    --with-glibc-version=2.11 \
    --with-sysroot=${LFS} \
    --with-newlib \
    --without-headers \
    --with-local-prefix=${LFS}/tools \
    --with-native-system-header-dir=${LFS}/tools/include \
    --disable-nls \
    --disable-shared \
    --disable-multilib \
    --disable-decimal-float \
    --disable-threads \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libmpx \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libvtv \
    --disable-libstdcxx \
    --enable-languages=c,c++

  make -j4 && make -j4 install

  unset GCC_DIR MPFR_DIR GMP_DIR MPC_DIR
  cd ${LFS}/sources
}

umount_blk() {
  sync
  umount -v ${LFS}/boot
  umount -v ${LFS}
}

run() {
  check_root || exit 1
  choice_blk || exit 2
  format_blk || exit 3
  mount_blk || exit 4
  download_packages || exit 5
  install_preparations || exit 6
  install_binutils || exit 7
  install_gcc || exit 8
  umount_blk || exit 99
}

run
