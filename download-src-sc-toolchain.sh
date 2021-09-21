#!/bin/sh

# Run this script to download and extract the versions
# of source code this project was tested with. Unless
# otherwise noted these are the latest stable versions
# available at the time of writing.

# Set environment variable SEAGATE_LINUX=1 if you
# want to use Seagate's version of linux headers.

# Based on gcc's download_prerequisites script

gcc='http://mirrors.kernel.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz'
binutils='http://mirrors.kernel.org/gnu/binutils/binutils-2.37.tar.xz'
linux='https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.14.tar.xz'
scgplzip='https://www.seagate.com/files/www-content/support-content/external-products/seagate-central/_shared/downloads/seagate-central-firmware-gpl-source-code.zip'

echo_archives() {
    echo "${gcc}"
    echo "${binutils}"
if [ -z ${SEAGATE_LINUX+x} ]; then    
    echo "${linux}"
fi
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
	echo "Extracting $(basename ${ar})"
        tar -xf "$(basename ${ar})" \
	    || die "Cannot extract $(basename ${ar})"
done
unset ar

# Run download_prerequisites for gcc
gccv=$(basename -s .tar.xz ${gcc})
echo "Running ./contrib/download_prerequisites for $gccv"
pushd $gccv
./contrib/download_prerequisites
if [ $? -ne 0 ]; then
    echo "ERROR running download_prerequisites!!"
    echo "Continuing...but check this later or make gcc will fail!!"
fi
popd

# Seagate Central Toolchain specific steps

# Download and extract only required components of the
# Seagate Central GPL archive to save disk space.
${fetch} "${scgplzip}" || die "Cannot download $scgplzip"
echo "Extracting needed sources from $(basename ${scgplzip})"
unzip -q "$(basename ${scgplzip})" \
      sources/LGPL/glibc/glibc_ports.tar.bz2 \
      sources/LGPL/glibc/glibc.tar.bz2 \
    || die "Cannot extract $(basename ${scgplzip})"
cp sources/LGPL/glibc/glibc_ports.tar.bz2 ./
cp sources/LGPL/glibc/glibc.tar.bz2 ./
tar -xf glibc.tar.bz2 || die "Cannot extract glibc.tar.bz2"
tar -xf glibc_ports.tar.bz2 || die "Cannot extract glibc_ports.tar.bz2"
ln -s ../glibc-ports-2.11-2010q1-mvl6/ glibc-2.11-2010q1-mvl6/ports

if [ ! -z ${SEAGATE_LINUX+x} ]; then
    echo "Extracting Seagate Linux"
    unzip -q "$(basename ${scgplzip})" \
	  sources/GPL/linux/git_.home.cirrus.cirrus_repos.linux_6065f48ac9974b200566c51d58bced9c639a2aad.tar.gz \
	|| die "Cannot extract Seagate Linux from $(basename ${scgplzip})"
    cp sources/GPL/linux/git_.home.cirrus.cirrus_repos.linux_6065f48ac9974b200566c51d58bced9c639a2aad.tar.gz ./linux-seagate.tar.gz
    tar -xf linux-seagate.tar.gz || die "Cannot extract linux-seagate.tar.gz"
    mv git linux-seagate
fi

echo "Patching glibc..."
patch -p0 < ../0001-Seagate-Central-glibc-2.11.patch
patch -p0 < ../0002-Seagate-Central-glibc-ports.patch
