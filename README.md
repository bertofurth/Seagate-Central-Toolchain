# Seagate-Central-Toolchain
Generate a toolchain to cross compile for the Seagate Central NAS

Note : This process takes up to a maximum of about 3.5GiB of 
disk space. Many 'weird' errors occur when disk space gets too low. 
To save space during the process we delete the generated obj objects 
after each stage is finished. 

This will consume about an extra 5GiB of disk space.



Tested to work on OpenSUSE Tumbleweed using gcc 11.1


Error fixing documentation
Makefile:246: *** mixed implicit and normal rules: deprecated syntax
make[2]: *** No rule to make target '/home/berto/src2/build-xgcc/cross-11.1.0/obj/eglibc/manual/stamp.o', needed by 'lib'.  Stop.


#### undefined reference to libgcc_s_resume
For example

ld: /home/berto/src2/build-xgcc/cross-11.1.0/obj/eglibc/libc_pic.os: in function `_Unwind_Resume':
(.text+0x4f8): undefined reference to `libgcc_s_resume'



#### mv sysroot/usr/libexec/getconf/.new ... are the same file

For example
mv: '/home/berto/src2/build-xgcc/cross-11.1.0/sysroot/usr/libexec/getconf/.new' and '/home/berto/src2/build-xgcc/cross-11.1.0/sysroot/usr/libexec/getconf/.new' are the same file
make[2]: *** [Makefile:339: /home/berto/src2/build-xgcc/cross-11.1.0/sysroot/usr/libexec/getconf] Error 1
make[2]: Leaving directory '/mnt/Ubuntu-2/root/src2/build-xgcc/src/glibc-2.11-2010q1-mvl6/posix'
make[1]: *** [Makefile:227: posix/subdir_install] Error 2
make[1]: Leaving directory '/mnt/Ubuntu-2/root/src2/build-xgcc/src/glibc-2.11-2010q1-mvl6'
make: *** [Makefile:15: install] Error 2

Installed

zypper install -t pattern devel_basis

gcc-c++
lbzip2


Obtain seagate-central-firmware-gpl-source-code.zip currently available at Seagate's webite from 

https://www.seagate.com/files/www-content/support-content/external-products/seagate-central/_shared/downloads/seagate-central-firmware-gpl-source-code.zip


unzip the file.

    unzip seagate-central-firmware-gpl-source-code.zip

We need to copy glibc and glibc-ports source code to the src
subdirectory of the directory we are working in.

    mkdir src
    cp sources/LGPL/glibc/glibc_ports.tar.bz2 .
    cp sources/LGPL/glibc/glibc.tar.bz2 .

At this point if you want to save disk space you can delete the
seagate-central-firmware-gpl-source-code.zip file and the extracted
contents. We don't need anything else from this file at the moment.

Extract the glibc archives. Make sure that lzip2 is installed in your
system in order to read the compressed archives.

tar -xf glibc.tar.bz2







