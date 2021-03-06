cd ${LFS}/sources
GLIBC_DIR=glibc

mkdir -pv ${GLIBC_DIR} && \
  tar -xf glibc-2.28.tar.xz -C ${GLIBC_DIR} --strip-components=1

mkdir -pv ${GLIBC_DIR}/build && cd ${GLIBC_DIR}/build

../configure \
  --prefix=${LFS}/tools \
  --host=${LFS_TGT} \
  --build=$(../scripts/config.guess) \
  --enable-kernel=3.2 \
  --with-headers=${LFS}/tools/include \
  libc_cv_forced_unwind=yes \
  libc_cv_c_cleanup=yes

make -j1 && make -j1 install

unset GLIBC_DIR
cd ${LFS}/sources
