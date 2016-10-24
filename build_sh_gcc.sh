#---------------------------------------------------------------------------------
# Build Flag
#---------------------------------------------------------------------------------
SKIP_BINUTIL=0
SKIP_GCC1=0
SKIP_NEWLIB=0
SKIP_GCC2=0
SKIP_GDB=0
CREATE_MULTILIB=0

#---------------------------------------------------------------------------------
# Check OS
#---------------------------------------------------------------------------------

if [ "$(uname)" == 'Darwin' ]; then
    OS='Mac'
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    OS='Linux'
elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then                                                                                           
    OS='Mingw'
else
    echo "OS ($(uname -a)) is not decided."
    exit 1
fi

#---------------------------------------------------------------------------------
# Source and Install directories
#---------------------------------------------------------------------------------

TARGET=sh-elf
BINUTILSPKG=binutils-2.27
GCCPKG=gcc-4.9.3
#NEWLIBPKG=newlib-2.4.0.20160923
NEWLIBPKG=newlib-2.3.0.20160226
GDBPKG=gdb-7.12
DEVDIR=$HOME/dev
BUILDDIR=$DEVDIR/build/$TARGET
SRCDIR=$DEVDIR/src
if [ "$OS" == 'Mingw' ]; then
    if [ $CREATE_MULTILIB == 1 ]; then
        PREFIXDIR=/c/cross/$GCCPKG-$TARGET-M
    else
        PREFIXDIR=/c/cross/$GCCPKG-$TARGET
    fi
else
    if [ $CREATE_MULTILIB == 1 ]; then
        PREFIXDIR=/opt/$GCCPKG-$TARGET-M
    else
        PREFIXDIR=/opt/$GCCPKG-$TARGET
    fi
fi
if [ $CREATE_MULTILIB == 1 ]; then
    MULTILIB='--enable-multilib'
else
    MULTILIB='--disable-multilib'
fi
NEWLIB_NANO='--enable-newlib-nano-malloc --enable-newlib-nano-formatted-io --enable-target-optspace --enable-lite-exit --enable-newlib-global-atexit --enable-newlib-reent-small --disable-newlib-fvwrite-in-streamio'

mkdir -p $BUILDDIR
mkdir -p $SRCDIR
sudo mkdir -p $PREFIXDIR
sudo chown $USER $PREFIXDIR
chmod 755 $PREFIXDIR

#---------------------------------------------------------------------------------
# set compiler flags
#---------------------------------------------------------------------------------

export CFLAGS='-O2 -pipe'
export CXXFLAGS='-O2 -pipe'
export LDFLAGS='-s'
export DEBUG_FLAGS=''

#---------------------------------------------------------------------------------
# Build and install binutils
#---------------------------------------------------------------------------------

if [ $SKIP_BINUTIL == 0 ]; then
    cd $SRCDIR
    if [ ! -e $BINUTILSPKG.tar.gz ]; then
        wget ftp://sourceware.org/pub/binutils/releases/$BINUTILSPKG.tar.gz
        tar xf $SRCDIR/$BINUTILSPKG.tar.gz
    fi
    rm -rf $BUILDDIR/$BINUTILSPKG/*
    mkdir -p $BUILDDIR/$BINUTILSPKG

    cd $BUILDDIR/$BINUTILSPKG
../../../src/$BINUTILSPKG/configure --prefix=$PREFIXDIR --target=$TARGET --disable-nls --disable-shared --enable-debug --disable-threads --with-gcc --with-gnu-as --with-gnu-ld --with-stabs --enable-interwork $MULTILIB 2>&1 | tee ${BINUTILSPKG}_configure.log

    make 2>&1 | tee ${BINUTILSPKG}_make.log
    make install 2>&1 | tee ${BINUTILSPKG}_install.log
fi

#---------------------------------------------------------------------------------
# Build and install gcc without newlib
#---------------------------------------------------------------------------------

export PATH=$PREFIXDIR/bin:${PATH}

if [ $SKIP_GCC1 == 0 ]; then
    cd $SRCDIR
    if [ ! -e $GCCPKG.tar.gz ]; then
        wget ftp://ftp.gnu.org/gnu/gcc/$GCCPKG/$GCCPKG.tar.gz
        tar xf $SRCDIR/$GCCPKG.tar.gz
        cd $SRCDIR/$GCCPKG
        ./contrib/download_prerequisites
    fi
    rm -rf $BUILDDIR/$GCCPKG/*
    mkdir -p $BUILDDIR/$GCCPKG

    cd $BUILDDIR/$GCCPKG
../../../src/$GCCPKG/configure --enable-languages=c,c++ --with-newlib $MULTILIB --disable-shared --disable-nls --enable-lto --enable-interwork --disable-thread  --disable-libgfortran -without-headers --disable-libstdcxx-pch --target=$TARGET --prefix=$PREFIXDIR -v 2>&1 | tee ${GCCPKG}-all_configure.log

    make all-gcc 2>&1 | tee ${GCCPKG}-all_make.log
    make install-gcc 2>&1 | tee ${GCCPKG}-all_install.log
fi

#---------------------------------------------------------------------------------
# Build and install newlib
#---------------------------------------------------------------------------------

if [ $SKIP_NEWLIB == 0 ]; then
    cd $SRCDIR
    if [ ! -e $NEWLIBPKG.tar.gz ]; then
        wget ftp://sourceware.org/pub/newlib/$NEWLIBPKG.tar.gz
        tar xf $SRCDIR/$NEWLIBPKG.tar.gz
        if [ $NEWLIBPKG == '2.4.0.20160923' ]; then
            cp $DEVDIR/$NEWLIBPKG.patch $SRCDIR
            patch -p1 -d $NEWLIBPKG < $NEWLIBPKG.patch
        fi
    fi
    rm -rf $BUILDDIR/$NEWLIBPKG/*
    mkdir -p $BUILDDIR/$NEWLIBPKG

    cd $BUILDDIR/$NEWLIBPKG
    ../../../src/$NEWLIBPKG/configure --prefix=$PREFIXDIR --target=$TARGET $MULTILIB --disable-shared --disable-libquadmath --disable-libada --disable-libssp $NEWLIB_NANO 2>&1 | tee ${NEWLIBPKG}_configure.log

    make 2>&1 | tee ${NEWLIBPKG}_make.log
    make install 2>&1 | tee ${NEWLIBPKG}_install.log
fi

#---------------------------------------------------------------------------------
# Build and install gcc
#---------------------------------------------------------------------------------

if [ $SKIP_GCC2 == 0 ]; then
    cd $SRCDIR
    cd $BUILDDIR/$GCCPKG
    ../../../$GCCPKG/configure --enable-languages=c,c++ --with-newlib $MULTILIB --disable-shared --disable-nls --enable-lto --enable-interwork --disable-thread --disable-libgfortran --target=$TARGET --prefix=$PREFIXDIR -v 2>&1 | tee ${GCCPKG}_configure.log
    make all 2>&1 | tee ${GCCPKG}_make.log
    make install 2>&1 | tee ${GCCPKG}_install.log
fi

#---------------------------------------------------------------------------------
# Build and install gdb
#---------------------------------------------------------------------------------

if [ $SKIP_GDB == 0 ]; then
    cd $SRCDIR
    if [ ! -e $GDBPKG.tar.gz ]; then
        wget http://ftp.gnu.org/gnu/gdb/$GDBPKG.tar.gz
        tar xf $SRCDIR/$GDBPKG.tar.gz
    fi

    rm -rf $BUILDDIR/$GDBPKG/*
    mkdir -p $BUILDDIR/$GDBPKG

    cd $BUILDDIR/$GDBPKG
    ../../../src/$GDBPKG/configure --prefix=$PREFIXDIR --target=$TARGET --disable-shared --disable-nls 2>&1 | tee ${GDBPKG}_configure.log

    make 2>&1 | tee ${GDBPKG}_make.log
    make install 2>&1 | tee ${GDBPKG}_install.log
fi
