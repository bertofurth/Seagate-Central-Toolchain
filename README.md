TODO : Change linux source code versions. Check if using v5 linux always works anyway.

# Seagate-Central-Toolchain
Generate a toolchain to cross compile binaries for the Seagate 
Central NAS.

This project is based on 

https://github.com/mauro-dellachiesa/seagate-nas-central-toolchain

which builds a Seagate Central toolchain based on gcc 4.4.x. In
contrast, this project works with contemporary versions of gcc
on the build host to build a toolchain based on contempory
versions of gcc (5.x.x and above).

This procedure has been tested to work on the following build
platforms

* OpenSUSE Tumbleweed (Aug 2021) on x86  gcc 11.1.0 make 4.3
* OpenSUSE Tumbleweed (Aug 2021) on Raspberry Pi 4B  gcc 11.1.0 make 4.3
* Debian 10 (Buster) on x86  gcc 8.3.0 make 4.2.1

The procedure has been tested building the following versions of
GCC in conjunction with binutils-2.37

* 11.2.0
* 10.3.0
* 9.4.0
* 8.5.0
* 7.5.0
* 6.5.0 (See Troubleshooting section)
* 5.5.0 (See Troubleshooting section)
* 4.9.4 (Failed - use the mauro-dellachiesa project linked above)

In general, it is suggested to generate a toolchain based on the latest
stable version of gcc and binutils.

## Prerequisites
### Disk space
This procedure will take up to a maximum of about 3.5GiB of disk space
during the build process and will generate about 1.2GiB of finished
product. 

### Time
The build components take a total of about 45 minutes to complete on an 
8 core i7 PC. It takes about 6.5 hours on a Raspberry Pi 4B.

### Required tools
The following packages or their equivalents may need to be installed.

#### OpenSUSE Tumbleweed - Aug 2021 (zypper add ...)
* zypper install -t pattern devel_basis
* gcc-c++
* unzip
* lbzip2
* bzip2
* libtirpc-devel
* wget (or use "curl -O")
* git (optional)

#### Debian 10 - Buster (apt-get install ...)
* build-essential
* unzip
* gawk
* git (optional)

## Procedure
### Workspace preparation
If not already done, download the files in this project to a 
new directory on your build machine. 

For example, the following **git** command will download the 
files in this project to a new subdirectory called 
Seagate-Central-Samba

    git clone https://github.com/bertofurth/Seagate-Central-Toolchain.git
    
Alternately, the following **wget** and **unzip** commands will 
download the files in this project to a new subdirectory called
Seagate-Central-Toolchain-main

    wget https://github.com/bertofurth/Seagate-Central-Toolchain/archive/refs/heads/main.zip
    unzip main.zip

Change into this new subdirectory. This will be referred to as 
the base working directory going forward.

     cd Seagate-Central-Toolchain
     
### Source code download

TODO : Make a DOWNLOAD AND UNPACK script for both seagte linux
and for "latest tested" linux

The next part of the procedure involves gathering the source
code for each component and installing it into the **src** 
subdirectory of our workspace. First, ensure that this directory 
exists then change into it.

    mkdir -p src
    cd src

Download the Seagate Central GPL source code archive from 
Seagate's website using a tool like **wget** or **curl -O**, then
unzip the archive. This file contains the open source components 
that go into making the software on the Seagate Central.

    wget https://www.seagate.com/files/www-content/support-content/external-products/seagate-central/_shared/downloads/seagate-central-firmware-gpl-source-code.zip
    unzip seagate-central-firmware-gpl-source-code.zip
    
We need to copy the Seagate Central version of glibc, glibc-ports
and linux source code to the src subdirectory of the base working
directory. Note the linux source code has quite an unintuitive 
name so I suggest you rename it during the copy process as seen
below.

    cp sources/LGPL/glibc/glibc_ports.tar.bz2 ./
    cp sources/LGPL/glibc/glibc.tar.bz2 ./
    
BERTO HERE HERE
Use one or the other

    cp sources/GPL/linux/git_.home.cirrus.cirrus_repos.linux_6065f48ac9974b200566c51d58bced9c639a2aad.tar.gz ./linux.tar.gz
    
    OR
    
    wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.14.tar.xz
    
    MODIFY SCRIPT TO USE "LATEST" VERSION
    
We don't need anything else from this zip file so it and the
"sources" subdirectory containing its contents may be deleted 
to save disk space at this point. 

Extract the newly downloaded archives. Linux gets extracted to a 
directory called "git" but we must rename it to "linux". We also 
need to install a link within the glibc source tree to the 
glibc_ports directory.

    tar -xf linux.tar.gz
    mv git linux
    tar -xf glibc.tar.bz2
    tar -xf glibc_ports.tar.bz2
    ln -s ../glibc-ports-2.11-2010q1-mvl6/ glibc-2.11-2010q1-mvl6/ports

Since the version of glibc and glibc_ports being used is quite old (v2.11)
a few minor patches need to be applied when using modern compilation
tools otherwise errors will occur during the build. These patches are 
included in this project and can be applied from the src directory as follows.
     
    patch -p0 < ../0001-Seagate-Central-glibc-2.11.patch
    patch -p0 < ../0002-Seagate-Central-glibc-ports.patch
    
    
BERTO TODO : ADD A DOWNLOAD SCRIPT    
    
Download and extract binutils and gcc to the src directory. In this example 
we use the latest stable versions at the time of writing, binutils-2.37 and
gcc-11.2.0.
    
    wget http://mirrors.kernel.org/gnu/binutils/binutils-2.37.tar.bz2
    wget http://mirrors.kernel.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz
    tar -xf binutils-2.37.tar.bz2
    tar -xf gcc-11.2.0.tar.xz
     
GCC needs some extra components installed inside it's source tree in order
to be compiled. These can be automatically downloaded by running a script
embedded in the gcc source code as follows. 

     cd gcc-11.2.0
     ./contrib/download_prerequisites
     
Now that all the required source code is present we change directories back 
to the base working directory.

    cd ../..

### Customizing maketoolchain.sh
At this point we may need to edit the **maketoolchain.sh** script in the 
base working directory to set some parameters to guide the build process 
however in most cases the default settings will be fine.

Working our way from the top of the script the following parameters need to
be set and checked. The comments in the script explain the meanings of each
parameter. If in doubt just leave as they are.

    # Number of threads to engage during build process.
    # Set to less than or equal the number of available
    # CPU cores. Use J=1 for troubleshooting
    J=6

    # The location where the generated tools will be built
    # and finally installed. Note that this directory can't
    # easily be moved or renamed after the build is complete.
    #
    # If you're building multiple versions of gcc then name
    # this something like cross-X.Y.Z for each version
    TOP=$(pwd)/cross

    # These parameters are used by glibc. "build" is the
    # type of machine we are running this build process on.
    # "host" is the type of machine the generated tools will
    # run on. They are generally the same. Note that this
    # is different to "TARGET" which is the platform
    # the resultant cross compiler will generate binaries
    # for (i.e. the Seagate Central)
    #
    # Typical values are i686-pc-linux-gnu for PCs or
    # arm-linux-gnu for Raspberry Pi.
    #
    build=i686-pc-linux-gnu
    host=$build

    # To stop temporary objects from being deleted as each
    # stage finishes set to 0. This adds about 4.5GiB to the
    # disk space consumed by the build.
    CLEAN_OLD_OBJ=1
     
    # The cross compiler target name and prefix.
    # N.B. No dash - at the end.
    export TARGET=arm-sc-linux-gnueabi
    
    # Uncomment this parameter if compiling gcc 5.x.x while
    # building using gcc 11.x.x and above.
    #export CXXFLAGS="-std=gnu++14"


## Building
Once all the parameters have been set and the maketoolchain.sh
file is saved the build can be run by executing the 
maketoolchain.sh script

    ./maketoolchain.sh

The script will display a stage number, status and location of
a log file as each stage of the process completes. 

If a stage fails then the script will halt.

The generated cross compilation tools will be located in the
directory specified by the TOP parameter which by default is
the cross/tools subdirectory of the base working directory.

## Troubleshooting
Most problems will be due to 

* A needed build system component has not been installed.
* The build system has run out of disk space.
* The patches in this project have not been applied to glibc or 
  glibc_ports

If a stage fails then refer to the log file displayed and try to
correct the problem. It may be easier to read the log files if
**J=1** is set in the maketoolchain.sh script. This way only one
build thread will be active at a time and any errors will cause
the build to terminate straight away instead of having to wait
for other threads to finish.

If an error similar to the following appears during the GCC build
phase then it means that you may have forgotten to run the
**contrib/download_prerequisites** script from within the
gcc source code sub directory.

     checking for the correct version of mpfr.h... no
     configure: error: Building GCC requires GMP 4.2+, MPFR 3.1.0+ and MPC 0.8.0+.

After fixing any problems the process can be resumed by rerunning
the build script with an argument referring to the stage number
you'd like to start with. For example, if during stage 4 a 
problem is discovered but then corrected, one could re-run the
script starting at stage 4 with the following command.

    ./maketoolchain.sh 4

If significant changes are made to the maketoolchain.sh script
or if new system components are installed it may be necessary
to restart the build process afresh. Do this by deleting the
**cross** subdirectory and starting again. 

### gcc 6.x.x
When building gcc version 6.x.x a small patch must be applied
as follows to gcc from the src directory.

     patch -p0 < ../0099-gcc-6.5.0.patch
     
If this patch is not applied then the following error may appear
in the make_gcc3.log during the make 3rd (final) GCC build stage

    ..../src/gcc-6.5.0/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc:332:44: error: ‘ARM_VFPREGS_SIZE’ was not declared in this scope

### gcc 5.x.x
When building gcc versions 5.x.x while using gcc version 11.x.x
and above the following line in the maketoolchain.sh script must be
uncommented.

     #export CXXFLAGS="-std=gnu++14"

If this modification is not made then an error similar to the
following may appear in the logs during the make 1st GCC
build stage

    ..../src/gcc-5.5.0/gcc/reload1.c: In function ‘void init_reload()’:
    ..../src/gcc-5.5.0/gcc/reload1.c:115:24: error: use of an operand of type ‘bool’ in ‘operator++’ is forbidden in C++17

Many warnings similar to the following may also appear

     warning: ISO C++17 does not allow ‘register’ storage class specifier [-Wregister]
     
