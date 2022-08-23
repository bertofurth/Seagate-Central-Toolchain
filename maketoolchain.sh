#!/bin/bash
#
# maketoolchain [stage-num]
#
# Script to build GCC toolchain for Seagate Central NAS
# using open source code. Supply an optional "stage-num"
# argument number to begin the process at a stage other
# than the start.

# Edit the following variables to suit your build
# requirements.

# The target name and prefix that will be given
# to the generated toolchain.
# Should be something like arm-XXXX-linux-gnueabi
# N.B. No dash (-) at the end.
#
TARGET=arm-sc-linux-gnueabi

# The location where the generated tools will be 
# installed once building is complete.
#
# If you're building multiple versions of gcc then name
# this something like cross-X.Y.Z for each version
#
TOP=$(pwd)/cross

# *****************************************************
# *****************************************************
# It's not likely that any of the values below need to
# be changed.
# *****************************************************
# *****************************************************

# Number of threads to engage during build process.
#
# If not explicitly set then we use the total
# number of CPUs available according to "nproc".
#
# Use J=1 for troubleshooting
#
J=${J-$(nproc)}

# Some build platforms are not correctly detected by
# the GLIBC build process. Particularly Raspberry Pi
#
# Uncomment this variable if building on a Raspberry
# Pi, other aarch64 / arm64 platform, or if an error
# of the following type appears
#
# configure: error: cannot guess build type; you must specify one
# 
#BUILD_PLATFORM_STRING=--build=arm-linux-gnu

# To stop temporary objects from being deleted as each
# stage finishes uncomment or set the following variable.
# This adds up to 5GB to the disk space consumed by the build.
#KEEP_OLD_OBJ=1
    
# To embed a "sysroot" directory in the toolchain uncomment
# or set the following variable. Embedding a sysroot directory
# makes cross compilation a little easier but it means the built
# toolchain is difficult to move to another directory after
# it's been generated and installed.
WITH_SYSROOT=1
         
# Uncomment or set this parameter if compiling gcc 5.x.x
# while building using gcc 11.x.x and above.
#CXXFLAGS="-std=gnu++14"
    

# ************************************************
# ************************************************
# Nothing below here should normally need to be
# modified.
# ************************************************
# ************************************************

linux_arch=arm
export ARCH=arm
export CROSS_COMPILE=${TARGET}-

#
# This is to stop some documentation being built. 
export MAKEINFO=:

# see https://gcc.gnu.org/bugzilla/show_bug.cgi?id=14654
export _POSIX2_VERSION=199209

# The version of glibc associated with the Seagate
# Central
GLIBC=glibc-2.11-2010q1-mvl6

# The locations of the source code and generated
# binaries
SRC=$(pwd)/src
OBJ=$TOP/obj
TOOLS=$TOP/tools

export SYSROOT=$TOP/sysroot

if [[ $WITH_SYSROOT -eq 1 ]]; then
    WITH_SYSROOT_OPTION="--with-sysroot=$SYSROOT"
fi

export PATH=$TOOLS/bin:$PATH
unset LD_LIBRARY_PATH

mkdir -p $OBJ
mkdir -p $TOOLS
mkdir -p $SYSROOT

ZIPSRC=seagate-central-firmware-gpl-source-code.zip

# Set the names of the gcc and binutils source
# sub directory. We automatically search for
# the latest version of name-X.X.X
binutilsv=binutils
gccv=gcc
linuxv=linux

gccv=$(basename $(ls -1drv $SRC/$gccv*/))
binutilsv=$(basename $(ls -1drv $SRC/$binutilsv*/))
linuxv=$(basename $(ls -1drv $SRC/$linuxv*/))

if [ ! -d $SRC/$gccv ]; then
    echo "Unable to find gcc. Please have gcc source installed"
    echo "in the $SRC/gcc-X.X.X directory"
    exit 1
fi

if [ ! -d $SRC/$gccv/gmp ]; then
    echo "Unable to find gcc prerequisites in $SRC/$gccv"
    echo "Running ./contrib/download_prerequisites "
    pushd $SRC/$gccv
    ./contrib/download_prerequisites
    if [ $? -ne 0 ]; then
       echo "Error running download_prerequisites"
       echo "Exiting"
       exit -1
    fi   
fi

if [ ! -d $SRC/$linuxv ]; then
    echo "Please copy $linuxv to $SRC/$linuxv"
    echo "$linuxv is included in GPL/linux/git_<...>.tar.gz in $ZIPSRC"
    echo "or download a version from kernel.org"
    exit 1
fi

if [ ! -d $SRC/$GLIBC ]; then
    echo "Please copy $GLIBC to $SRC/$GLIBC"
    echo "$GLIBC is included in LGPL/glibc/glibc.tar in $ZIPSRC"
    exit 1
fi

if [ ! -d $SRC/$GLIBC ]; then
    echo "Please copy $GLIBC to $SRC/$GLIBC"
    echo "$GLIBC is included in LGPL/glibc/glibc.tar in $ZIPSRC"
    exit 1
fi
    
if [ ! -d $SRC/$GLIBC/ports ]; then
    echo "Please link $SRC/$GLIBC/ports to glibc-ports"
    echo "glibc-ports is included in LGPL/glibc/glibc_ports.tar in $ZIPSRC"
    echo "after extracting glibc_ports.tar to $SRC"
    echo "run"
    echo "ln -s ../glibc-ports-2.11-2010q1-mvl6/ $SRC/$GLIBC/ports"
    exit 1
fi

echo
echo "Building $TARGET toolchain in $TOOLS"
echo "Detected $binutilsv $gccv"
echo "Using linux headers in $SRC/$linuxv"
echo "sysroot is $SYSROOT"
echo "Threads in use : j=$J"
if [[ $WITH_SYSROOT -eq 1 ]]; then
    echo "Embedding sysroot $SYSROOT in generated toolset "
else
    echo "Not embedding sysroot in generated toolset (default) "
fi
if [[ $KEEP_OLD_OBJ -eq 1 ]]; then
    echo "WARNING - Keeping old objects!! May consume 5GB extra disk space!!"
fi

echo
echo "Reference: Cross-Compiling EGLIBC by Jim Blandy <jimb@codesourcery.com>"
echo "           in $SRC/$GLIBC/EGLIBC.cross-building"
echo "Based on : https://github.com/mauro-dellachiesa/seagate-nas-central-toolchain"
echo
# Printing free space on the device because this process takes up
# so much disk space.
df -h $OBJ

echo

GRN="\e[32m"
RED="\e[31m"
YEL="\e[33m"
NOCOLOR="\e[0m"

#report error.  4 arguments.
# $1-retval (0 means success)  $2-name $3-log file 
checkerr()
{
    if [ $1 -ne 0 ]; then
	echo -e "$RED  Failure: $2. $NOCOLOR $(date +%T) Check $3"
	tail -n 10 $3 | grep -i error
	exit 1
    else
	echo -e "$GRN  Success: $2.$NOCOLOR $(date +%T) See $3"
    fi
}

clean_obj()
{
    cd $OBJ
    if [[ ! $KEEP_OLD_OBJ -eq 1 ]]; then
	rm -rf $1
    fi

}

start_stage=$1
current_stage=0
skip_stage=0

# Run this before each stage and check the
# skip_stage variable to see if a stage should
# be run.
new_stage()
{
    skip_stage=0
    let current_stage++
    if [[ $current_stage -ge $start_stage ]]; then
	echo -e "$GRN Stage $current_stage : $1$NOCOLOR : $(date +%T)"
    else
        skip_stage=1
    fi
}

cd $SRC

new_stage "binutils ($binutilsv)" 
if [[ $skip_stage -eq 0 ]]; then
    ### BINUTILS
    if [ -z $binutilsv ]; then
	echo Unable to find any binutils folders. Make sure
	echo to extract the archive into the $SRC directory
	echo or manually set the location
	exit -1
    fi
    
    if [ ! -d $binutilsv ]; then
    echo "Please copy $binutilsv to $SRC/$binutilsv"
    exit 1
    fi
    mkdir -p $OBJ/binutils
    cd $OBJ/binutils

    $SRC/$binutilsv/configure --target=$TARGET --prefix=$TOOLS \
			      $WITH_SYSROOT_OPTION \
			      --disable-werror \
			      --with-arch=armv6 --with-fpu=vfp --with-float=softfp \
	&> $TOP/config_binutils.log
    
    checkerr $? "config binutils" $TOP/config_binutils.log
    make -j$J &> $TOP/make_binutils.log
    checkerr $? "make binutils" $TOP/make_binutils.log

    make install &> $TOP/make_binutils_install.log
    checkerr $? "install binutils" $TOP/make_binutils_install.log
    clean_obj "$OBJ/binutils"
fi


new_stage "1st GCC ($gccv)"
if [[ $skip_stage -eq 0 ]]; then
    ### THE FIRST GCC

    if [ -z $gccv ]; then
	echo Unable to find any gcc folders. Make sure
	echo to extract the archive into the $SRC directory
	echo or manually set the location
	exit -1
    fi
    mkdir -p $OBJ/gcc1
    cd $OBJ/gcc1

    $SRC/$gccv/configure \
	--target=$TARGET \
	--prefix=$TOOLS \
	--with-newlib \
	--without-headers \
	--enable-initfini-array \
	--disable-nls \
	--disable-shared \
	--disable-multilib \
	--disable-decimal-float \
	--disable-threads \
	--disable-libatomic \
	--disable-libgomp \
	--disable-libquadmath \
	--disable-libssp \
	--disable-libvtv \
	--disable-libstdcxx \
	--enable-languages=c,c++ \
	--with-arch=armv6 --with-fpu=vfp --with-float=softfp \
	--verbose &> $TOP/config_gcc1.log
    
    checkerr $? "config 1st GCC" $TOP/config_gcc1.log
    make -j$J &> $TOP/make_gcc1.log
    
    checkerr $? "make 1st GCC" $TOP/make_gcc1.log

    make install &> $TOP/make_gcc1_install.log
    checkerr $? "install 1st GCC" $TOP/make_gcc1_install.log
    clean_obj "$OBJ/gcc1"
fi

new_stage "Linux headers ($linuxv)"
if [[ $skip_stage -eq 0 ]]; then
    ### LINUX KERNEL HEADERS
    cp -r $SRC/$linuxv $OBJ/linux
    cd $OBJ/linux
    make headers_install ARCH=$linux_arch CROSS_COMPILE=$TARGET- \
	 INSTALL_HDR_PATH=$SYSROOT/usr &> $TOP/make_linux_hdr_install.log
    checkerr $? "install Linux headers" $TOP/make_linux_hdr_install.log
    clean_obj "$OBJ/linux"
fi

new_stage "1st GLIBC (EGLIBC Headers and Preliminary Objects)"
if [[ $skip_stage -eq 0 ]]; then
    ### EGLIBC Headers and Preliminary Objects
    cd $SRC/$GLIBC/
    mkdir -p $OBJ/eglibc-headers
    cd $OBJ/eglibc-headers
    libc_cv_broken_visibility_attribute=no \
				       BUILD_CC=gcc \
				       CC=$TOOLS/bin/$TARGET-gcc \
				       CXX=$TOOLS/bin/$TARGET-g++ \
				       AR=$TOOLS/bin/$TARGET-ar \
				       RANLIB=$TOOLS/bin/$TARGET-ranlib \
				       $SRC/$GLIBC/configure \
				       --prefix=/usr \
				       --with-headers=$SYSROOT/usr/include \
				       $BUILD_PLATFORM_STRING \
				       --host=$TARGET \
				       --disable-profile --without-gd --without-cvs --enable-add-ons \
				       --with-arch=armv6 --with-fpu=vfp --with-float=softfp \
	&> $TOP/config_eglibc1.log



    checkerr $? "config 1st GLIBC" $TOP/config_eglibc1.log

    make -j$J cross-compiling=yes install_root=$SYSROOT install-headers \
	 install-bootstrap-headers=yes &> $TOP/make_eglibc_hdr1.log
    checkerr $? "make 1st GLIBC" $TOP/make_eglibc_hdr1.log

    mkdir -p $SYSROOT/usr/lib
    make csu/subdir_lib &> $TOP/make_eglibc_csu1.log
    checkerr $? "make 1st GLIBC csu" $TOP/make_eglibc_csu1.log

    cp csu/crt1.o csu/crti.o csu/crtn.o $SYSROOT/usr/lib
    $TOOLS/bin/$TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $SYSROOT/usr/lib/libc.so
    clean_obj "$OBJ/eglibc-headers"
fi

new_stage "2nd GCC ($gccv)"
if [[ $skip_stage -eq 0 ]]; then
    ### The Second GCC
    mkdir -p $OBJ/gcc2
    cd $OBJ/gcc2
    $SRC/$gccv/configure \
	--target=$TARGET \
	--prefix=$TOOLS \
	--with-sysroot=$SYSROOT \
	--with-headers=$SYSROOT/usr/include \
	--disable-libatomic \
	--disable-libquadmath \
	--disable-libssp --disable-libgomp  \
	--enable-languages=c \
	--with-arch=armv6 --with-fpu=vfp --with-float=softfp \
	&> $TOP/config_gcc2.log
    checkerr $? "config 2nd GCC" $TOP/config_gcc2.log

    make -j$J &> $TOP/make_gcc2.log
    checkerr $? "make 2nd GCC" $TOP/make_gcc2.log

    make install &> $TOP/make_gcc2_install.log
    checkerr $? "install 2nd GCC" $TOP/make_gcc2_install.log
    clean_obj "$OBJ/gcc2"
fi

new_stage "complete GLIBC"
if [[ $skip_stage -eq 0 ]]; then
    ### EGLIBC, Complete
    mkdir -p $OBJ/eglibc
    cd $OBJ/eglibc
    libc_cv_broken_visibility_attribute=no \
				       libc_cv_ssp=no \
				       BUILD_CC=gcc \
				       CC=$TOOLS/bin/$TARGET-gcc \
				       CXX=$TOOLS/bin/$TARGET-g++ \
				       AR=$TOOLS/bin/$TARGET-ar \
				       RANLIB=$TOOLS/bin/$TARGET-ranlib \
				       $SRC/$GLIBC/configure \
				       --prefix=/usr \
				       --with-headers=$SYSROOT/usr/include \
				       $BUILD_PLATFORM_STRING \
				       --host=$TARGET \
				       --disable-profile --without-gd --without-cvs --enable-add-ons \
				       --with-arch=armv6 --with-fpu=vfp --with-float=softfp \
	&> $TOP/config_eglibc2.log 



    checkerr $? "config complete GLIBC" $TOP/config_eglibc2.log
    
    make -j$J &> $TOP/make_eglibc2.log
    checkerr $? "make complete GLIBC" $TOP/make_eglibc2.log

    # last line of cross/obj/eglibc/posix/getconf.speclist has space instead of newline?

    make install_root=$SYSROOT install &> $TOP/make_eglibc2_install.log
    checkerr $? "install complete GLIBC" $TOP/make_eglibc2_install.log 1
    clean_obj "$OBJ/eglibc"
fi

new_stage "3rd (final) GCC ($gccv)"
if [[ $skip_stage -eq 0 ]]; then
    ### The Third GCC
    mkdir -p $OBJ/gcc3

    cd $OBJ/gcc3
#    echo LDFLAGS IS CURRENTLY $LDFLAGS
#    sleep 10
#    export LDFLAGS=$LDFLAGS" -Wl,--sysroot=$SYSROOT"
#    echo New LDFLAGS is $LDFLAGS
#    sleep 10
    
    $SRC/$gccv/configure \
	--target=$TARGET \
	--prefix=$TOOLS \
	--enable-__cxa_atexit \
	--disable-libssp \
	--disable-libgomp \
	--enable-languages=c,c++ \
	$WITH_SYSROOT_OPTION \
	--with-build-sysroot=$SYSROOT \
	--with-arch=armv6 --with-fpu=vfp --with-float=softfp \
	&> $TOP/config_gcc3.log

    checkerr $? "config 3rd (final) GCC" $TOP/config_gcc3.log

    make -j$J &> $TOP/make_gcc3.log
    checkerr $? "make 3rd (final) GCC" $TOP/make_gcc3.log

    make install &> $TOP/make_gcc3_install.log
    checkerr $? "install 3rd (final) GCC" $TOP/make_gcc3_install.log
    clean_obj "$OBJ/gcc3"
fi

cp -d $TOOLS/$TARGET/lib/libgcc_s.so* $SYSROOT/lib
cp -d $TOOLS/$TARGET/lib/libstdc++.so* $SYSROOT/usr/lib

