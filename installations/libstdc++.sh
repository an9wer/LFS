cd ${LFS}/sources
LIBSTD_DIR=gcc/libstdc++-v3

mkdir -pv ${LIBSTD_DIR}/build && cd ${LIBSTD_DIR}/build
../configure \
  --host=${LFS_TGT} \
  --prefix=${LFS}/tools \
  --disable-multilib \
  --disable-nls \
  --disable-libstdxx-threads \
  --disable-libstdcxx-pch \
  --with-gxx-include-dir=${LFS}/tools/${LFS_TGT}/include/c++/8.2.0

make -j4 && make -j4 install

unset LIBSTD_DIR
cd ${LFS}/sources
