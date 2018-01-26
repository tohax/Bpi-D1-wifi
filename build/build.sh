#!/bin/bash
build_tools()
{
    echo Updating package list...
  #  $APT_GET update

    echo Installing tools...
    $APT_GET install lzop zip

    if [ `uname -m` == 'x86_64' ]; then
        echo Installing 32bit libraries...
        $APT_GET install --force-yes ia32-libs ia32-libs-multiarch liblzo2-2:i386 liblzma5:i386
    fi

    if [ ! -d $DEV_ROOT/compiler/arm-2009q3 ]; then
        $MKDIR $DEV_ROOT/compiler
        cd $DEV_ROOT/compiler
        echo Installing compiler...
        $TAR -jxf arm-2009q3-67-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2
    fi
}

clean_tools()
{
    echo Cleaning tools...
    $RM $DEV_ROOT/compiler/arm-2009q3
}

config_kernel()
{
    echo Configuring kernel...
    cd $DEV_ROOT/src/kernel
    $MKDIR $DEV_ROOT/output/kernel
    $MAKE O=$DEV_ROOT/output/kernel aimer39_ak3918_D1_defconfig
#    $MAKE O=$DEV_ROOT/output/kernel menuconfig
}

build_kernel()
{
    echo Building kernel...
    cd $DEV_ROOT/src/kernel
    $MKDIR $DEV_ROOT/output/kernel
    $MAKE O=$DEV_ROOT/output/kernel LOCALVERSION= -j$NCPU
    $CP $DEV_ROOT/output/kernel/arch/arm/boot/zImage $DEV_ROOT/output

    $MAKE O=$DEV_ROOT/output/kernel LOCALVERSION= -j$NCPU modules
    $MAKE O=$DEV_ROOT/output/kernel LOCALVERSION= -j$NCPU modules_prepare

#    cd /root/rtl8188eu
#    $MAKE -j$NCPU KSRC=$DEV_ROOT/output/kernel modules
#    $MAKE -j$NCPU KSRC=$DEV_ROOT/output/kernel strip
#    $CP 8188eu.ko $DEV_ROOT/src/librootfs/akaimer39lib/lib/modules/3.4.113
}

clean_kernel()
{
    echo Cleaning kernel...
    $RM $DEV_ROOT/output/kernel
    cd $DEV_ROOT/src/kernel
#    restore kernel/lib/libakaec.a and kernel/lib/libfha.a
#   git checkout lib

    cd $DEV_ROOT/src/kernel/drivers/net/wireless/rtlwifi
    $MAKE -j$NCPU KSRC=$DEV_ROOT/output/kernel clean
}

config_busybox()
{
    echo Configuring busybox...
    cd $DEV_ROOT/src/busybox
    $MKDIR $DEV_ROOT/output/busybox
    $MAKE O=$DEV_ROOT/output/busybox \
        ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- \
        lamobo_d1_defconfig

#    $MAKE O=$DEV_ROOT/output/busybox \
#        ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- menuconfig
}

build_busybox()
{
    echo Building busybox...
    cd $DEV_ROOT/src/busybox
    $MAKE O=$DEV_ROOT/output/busybox \
        ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -j$NCPU

    sudo $RM $DEV_ROOT/output/busybox/rootfs
    $RM $DEV_ROOT/output/busybox/rootfs.tar.gz
    $MAKE O=$DEV_ROOT/output/busybox \
        ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- CONFIG_PREFIX=rootfs -s install

    echo Merging with the prebuilt...
    cd $DEV_ROOT/output/busybox/rootfs
    $RM linuxrc
    sudo $TAR -zxpf $DEV_ROOT/build/rootfs_prebuilt.tgz
    sudo $MKDIR mnt
    sudo $MKDIR proc
    sudo $MKDIR sys
    sudo $MKDIR tmp
    sudo $MKDIR var
    $CHMOD 755 bin
    $CHMOD 755 etc
    $CHMOD 755 sbin
    $CHMOD 755 usr
    $CHMOD 755 usr/bin
    $CHMOD 755 usr/sbin
    cd ..

    find rootfs/ -exec sudo touch -h {} \;
    sudo $TAR -zcpf rootfs.tar.gz rootfs
    $CP rootfs.tar.gz $DEV_ROOT/src/librootfs/rootfs.tar.gz
}

clean_busybox()
{
    echo Cleaning busybox...
    sudo $RM $DEV_ROOT/output/busybox
    $RM $DEV_ROOT/src/librootfs/rootfs.tar.gz
}

build_rootfs()
{
    echo Building rootfs...
    cd $DEV_ROOT/src/ipcamera
    $MAKE
    $MAKE install
    $MAKE reinstall

    cd $DEV_ROOT/src
    $CP ipcamera/rootfs/root.jffs2 $DEV_ROOT/output
    $CP ipcamera/rootfs/root.sqsh4 $DEV_ROOT/output
}

clean_rootfs()
{
    echo Cleaning rootfs...
    cd $DEV_ROOT/src/ipcamera
    $MAKE clean
    $RM $DEV_ROOT/src/ipcamera/rootfs/rootfs.tar.gz
}

pack_basic()
{
    echo Packing Firmware...
    cd $DEV_ROOT/output
    $RM burntool
    $MKDIR burntool
    $CP ../src/burntool/* burntool/
    $CP zImage burntool/
    $CP root.sqsh4 burntool/
    $CP root.jffs2 burntool/
    $RM D1_Basic_$REV_ID.zip
    $ZIP D1_Basic_$REV_ID.zip burntool
}

build_all()
{
    build_tools
#    $MKDIR $DEV_ROOT/output/local/bin
#    $MKDIR $DEV_ROOT/output/local/lib
    config_kernel
    build_kernel
    config_busybox
    build_busybox
    build_rootfs
    pack_basic
}

clean_all()
{
#    clean_tools
    clean_kernel
    clean_busybox
    clean_rootfs
    cd $DEV_ROOT
    $RM $DEV_ROOT/output
    git status -s --ignored
}

usage()
{
    echo Usage: $0 [-v] [clean]
    echo Build Lamobo-D1 Firmware.
}

#
# Main
#

#
# Set essential variables
#
DEV_ROOT=`dirname $0`/..
DEV_ROOT=`cd $DEV_ROOT; pwd`

REV_ID=`git rev-parse HEAD`
REV_ID=${REV_ID:0:7}

NCPU=$((`grep '^processor' /proc/cpuinfo | wc -l` * 2))

export PATH=$DEV_ROOT/compiler/arm-2009q3/bin:$PATH

#
# Parse command line
#
ACTION=
VERBOSE=
while :; do
    case $1 in
        -v)
            VERBOSE=1
            ;;
        clean)
            ACTION=clean
            break
            ;;
        '')
            ACTION=build
            break
            ;;
        *)
            usage
            exit
            ;;
    esac
    shift
done

#
# Config tools according to the verbosity
#
if [ -z $VERBOSE ]; then
    APT_GET="sudo apt-get -y -qq"
    RM="rm -rf"
    TAR="tar"
    MKDIR="mkdir -p"
    MAKE="make -s"
    CP="cp"
    CHMOD="sudo chmod"
    STRIP="arm-none-linux-gnueabi-strip"
    ZIP="zip -r -q"
else
    APT_GET="sudo apt-get -y -q"
    RM="rm -rfv"
    TAR="tar -v"
    MKDIR="mkdir -p -v"
    MAKE="make"
    CP="cp -v"
    CHMOD="sudo chmod -v"
    STRIP="arm-none-linux-gnueabi-strip -v"
    ZIP="zip -r -v"
fi

#
# Perform build actions
#
if [ "$ACTION" == "build" ]; then
    build_all
elif [ "$ACTION" == "clean" ]; then
    clean_all
fi
