#!/bin/bash -e
#---------------------------------------------------------------------------------
# Prerequisites
#---------------------------------------------------------------------------------

#---------------------------------------------------------------------------------
# Windows 10
#   MSYS2 - 64bit
#   For details, please refer to readme.md
#---------------------------------------------------------------------------------

#---------------------------------------------------------------------------------
# Ubuntu 16.04
#   build-essential
#   git
#   texinfo
#---------------------------------------------------------------------------------

#---------------------------------------------------------------------------------
# Build Flag
#---------------------------------------------------------------------------------
SKIP_BINUTIL=0      # skip binutil build
SKIP_GCC1=0         # skip gcc phase 1 build
SKIP_NEWLIB=0       # skip newlib build
SKIP_GCC2=0         # skip gcc phase 2 build
SKIP_GDB=0          # skip gdb build
CREATE_MULTILIB=1   # create multi-libraqry
SKIP_TAR=0          # skip tar archive
TARGET_WIN=0		# Set 1 for canadian cross compile (doesn't work)
#PASSWORD           # password for sudo to create under /opt

#---------------------------------------------------------------------------------
# default parameters
#---------------------------------------------------------------------------------

#DEFAULT_BINUTILSPKG=binutils-2.31
#DEFAULT_GCCPKG=gcc-4.9.4
#DEFAULT_NEWLIBPKG=newlib-3.0.0.20180831
#DEFAULT_GDBPKG=gdb-8.1.1

DEFAULT_BINUTILSPKG=binutils-2.34
DEFAULT_GCCPKG=gcc-9.3.0
DEFAULT_NEWLIBPKG=newlib-3.3.0
DEFAULT_GDBPKG=gdb-9.2

DEFAULT_DEV_DIR=$PWD
DEFAULT_INSTALL_DIR_WIN='/c/cross'
DEFAULT_INSTALL_DIR_LINUX='/opt'

#---------------------------------------------------------------------------------
# error stop
#---------------------------------------------------------------------------------

set -e -o pipefail
trap 'echo "ERROR: line no = $LINENO, exit status = $?" >&2; exit 1' ERR

#---------------------------------------------------------------------------------
# set source packages
#---------------------------------------------------------------------------------

TARGET=rx-elf

if [ "$BINUTILSPKG" == '' ]; then
    BINUTILSPKG=$DEFAULT_BINUTILSPKG
fi
if [ "$GCCPKG" == '' ]; then
    GCCPKG=$DEFAULT_GCCPKG
fi
if [ "$NEWLIBPKG" == '' ]; then
    NEWLIBPKG=$DEFAULT_NEWLIBPKG
fi
if [ "$GDBPKG" == '' ]; then
    GDBPKG=$DEFAULT_GDBPKG
fi

#---------------------------------------------------------------------------------
# Check OS
#---------------------------------------------------------------------------------
export LC_ALL=C

if [ "$(uname)" == 'Darwin' ]; then
    OS='Mac'
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    OS='Linux'
    #BUILD='x86_64-unknown-linux-gnu'
    BUILD='x86_64-linux-gnu'
    if [ "$TARGET_WIN" == '1' ]; then
        HOST='--host=x86_64-w64-mingw32'
        #OSPRI='-win'
    else
        HOST='--host=x86_64-unknown-linux-gnu'
        HOST='x86_64-linux-gnu'
        #OSPRI=''
    fi
    if [ "$PASSWORD" == '' ]; then
        printf "Enter PASSWORD: "
        read PASSWORD
    fi
elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then
    OS='Mingw'
elif [ "$(expr substr $(uname -s) 1 12)" == 'MSYS_NT-10.0' ]; then
    OS='Mingw'
elif [ "$(expr substr $(uname -s) 1 15)" == 'MINGW64_NT-10.0' ]; then
    OS='Mingw'
elif [ "$(expr substr $(uname -s) 1 15)" == 'NIMGW32_NT-10.0' ]; then
    OS='Mingw'
else
    echo "OS ($(uname -a)) is not decided."
    exit 1
fi

#---------------------------------------------------------------------------------
# Install directories
#---------------------------------------------------------------------------------

if [ "$DEV_DIR" == '' ]; then
    DEV_DIR=$DEFAULT_DEV_DIR
    BUILD_DIR=$DEFAULT_DEV_DIR/build/$TARGET
    SRC_DIR=$DEFAULT_DEV_DIR/src
    RELEASE_DIR=$DEFAULT_DEV_DIR/release
fi
if [ "$INSTALL_DIR_WIN" == '' ]; then
    INSTALL_DIR_WIN=$DEFAULT_INSTALL_DIR_WIN
fi
if [ "$INSTALL_DIR_LINUX" == '' ]; then
    INSTALL_DIR_LINUX=$DEFAULT_INSTALL_DIR_LINUX
fi
if [ "$OS" == 'Mingw' ]; then
    INSTALL_DIR=$INSTALL_DIR_WIN
else
    INSTALL_DIR=$INSTALL_DIR_LINUX
fi
PREFIXDIR=$INSTALL_DIR/$TARGET-$GCCPKG

if [ $CREATE_MULTILIB == 1 ]; then
    MULTILIB='--enable-multilib --disable-libquadmath'
else
    MULTILIB='--disable-multilib'
fi
NEWLIB_NANO='--enable-newlib-nano-malloc --enable-newlib-nano-formatted-io --enable-target-optspace --enable-lite-exit --enable-newlib-global-atexit --enable-newlib-reent-small --disable-newlib-fvwrite-in-streamio'

mkdir -p $BUILD_DIR
mkdir -p $SRC_DIR
mkdir -p $RELEASE_DIR
if [ "$OS" == 'Mingw' ]; then
    mkdir -p $PREFIXDIR
    #chown $USER $PREFIXDIR
    #chown $USER $PREFIXDIR
    #chmod 755 $PREFIXDIR
else
    echo $PASSWORD | sudo -S mkdir -p $PREFIXDIR
    echo $PASSWORD | sudo -S chown $USER $PREFIXDIR
    echo $PASSWORD | sudo -S chgrp $USER $PREFIXDIR
    chmod 755 $PREFIXDIR
fi

#---------------------------------------------------------------------------------
# set compiler flags
#---------------------------------------------------------------------------------

export LANG=C
export CFLAGS='-O2 -pipe'
export CXXFLAGS='-O2 -pipe'
export LDFLAGS='-s'
export DEBUG_FLAGS=''
export MAKE_MULTI='-j4'

#---------------------------------------------------------------------------------
# Build and install binutils
#---------------------------------------------------------------------------------

if [ $SKIP_BINUTIL == 0 ]; then
    cd $SRC_DIR
    if [ ! -e $BINUTILSPKG.tar.gz ]; then
        wget ftp://sourceware.org/pub/binutils/releases/$BINUTILSPKG.tar.gz
        echo "untaring..."
        tar xf $SRC_DIR/$BINUTILSPKG.tar.gz
    fi
    rm -rf $BUILD_DIR/$BINUTILSPKG/*
    mkdir -p $BUILD_DIR/$BINUTILSPKG

    cd $BUILD_DIR/$BINUTILSPKG
    LDFLAGS=-static ../../../src/$BINUTILSPKG/configure --prefix=$PREFIXDIR --target=$TARGET $HOST --disable-nls --disable-shared --enable-debug --disable-threads --with-gcc --with-gnu-as --with-gnu-ld --with-stabs --enable-interwork $MULTILIB 2>&1 | tee ${BINUTILSPKG}_configure.log

    make $MAKE_MULTI 2>&1 | tee ${BINUTILSPKG}_make.log
    make install 2>&1 | tee ${BINUTILSPKG}_install.log
fi

#---------------------------------------------------------------------------------
# Build and install gcc without newlib
#---------------------------------------------------------------------------------

export PATH=$PREFIXDIR/bin:${PATH}

if [ $SKIP_GCC1 == 0 ]; then
    cd $SRC_DIR
    if [ ! -e $GCCPKG.tar.gz ]; then
        wget ftp://ftp.gnu.org/gnu/gcc/$GCCPKG/$GCCPKG.tar.gz
        echo "untaring..."
        tar xf $SRC_DIR/$GCCPKG.tar.gz
        cd $SRC_DIR/$GCCPKG
        ./contrib/download_prerequisites
    fi
    rm -rf $BUILD_DIR/$GCCPKG/*
    mkdir -p $BUILD_DIR/$GCCPKG

    #unset CT_CC_GCC_ENABLE_TARGET_OPTSPACE
    cd $BUILD_DIR/$GCCPKG
#    LDFLAGS=-static ../../../src/$GCCPKG/configure --enable-languages=c,c++ --with-newlib --disable-shared --disable-nls --enable-interwork --disable-thread  --without-headers --disable-libssp --disable-libstdcxx-pch --target=$TARGET --prefix=$PREFIXDIR $HOST -v 2>&1 | tee ${GCCPKG}-all_configure.log

    LDFLAGS=-static ../../../src/$GCCPKG/configure -v --target=$TARGET --prefix=$PREFIXDIR $HOST --enable-languages=c,c++ --disable-shared --with-newlib --enable-lto --enable-gold --disable-libstdcxx-pch --disable-nls 2>&1 | tee ${GCCPKG}-all_configure.log    
    
    make $MAKE_MULTI all-gcc 2>&1 | tee ${GCCPKG}-all_make.log
    make install-gcc 2>&1 | tee ${GCCPKG}-all_install.log
fi

#---------------------------------------------------------------------------------
# Build and install newlib
#---------------------------------------------------------------------------------

if [ $SKIP_NEWLIB == 0 ]; then
    cd $SRC_DIR
    if [ ! -e $NEWLIBPKG.tar.gz ]; then
        wget ftp://sourceware.org/pub/newlib/$NEWLIBPKG.tar.gz
        echo "untaring..."
        tar xf $SRC_DIR/$NEWLIBPKG.tar.gz
        if [ $NEWLIBPKG == '2.4.0.20160923' ]; then
            cp $DEVDIR/$NEWLIBPKG.patch $SRC_DIR
            patch -p1 -d $NEWLIBPKG < $NEWLIBPKG.patch
        fi
    fi
    rm -rf $BUILD_DIR/$NEWLIBPKG/*
    mkdir -p $BUILD_DIR/$NEWLIBPKG

    cd $BUILD_DIR/$NEWLIBPKG
    ../../../src/$NEWLIBPKG/configure --prefix=$PREFIXDIR --target=$TARGET $HOST $MULTILIB --disable-shared --disable-libquadmath --disable-libada --disable-libssp $NEWLIB_NANO 2>&1 | tee ${NEWLIBPKG}_configure.log

    make $MAKE_MULTI 2>&1 | tee ${NEWLIBPKG}_make.log
    make install 2>&1 | tee ${NEWLIBPKG}_install.log
fi

#---------------------------------------------------------------------------------
# Build and install gcc
#---------------------------------------------------------------------------------

if [ $SKIP_GCC2 == 0 ]; then
    rm -rf $BUILD_DIR/$GCCPKG/*
    mkdir -p $BUILD_DIR/$GCCPKG
    cd $BUILD_DIR/$GCCPKG
    #../../../src/$GCCPKG/configure --enable-languages=c,c++ --with-newlib --disable-shared --disable-nls --enable-lto --enable-interwork --disable-thread --disable-libgfortran --target=$TARGET --prefix=$PREFIXDIR $HOST -v 2>&1 | tee ${GCCPKG}_configure.log

    #LDFLAGS=-static ../../../src/$GCCPKG/configure --enable-languages=c,c++ --with-newlib --disable-shared --disable-nls --enable-interwork --disable-thread --without-headers --disable-libssp --disable-libstdcxx-pch --enable-lto --target=$TARGET --prefix=$PREFIXDIR $HOST -v 2>&1 | tee ${GCCPKG}-all_configure.log

    LDFLAGS=-static ../../../src/$GCCPKG/configure -v --target=$TARGET --prefix=$PREFIXDIR $HOST --enable-languages=c,c++ --disable-shared --with-newlib --enable-lto --enable-gold --disable-libstdcxx-pch --disable-nls 2>&1 | tee ${GCCPKG}-all_configure.log
    
    make $MAKE_MULTI all 2>&1 | tee ${GCCPKG}_make.log
    make install 2>&1 | tee ${GCCPKG}_install.log
fi

#---------------------------------------------------------------------------------
# Build and install gdb
#---------------------------------------------------------------------------------

if [ $SKIP_GDB == 0 ]; then
    cd $SRC_DIR
    if [ ! -e $GDBPKG.tar.gz ]; then
        wget http://ftp.gnu.org/gnu/gdb/$GDBPKG.tar.gz
        echo "untaring..."
        tar xf $SRC_DIR/$GDBPKG.tar.gz
    fi

    rm -rf $BUILD_DIR/$GDBPKG/*
    mkdir -p $BUILD_DIR/$GDBPKG

    cd $BUILD_DIR/$GDBPKG
    LDFLAGS=-static ../../../src/$GDBPKG/configure --prefix=$PREFIXDIR --target=$TARGET $HOST --disable-shared --disable-nls 2>&1 | tee ${GDBPKG}_configure.log

    make $MAKE_MULTI 2>&1 | tee ${GDBPKG}_make.log
    make install 2>&1 | tee ${GDBPKG}_install.log
fi

#---------------------------------------------------------------------------------
# zip
#---------------------------------------------------------------------------------

if [ $SKIP_TAR == 0 ]; then
    COMBINATION_DIR=$BINUTILSPKG-$GCCPKG-$NEWLIBPKG-$GDBPKG
    mkdir -p $RELEASE_DIR/$OS/$COMBINATION_DIR
    cd $INSTALL_DIR
    if [ -e $RELEASE_DIR/$OS/$COMBINATION_DIR/$TARGET-$GCCPKG.tar.gz ]; then 
        if [ "$OS" == 'Mingw' ]; then
            rm -f $RELEASE_DIR/$OS/$COMBINATION_DIR/$TARGET-$GCCPKG.tar.gz
        else
            #sudo rm -f $TARGET-$GCCPKG.tar.gz
            rm -f $RELEASE_DIR/$OS/$COMBINATION_DIR/$TARGET-$GCCPKG.tar.gz
        fi
    fi
    if [ "$OS" == 'Mingw' ]; then
        tar -cvzf $RELEASE_DIR/$OS/$COMBINATION_DIR/$TARGET-$GCCPKG.tar.gz $TARGET-$GCCPKG
    else
        #sudo tar -cvzf $TARGET-$GCCPKG.tar.gz $TARGET-$GCCPKG
        tar -cvzf $RELEASE_DIR/$OS/$COMBINATION_DIR/$TARGET-$GCCPKG.tar.gz $TARGET-$GCCPKG
    fi
fi