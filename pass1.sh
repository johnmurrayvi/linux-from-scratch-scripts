#!/bin/bash

LFS_TGT=$(uname -m)-lfs-linux-gnu


testToolchain () 
{
	echo 'main(){}' > dummy.c
	cc dummy.c
	TCT=$(readelf -l a.out | grep ': /tools')
	echo "toolchain test: "
	if [ -n "$TCT" ] ; then
		echo "$TCT"
		echo "passed"
		rm -v dummy.c a.out
	else 
		echo "failed"
		exit 1;
	fi
}



##########################
# Binutils 2.22 - Pass 1 #
##########################

tar -jxf binutils-2.22.tar.bz2

mkdir -v binutils-build
cd binutils-build

../binutils-2.22/configure \
	--target=$LFS_TGT --prefix=/tools \
	--disable-nls --disable-werror

make -j4

case $(uname -m) in
	x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
esac

make install

cd ..
rm -rf binutils-build binutils-2.22



######################
# GCC 4.6.2 - Pass 1 #
######################

tar -jxf gcc-4.6.2.tar.bz2
cd gcc-4.6.2

tar -jxf ../mpfr-3.1.0.tar.bz2
mv -v mpfr-3.1.0 mpfr
tar -Jxf ../gmp-5.0.4.tar.xz
mv -v gmp-5.0.4 gmp
tar -zxf ../mpc-0.9.tar.gz
mv -v mpc-0.9 mpc

patch -Np1 -i ../gcc-4.6.2-cross_compile-1.patch

mkdir -v ../gcc-build
cd ../gcc-build

../gcc-4.6.2/configure \
    --target=$LFS_TGT --prefix=/tools \
    --disable-nls --disable-shared --disable-multilib \
    --disable-decimal-float --disable-threads \
    --disable-libmudflap --disable-libssp \
    --disable-libgomp --disable-libquadmath \
    --disable-target-libiberty --disable-target-zlib \
    --enable-languages=c --without-ppl --without-cloog \
    --with-mpfr-include=$(pwd)/../gcc-4.6.2/mpfr/src \
    --with-mpfr-lib=$(pwd)/mpfr/src/.libs

make -j4
make install
ln -vs libgcc.a `$LFS_TGT-gcc -print-libgcc-file-name | \
	sed 's/libgcc/&_eh/'`

cd ..
rm -rf gcc-build gcc-4.6.2



###########################
# Linux 3.2.6 API Headers #
###########################

tar -zxf linux-3.2.6.tar.gz
cd linux-3.2.6

make mrproper
make INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* /tools/include

cd ..
rm -rf linux-3.2.6



#########################
# Glibc 2.14.1 - Pass 1 #
#########################

tar -jxf glibc-2.14.1.tar.bz2 
cd glibc-2.14.1

patch -Np1 -i ../glibc-2.14.1-gcc_fix-1.patch
patch -Np1 -i ../glibc-2.14.1-cpuid-1.patch

mkdir -v ../glibc-build
cd ../glibc-build

../glibc-2.14.1/configure --prefix=/tools \
	--host=$LFS_TGT --build=$(../glibc-2.14.1/scripts/config.guess) \
	--disable-profile --enable-add-ons \
	--enable-kernel=2.6.25 --with-headers=/tools/include \
	libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes

make -j4
make install

cd ..
rm -rf glibc-build glibc-2.14.1



####################
# Adjust Toolchain #
####################

SPECS=`dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/specs
$LFS_TGT-gcc -dumpspecs | sed \
  -e 's@/lib\(64\)\?/ld@/tools&@g' \
  -e "/^\*cpp:$/{n;s,$, -isystem /tools/include,}" > $SPECS 
echo "New specs file is: $SPECS"
unset SPECS

## Test for proper toolchain functioning

testToolchain
