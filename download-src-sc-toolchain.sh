#!/bin/sh

# Run this script to download and extract the versions
# of source code this project was tested with. Unless
# otherwise noted these are the latest stable versions
# available at the time of writing.

# Based on gcc's download_prerequisites script

gcc='http://mirrors.kernel.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz'
binutils='http://mirrors.kernel.org/gnu/binutils/binutils-2.37.tar.xz'
linux='https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.14.tar.xz'
scgplzip='https://www.seagate.com/files/www-content/support-content/external-products/seagate-central/_shared/downloads/seagate-central-firmware-gpl-source-code.zip'

echo_archives() {
    echo "${gcc}"
    echo "${binutils}"
    echo "${linux}"
}

echo_zip_archives() {
    echo "${scgplzip}"
}

die() {
    echo "error: $@" >&2
    exit 1
}

mkdir -p src
cd src

if type wget > /dev/null ; then
    fetch='wget'
else
    if type curl > /dev/null; then
	fetch='curl -LO'
    else
	die "Unable to find wget or curl"
    fi    
fi

if ! type unzip > /dev/null ; then
    die "Unable to find unzip"
fi

for ar in $(echo_archives)
do
	${fetch} "${ar}"    \
		 || die "Cannot download $ar"
        tar -xf "$(basename ${ar})" \
		 || die "Cannot extract $(basename ${ar})"
done
unset ar

for ar in $(echo_zip_archives)
do	  
	${fetch} "${ar}"    \
		 || die "Cannot download $ar"
        unzip "$(basename ${ar})" \
		 || die "Cannot extract $(basename ${ar})"
done
unset ar

# Seagate Central Toolchain specific steps

echo "Copying and extracting glibc..."
cp sources/LGPL/glibc/glibc_ports.tar.bz2 ./
cp sources/LGPL/glibc/glibc.tar.bz2 ./
tar -xf glibc.tar.bz2
tar -xf glibc_ports.tar.bz2
ln -s ../glibc-ports-2.11-2010q1-mvl6/ glibc-2.11-2010q1-mvl6/ports

echo "Patching glibc..."
patch -p0 < ../0001-Seagate-Central-glibc-2.11.patch
patch -p0 < ../0002-Seagate-Central-glibc-ports.patch

