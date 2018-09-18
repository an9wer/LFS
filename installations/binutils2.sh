cd ${LFS}/sources
BINUTILS_DIR=binutils

mkdir -pv ${BINUTILS_DIR}/build2 && cd ${BINUTILS_DIR}/build2
CC=${LFS}/tools/bin/${LFS_TGT}-gcc \
AR=${LFS}/tools/bin/${LFS_TGT}-ar \
RANLIB=${LFS}/tools/bin/${LFS_TGT}-ranlib \
../configure \
  --prefix=${LFS}/tools \
  --with-sysroot=${LFS} \
  --with-lib-path=${LFS}/tools/lib \
  --target=${LFS_TGT} \
  --disable-nls \
  --disable-werror

make -j4 && make -j4 install

make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -pv ld/ld-new ${LFS}/tools/bin

unset BINUTILS_DIR
cd ${LFS}/sources
