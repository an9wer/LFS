# Q: what is the "--target" option of configure?
# thx: https://airs.com/ian/configure/configure_5.html

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
make -j4

[[ $(uname -m) == x86_64 ]] && {
  mkdir -pv ${LFS}/tools/lib
  ln -vsf ./lib ${LFS}/tools/lib64
}

make -j4 install

unset BINUTILS_DIR
cd ${LFS}/sources
