cd ${LFS}/sources
LINUX_DIR=linux

mkdir -pv ${LINUX_DIR} && \
  tar -xf linux-4.18.5.tar.xz -C ${LINUX_DIR} --strip-components=1

cd ${LINUX_DIR}
make -j4 mrproper
make -j4 INSTALL_HDR_PATH=dest headers_install
cp -rp dest/include/* ${LFS}/tools/include

unset LINUX_DIR
cd ${LFS}/sources
