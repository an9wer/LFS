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

[[ $(uname -m) == 'x86_64' ]] && {
    sed -e '/m64=/s/lib64/lib/' -i.orig ${GCC_DIR}/gcc/config/i386/t-linux64
}

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
