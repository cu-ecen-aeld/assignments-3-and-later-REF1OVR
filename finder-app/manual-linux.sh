#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]; then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
	#Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
	cd linux-stable
	echo "Checking out version ${KERNEL_VERSION}"
	git checkout ${KERNEL_VERSION}


	# TODO: Add your kernel build steps here:
	echo "------------ Building the Kernel ------------"
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper			# Clean make autogenerated files
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig			# Configure for virtual target
	make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all		# Build image using all available processors
	#make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules			# Build modules
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs				# Build device tree
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]; then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
	sudo rm  -rf ${OUTDIR}/rootfs
fi


# TODO: Create necessary base directories:
echo "--------- Creating Base Directories ---------"
mkdir ${OUTDIR}/rootfs && cd ${OUTDIR}/rootfs
mkdir -pv {bin,sbin,dev,etc,home,lib,lib64,proc,sys,temp,usr/{bin,sbin,lib},var/log}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]; then
	git clone git://busybox.net/busybox.git
	cd busybox
	git checkout ${BUSYBOX_VERSION}
	# TODO:  Configure busybox:
	echo "------------ Configuring BusyBox ------------"
	make distclean
	make defconfig
else
	cd busybox
fi


# TODO: Make and install busybox:
echo "------ Building and Installing BusyBox ------"
make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
cd ${OUTDIR}/rootfs
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"


# TODO: Add library dependencies to rootfs:
echo "-------- Adding Library Dependencies --------"
CC_PATH=$(${CROSS_COMPILE}gcc -print-sysroot)
cp -v ${CC_PATH}/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/
cp -v ${CC_PATH}/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/
cp -v ${CC_PATH}/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/
cp -v ${CC_PATH}/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/


# TODO: Make device nodes:
echo "----------- Creating Device Nodes -----------"
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/tty c 5 0
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/zero c 1 5
sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/random c 1 8
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/urandom c 1 9


# TODO: Clean and build the writer utility:
echo "-------- Clean and Build Writer Util --------"
cd ${FINDER_APP_DIR}
make CROSS_COMPILE=${CROSS_COMPILE} clean
make CROSS_COMPILE=${CROSS_COMPILE} all


# TODO: Copy the finder related scripts and executables to the /home directory on the target rootfs:
echo "---------- Copying Finder to rootfs ----------"
cp -v writer ${OUTDIR}/rootfs/home/
cp -v finder.sh ${OUTDIR}/rootfs/home/
cp -v finder-test.sh ${OUTDIR}/rootfs/home/
cp -v autorun-qemu.sh ${OUTDIR}/rootfs/home/
cp -v start-qemu-app.sh ${OUTDIR}/rootfs/home/
cp -v start-qemu-terminal.sh ${OUTDIR}/rootfs/home/
mkdir -p ${OUTDIR}/rootfs/home/conf
cp -v ./conf/assignment.txt ${OUTDIR}/rootfs/home/conf/
cp -v ./conf/username.txt ${OUTDIR}/rootfs/home/conf/


# TODO: Chown the root directory:
echo "---------- Chown the root directory ----------"
sudo chown -R root:root ${OUTDIR}/rootfs


# TODO: Create initramfs.cpio.gz:
echo "------------- Creating initramfs -------------"
sudo apt-get install -y cpio
cd "${OUTDIR}/rootfs"
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio
