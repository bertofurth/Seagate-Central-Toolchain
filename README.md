# Seagate-Central-Toolchain
Generate a toolchain to cross compile binaries for the Seagate 
Central NAS.

This project is based on "seagate-nas-central-toolchain" by
mauro-dellachiesa which builds a toolchain based on GCC 4.4.x

https://github.com/mauro-dellachiesa/seagate-nas-central-toolchain

In contrast, this project builds a toolchain based on more recent
versions of GCC. By default, GCC version 11.2.0 is built however any
version of GCC after 5.x.x should be able to be built using the 
instructions in this project.

## TLDNR
Build a GCC 11.2.0 based cross compilation toolchain with prefix
"arm-sc-linux-gnueabi-" for the Seagate Central as follows.

    # Download this project to the build host
    git clone https://github.com/bertofurth/Seagate-Central-Toolchain.git
    cd Seagate-Central-Toolchain
    
    # Obtain the required source code 
    ./download-src-sc-toolchain.sh
    
    # Build the "arm-sc-linux-gnueabi-" toolchain for Seagate Central
    ./maketoolchain.sh

## Tested versions
This procedure has been tested to work on the following build
platforms

* OpenSUSE Tumbleweed (Aug 2021) on x86 (GCC 11.1.0, make 4.3)
* OpenSUSE Tumbleweed (Aug 2021) on Raspberry Pi 4B  (See Troubleshooting section)
* Debian 10 (Buster) on x86  (GCC 8.3.0, make 4.2.1)

The procedure has been tested building the following versions of
GCC in conjunction with binutils v2.37 (latest at time of writing) and
both Linux 5.14 (latest) and the Seagate supplied Linux headers (2.6.35)
(See note in Troubleshooting section in regards to using Linux later
than 5.12.x for some versions of GCC)

* 11.2.0 (Default)
* 10.3.0 
* 9.4.0 
* 8.5.0 
* 7.5.0
* 6.5.0 (See Troubleshooting section)
* 5.5.0 (See Troubleshooting section)
* 4.9.4 (Failed - use the mauro-dellachiesa project linked above)

Unless you have specific requirements, it is suggested to generate a 
toolchain based on the latest stable versions of GCC, binutils and 
Linux.

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
* git (Optional - To download this project)

#### Debian 10 - Buster (apt-get install ...)
* build-essential
* unzip
* gawk
* git (Optional - To download this project)

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
#### Automated Download script
The "download-src-sc-toolchain.sh" script will automatically download
the versions of source code tested with this procedure. Unless 
otherwise noted these are the latest stable releases at the time
of writing. Hopefully later versions, or at least those with the
same major version numbers, will still work with this guide.

* gcc-11.2.0 - http://mirrors.kernel.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz
* binutils-2.37 - http://mirrors.kernel.org/gnu/binutils/binutils-2.37.tar.xz
* linux-5.14 - https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.14.tar.xz
* Seagate Central GPL - https://www.seagate.com/files/www-content/support-content/external-products/seagate-central/_shared/downloads/seagate-central-firmware-gpl-source-code.zip

Execute this script as follows.

     ./download-src-sc-toolchain.sh
     
In the rare case that you wish to build the cross compiler using 
the original Seagate Central supplied version of Linux kernel headers
(2.6.35.13-cavm1.whitney-econa) then you can set the SEAGATE_LINUX
environment variable before running the script to force it to use
these old headers as follows.

     SEAGATE_LINUX=1 ./download-src-sc-toolchain.sh

Only use this option if you are planning to use the toolchain to cross
compile a very old version of software for the Seagate Central that does
not work well with modern Linux headers AND if you have no intention of
upgrading your Seagate Central to a modern Linux kernel as per the 
**Seagate-Central-Slot-In-v5.x-Kernel** project at

https://github.com/bertofurth/Seagate-Central-Slot-In-v5.x-Kernel 

#### Optional - Manual download and extract
Only perform this part of the procedure if you do not wish to use the
above mentioned automatic download scripts and would prefer to manually
download and extract the necessary source code archives. This might
be the case if you want to create a toolchain based on an older 
version of GCC in order to cross compile some particularly old software
that does not build easily using modern versions of GCC.

First, create an **src** subdirectory below the base working directory
to store the source code. Change into this directory.

    mkdir -p src
    cd src

##### Seagate Central GPL archive
Download the Seagate Central GPL source code archive from Seagate's
website, then unzip the archive. This file contains the open source 
components that go into making the software on the Seagate Central.

    wget https://www.seagate.com/files/www-content/support-content/external-products/seagate-central/_shared/downloads/seagate-central-firmware-gpl-source-code.zip
    unzip seagate-central-firmware-gpl-source-code.zip
    
##### glibc and glibc-ports    
Copy the Seagate Central version of glibc and glibc-ports from the
extracted archive to the src subdirectory of the base working
directory. 

    cp sources/LGPL/glibc/glibc_ports.tar.bz2 ./
    cp sources/LGPL/glibc/glibc.tar.bz2 ./

Extract glibc and glibc-ports as follows. Note that we need to
install a link within the glibc source tree to the glibc_ports 
directory.

    tar -xf glibc.tar.bz2
    tar -xf glibc_ports.tar.bz2
    ln -s ../glibc-ports-2.11-2010q1-mvl6/ glibc-2.11-2010q1-mvl6/ports

Since the version of glibc and glibc_ports being used is quite old (v2.11)
a few minor patches need to be applied when using modern compilation
tools otherwise errors will occur during the build. These patches are 
included in this project and can be applied from the src directory as 
follows.
     
    patch -p0 < ../0001-Seagate-Central-glibc-2.11.patch
    patch -p0 < ../0002-Seagate-Central-glibc-ports.patch

#### Linux kernel headers
At this point you need to decide whether to build the toolchain using
recent Linux headers or the Linux headers provided by Seagate. It is 
highly recommended to use recent Linux headers however if you are planning
to cross compile a particularly old version of software that is not
compatible with modern Linux headers then you can use Seagate supplied 
headers.

If you chose to use recent headers then download and extract
the relevant version as per the following example using Linux v5.14

     wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.14.tar.xz
     tar -xf linux-5.14.tar.xz

**NOTE**. Some versions of GCC do not build properly with versions of
Linux headers later than v5.12.x. See the Troubleshooting section for 
more details. 

If you chose to use the Seagate supplied Linux headers (version 
2.6.35.13-cavm1.whitney-econa) then copy the headers from the 
Seagate Central GPL archive and extract as follows.

    cp sources/GPL/linux/git_.home.cirrus.cirrus_repos.linux_6065f48ac9974b200566c51d58bced9c639a2aad.tar.gz ./linux-seagate.tar.gz
    tar -xf linux-seagate.tar.gz
    mv git linux-seagate
    
#### Binutils and GCC    
Download binutils and GCC to the src directory and extract them. In this
example we use the latest stable versions at the time of writing,
binutils-2.37 and gcc-11.2.0.
    
    wget http://mirrors.kernel.org/gnu/binutils/binutils-2.37.tar.bz2
    wget http://mirrors.kernel.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz
    tar -xf binutils-2.37.tar.bz2
    tar -xf gcc-11.2.0.tar.xz
     
GCC needs some extra components installed inside its source tree in order
to be compiled. These can be automatically downloaded by changing into the
extracted GCC source code subdirectory and running a script embedded in the
GCC source code as follows. 

     cd gcc-11.2.0
     ./contrib/download_prerequisites
     
Now that all the required source code is present, we change directories back 
to the base working directory.

    cd ../..

### Optional - Customizing maketoolchain.sh
At this point we may need to edit the **maketoolchain.sh** script in the 
base working directory to set some parameters to guide the build process 
however, in most cases the default settings will be fine.

Working our way from the top of the script, the following parameters need to
be set and checked. 

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

There are a number of other debugging parameters within the script
that can also be configured. Read the script itself for details.

## Building
The build can be run by executing the maketoolchain.sh script

    ./maketoolchain.sh

The script will display a stage number, status and location of
a log file as each stage of the process completes. 

If a stage fails, then the script will halt.

The generated cross compilation tools will be located in the
"cross" subdirectory by default and the PATH to the newly generated
executable tools will be the cross/tools subdirectory of the base
working directory. 

## Troubleshooting
Most problems will be due to 

* A needed build system component has not been installed.
* The build system has run out of disk space.
* The patches in this project have not been applied to glibc or 
  glibc_ports

If a stage fails then refer to the log file displayed and try to
correct the problem. It may be easier to read the log files if
**J=1** is set before running the maketoolchain.sh script. For
example

     J=1 ./maketoolchain.sh
     
This way only one build thread will be active at a time and any errors
will cause the build to terminate straight away instead of having to
wait for other threads to finish.

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

### Linux headers later than v5.12.x
The following error may be seen when building some versions of GCC
while using Linux headers from kernel versions later than v5.12.x.

    ..../gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cpp:134:10: fatal error: linux/cyclades.h: No such file or directory
       134 | #include <linux/cyclades.h>

An obsolete header file (/include/linux/cyclades.h) has been 
removed from Linux versions v5.13 and later. This file was 
required by some older versions of GCC in order to be built.
Releases of GCC issued after June 2021 should resolve this issue.

See

https://gcc.gnu.org/bugzilla/show_bug.cgi?id=100379

A workaround is to replace V5.14 in the Linux download step with
version 5.12.x . For example

    rm -rf linux-5.14      # Remove this version of linux
    wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.12.19.tar.xz
    tar -xf linux-5.12.19.tar.xz

### Building on Raspberry Pi
Since the version of GLIBC being used is quite old, it does not
automatically recognize the Raspberry Pi arm64 style build platform.

An error similar to the following may appear while GLIBC is going
through the configure stage.

    configure: error: cannot guess build type; you must specify one

Since this is the case, the "build" configure script parameter
needs to be manually specified for GLIBC. This can be done by
uncommenting the following variable in the maketoolchain.sh script
or setting it on the command line.

    BUILD_PLATFORM_STRING=--build=arm-linux-gnu

### GCC 6.x.x
When building GCC version 6.x.x a small patch must be applied
as follows to GCC from the src directory.

     patch -p0 < ../0099-gcc-6.5.0.patch
     
If this patch is not applied then the following error may appear
in the make_gcc3.log during the make 3rd (final) GCC build stage

    ..../src/gcc-6.5.0/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc:332:44: error: ‘ARM_VFPREGS_SIZE’ was not declared in this scope

### GCC 5.x.x
When building GCC versions 5.x.x while using GCC version 11.x.x
and above the following line in the maketoolchain.sh script must be
uncommented or set on the command line.

     CXXFLAGS="-std=gnu++14"

If this modification is not made then an error similar to the
following may appear in the logs during the make 1st GCC
build stage

    ..../src/gcc-5.5.0/gcc/reload1.c: In function ‘void init_reload()’:
    ..../src/gcc-5.5.0/gcc/reload1.c:115:24: error: use of an operand of type ‘bool’ in ‘operator++’ is forbidden in C++17

Many warnings similar to the following may also appear

     warning: ISO C++17 does not allow ‘register’ storage class specifier [-Wregister]

### GCC prerequisites
If an error similar to the following appears during the GCC build
phase then it means that the **contrib/download_prerequisites**
script has not properly executed from within the gcc source code
sub directory.

     checking for the correct version of mpfr.h... no
     configure: error: Building GCC requires GMP 4.2+, MPFR 3.1.0+ and MPC 0.8.0+.
     
This script should have been run automatically as part of
both the "download-src-sc-toolchain.sh" and 
"maketoolchain.sh" scripts but it may need to be run manually.
