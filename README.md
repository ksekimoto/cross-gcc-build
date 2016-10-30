# cross-gcc-build

* The script is for building cross gcc compiler for Renesas RX, SH and H8 CPU.

# How to build

## Prerequisite

* Windows
*  Windows 10
*  MSYS2 (64bit)

* Linux
*  Ubuntu 14.04

* For Linux, only Ubuntu 14.04 environment are tested.

## Windows - Windows 10 MSYS2 environment

* Download MSYS2 Installer (either 64bit or 32bit)
*  [MSYS2 installer] (http://msys2.github.io/)
* Execute the installer
*  msys2-x86_64-20161025.exe
* Install development tools
*  Open All application - MSYS2 64bit - MSYS2 MinGW 64bit
*  export LANG=C
*  pacman -S base-devel 
```
xxxxxxxx@xxxxxxxx MINGW64 ~
$ export LANG=C

xxxxxxxx@xxxxxxxx MINGW64 ~
$ pacman -S base-devel
:: There are 54 members in group base-devel:
:: Repository msys
   1) asciidoc  2) autoconf  3) autoconf2.13  4) autogen  5) automake-wrapper
   6) automake1.10  7) automake1.11  8) automake1.12  9) automake1.13
   10) automake1.14  11) automake1.15  12) automake1.6  13) automake1.7
   14) automake1.8  15) automake1.9  16) bison  17) diffstat  18) diffutils
   19) dos2unix  20) file  21) flex  22) gawk  23) gdb  24) gettext
   25) gettext-devel  26) gperf  27) grep  28) groff  29) help2man
   30) intltool  31) lemon  32) libtool  33) libunrar  34) m4  35) make
   36) man-db  37) pacman  38) pactoys-git  39) patch  40) patchutils  41) perl
   42) pkg-config  43) pkgfile  44) quilt  45) rcs  46) scons  47) sed
   48) swig  49) texinfo  50) texinfo-tex  51) ttyrec  52) unrar  53) wget
   54) xmlto

Enter a selection (default=all):
```

*  pacman -S mingw-w64-x86_64-toolchain

```
xxxxxxxx@xxxxxxxx MINGW64 ~
$ pacman -S mingw-w64-x86_64-toolchain
:: There are 16 members in group mingw-w64-x86_64-toolchain:
:: Repository mingw64
   1) mingw-w64-x86_64-binutils  2) mingw-w64-x86_64-crt-git
   3) mingw-w64-x86_64-gcc  4) mingw-w64-x86_64-gcc-ada
   5) mingw-w64-x86_64-gcc-fortran  6) mingw-w64-x86_64-gcc-libgfortran
   7) mingw-w64-x86_64-gcc-libs  8) mingw-w64-x86_64-gcc-objc
   9) mingw-w64-x86_64-gdb  10) mingw-w64-x86_64-headers-git
   11) mingw-w64-x86_64-libmangle-git  12) mingw-w64-x86_64-libwinpthread-git
   13) mingw-w64-x86_64-make  14) mingw-w64-x86_64-pkg-config
   15) mingw-w64-x86_64-tools-git  16) mingw-w64-x86_64-winpthreads-git

Enter a selection (default=all):
```

### Notes

* For 32bit version's execute,
*  Open MSYS2 MinGW 32bit window,
*  pacman -S mingw-w64-i686-toolchain

## Linux - Ubuntu 14.04 environment

* T.B.D.

## Set target CPU and package versions in a build script

* Select target CPU
*  rx-elf, sh-elf and h83000-elf were successfully built.

```
TARGET=rx-elf
```

* Select versions
*  you need to make sure which versions are available by checking their ftp/http sites

```
BINUTILSPKG=binutils-2.27
GCCPKG=gcc-4.9.4
NEWLIBPKG=newlib-2.3.0.20160226
GDBPKG=gdb-7.12
```

* Select installation directory
*  For Windows, default directory is c:/cross/xxxxxxx
*  For Linux, default directory is /opt/xxxxxx

## Execute build script

* Copy the build script (build_xx_gcc.sh) on any directory
* Execute the build script
*  bash ./build_xx_gcc.sh

```
xxxxxxxx@xxxxxxxx MINGW64 ~
$ ls
build_rx_gcc.sh

xxxxxxxx@xxxxxxxx MINGW64 ~
$ bash ./build_rx_gcc.sh

```
