# Seagate-Central-Toolchain
Generate a toolchain to cross compile binaries for the Seagate 
Central NAS.

This project takes the work done at 

https://github.com/mauro-dellachiesa/seagate-nas-central-toolchain

and tweaks it slightly to work with contemporary versions of 
gcc amd make.

This procedure has been tested to work on the following building
platforms

* OpenSUSE Tumbleweed (Aug 2021) on x86  gcc v11.1 make 4.3
* OpenSUSE Tumbleweed (Aug 2021) on Raspberry Pi 4B  gcc v11.1 make 4.3
* Debian 10 (Buster) on x86  gcc 8.3.0 make 4.2.1

## Prerequisites
### Disk space
This procedure will take up to a maximum of about 3.5GiB of disk space
during the build process and will generate about 1.2GiB of finished
product. 

### Time
The build components take a total of about 45 minutes to complete on an 
8 core i7 PC. It takes about 6.5 hours on a Raspberry Pi 4B.

### Required tools
The following packages or their equivalents need to be installed on
a "fresh" OpenSUSE Tumbleweed system to perform the build (zypper add ... )

* zypper install -t pattern devel_basis
* gcc-c++
* unzip
* lbzip2
* bzip2
* libtirpc-devel

The following packages or their equivalents need to be installed on 
a "fresh" Debian 10 (Buster) system to perform the build (apt-get install ... )

* build-essential
* unzip
* curl
* gawk

## Procedure
### Preparation and source code download
Download the files in this project to a new directory on your
build machine. This will be referred to as the base working 
directory going forward.

The next part of the procedure involves gathering the source
code for each component and installing it into the **src** 
subdirectory of our workspace. First, ensure that this directory 
exists.

    mkdir -p src

Obtain the Seagate Central GPL source code archive available from 
Seagate's webite using a tool like **wget** or **curl -O**, then
unzip the archive. This file contains the open source components 
that go into making the software on the Seagate Central.

    curl -O https://www.seagate.com/files/www-content/support-content/external-products/seagate-central/_shared/downloads/seagate-central-firmware-gpl-source-code.zip
    unzip seagate-central-firmware-gpl-source-code.zip
    
We need to copy the Seagate Central glibc, glibc-ports and linux 
source code to the src subdirectory of the base working directory. 
Note the linux source code has quite an unintuitive name so I suggest
you rename it during the copy process as seen below.

    cp sources/LGPL/glibc/glibc_ports.tar.bz2 ./src
    cp sources/LGPL/glibc/glibc.tar.bz2 ./src
    cp sources/GPL/linux/git_.home.cirrus.cirrus_repos.linux_6065f48ac9974b200566c51d58bced9c639a2aad.tar.gz ./src/linux.tar.gz
    
We don't need anything else from this zip file so it and its 
contents may be deleted to save disk space at this point. This step 
is optional.

    rm -rf sources __MACOSX Cirrus\ Package\ Licenses.docx
    rm seagate-central-firmware-gpl-source-code.zip

Change to the src directory and extract the archives just copied into
it. Linux gets extracted to a directory called "git" but we must 
rename it to "linux". We also need to install a link within the glibc
source tree to the glibc_ports directory.

    pushd src
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
    
Download and extract binutils and gcc to the src directory. In this example 
we use the latest stable versions at the time of writing, binutils-2.37 and
gcc-11.2.0.
    
    curl -O http://mirrors.kernel.org/gnu/binutils/binutils-2.37.tar.bz2
    tar -xf binutils-2.37.tar.bz2
    curl -O http://mirrors.kernel.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz
    tar -xf gcc-11.2.0.tar.xz
     
GCC needs some extra components installed inside it's source tree in order
to be compiled. These can be automatically downloaded by running a script
embedded in the gcc source code as follows. 

     cd gcc-11.2.0
     ./contrib/download_prerequisites
     
Now that all the required source code is present we change directories back 
to the base working directory.

    popd

### Customizing maketoolchain.sh
At this point we need to edit the **maketoolchain.sh** script in the 
base working directory to set some parameters to guide the build process

Working our way from the top of the script the following parameters need to
be set and checked. The comments in the script explain the meanings of each
parameter. If in doubt just leave as they are.

    # Number of threads to engage during build process.
    # Set to less than or equal the number of available
    # CPU cores. Use J=1 for troubleshooting
    J=6
    
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
    # (N.B. No dash - at the end)
    export TARGET=arm-sc-linux-gnueabi


## Building
Once all the parameters have been set and the maketoolchain.sh
file is saved the build can be run by executing the 
maketoolchain.sh script

    ./maketoolchain.sh

The script will display an update as each stage of the process 
completes.

## Troubleshooting
If a stage fails then refer to the log file displayed and try to
correct the problem. After fixing the problem the process can be
resumed by rerunning the script with an argument referring to the
stage number you'd like to start with. For example, if during stage
4 a problem is discovered but then corrected, one could re-run
the script starting at stage 4 with the following command.

    ./maketoolchain.sh 4
    
The generated cross compilation tools will be located in the
cross/tools subdirectory of the base working directory.

The vast majority of problems will be due to 

* A needed build system component has not been installed.
* The build system has run out of disk space.
* The patches in this project have not been applied to glibc or 
  glibc_ports

It may be necessary to restart the build process if significant
changes are made to the maketoolchain.sh script or if new
system components are installed. Do this by deleting the
**cross** and **obj** subdirectories and starting again.

Other than that, check the log files referred to in the 
script output when problems occur. It may be easier to read the
log files if **J=1** is set in the maketoolchain.sh script. This
way only one build thread will be active and any errors will cause
the build to terminate straight away instead of having to wait
for other threads to finish.
