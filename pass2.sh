#!/bin/bash

LFS_TGT=$(uname -m)-lfs-linux-gnu
LFS=/mnt/lfs


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
# Binutils 2.22 - Pass 2 #
##########################

tar -jxf binutils-2.22.tar.bz2

mkdir -v binutils-build
cd binutils-build

CC="$LFS_TGT-gcc -B/tools/lib/" \
	AR=$LFS_TGT-ar RANLIB=$LFS_TGT-ranlib \
	../binutils-2.22/configure --prefix=/tools \
	--disable-nls --with-lib-path=/tools/lib

make -j4
make install

make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin

cd ..
rm -rf binutils-build binutils-2.22


######################
# GCC 4.6.2 - Pass 2 #
######################

tar jxf gcc-4.6.2.tar.bz2
cd gcc-4.6.2

## Apply startfiles patch
patch -Np1 -i ../gcc-4.6.2-startfiles_fix-1.patch


cp -v gcc/Makefile.in{,.orig}
sed 's@\./fixinc\.sh@-c true@' gcc/Makefile.in.orig > gcc/Makefile.in

cp -v gcc/Makefile.in{,.tmp}
sed 's/^T_CFLAGS =$/& -fomit-frame-pointer/' gcc/Makefile.in.tmp > gcc/Makefile.in

for file in \
	$(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
	cp -uv $file{,.orig}
	sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
	-e 's@/usr@/tools@g' $file.orig > $file
	echo '
#undef STANDARD_INCLUDE_DIR
#define STANDARD_INCLUDE_DIR 0
#define STANDARD_STARTFILE_PREFIX_1 ""
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
	touch $file.orig
done

case $(uname -m) in
	x86_64)
		for file in $(find gcc/config -name t-linux64) ; do \
			cp -v $file{,.orig}
			sed '/MULTILIB_OSDIRNAMES/d' $file.orig > $file
		done
	;;
esac

tar -jxf ../mpfr-3.1.0.tar.bz2
mv -v mpfr-3.1.0 mpfr
tar -Jxf ../gmp-5.0.4.tar.xz
mv -v gmp-5.0.4 gmp
tar -zxf ../mpc-0.9.tar.gz
mv -v mpc-0.9 mpc

mkdir -v ../gcc-build
cd ../gcc-build

CC="$LFS_TGT-gcc -B/tools/lib/" \
    AR=$LFS_TGT-ar RANLIB=$LFS_TGT-ranlib \
    ../gcc-4.6.2/configure --prefix=/tools \
    --with-local-prefix=/tools --enable-clocale=gnu \
    --enable-shared --enable-threads=posix \
    --enable-__cxa_atexit --enable-languages=c,c++ \
    --disable-libstdcxx-pch --disable-multilib \
    --disable-bootstrap --disable-libgomp \
    --without-ppl --without-cloog \
    --with-mpfr-include=$(pwd)/../gcc-4.6.2/mpfr/src \
    --with-mpfr-lib=$(pwd)/mpfr/src/.libs

make -j4
make install
ln -vs gcc /tools/bin/cc

rm -rf gcc-build gcc-4.6.2


## Test for proper tool chain execution

testToolchain

############################
#                          #
#   Build other packages   #
#                          #
############################

##############
# Tcl 8.5.11 #
##############
tar xzf tcl8.5.11-src.tar.gz 
cd tcl8.5.11
cd unix/

./configure --prefix=/tools
make -j4
TZ=UTC make test
make install

chmod -v u+w /tools/lib/libtcl8.5.so 
make install-private-headers
ln -sv tclsh8.5 /tools/bin/tclsh

cd ../../
rm -rf tcl8.5.11

###############
# Expect 5.45 #
###############
tar xf expect5.45.tar.gz 
cd expect5.45

cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure

./configure --prefix=/tools --with-tcl=/tools/lib --with-tclinclude=/tools/include
make -j4
make test
make SCRIPTS="" install

cd ..
rm -rf expect5.45

###############
# DejaGNU 1.5 #
###############
tar xf dejagnu-1.5.tar.gz 
cd dejagnu-1.5

./configure --prefix=/tools
make install
make check

cd ..
rm -rf dejagnu-1.5

###############
# Check 0.9.8 #
###############
tar xf check-0.9.8.tar.gz 
cd check-0.9.8

./configure --prefix=/tools
make -j4
make check
make install

cd ..
rm -rf check-0.9.8

###############
# Ncurses 5.9 #
###############

tar xf ncurses-5.9.tar.gz 
cd ncurses-5.9
./configure --prefix=/tools --with-shared --without-debug --without-ada --enable-overwrite
make -j4
make install
cd ..
rm -rf ncurses-5.9

############
# Bash 4.2 #
############

tar xf bash-4.2.tar.gz 
cd bash-4.2
patch -Np1 -i ../bash-4.2-fixes-4.patch 
./configure --prefix=/tools --without-bash-malloc
make -j4
make tests
make install
ln -sv bash /tools/bin/sh
cd ..
rm -rf bash-4.2

##############
# Bzip 1.0.6 #
##############

tar xf bzip2-1.0.6.tar.gz 
cd bzip2-1.0.6
make
make PREFIX=/tools install
cd ..
rm -rf bzip2-1.0.6

##################
# Coreutils 8.15 #
##################

tar xf coreutils-8.15.tar.xz 
cd coreutils-8.15
./configure --prefix=/tools --enable-install-program=hostname
make -j4
make install
cp -v src/su /tools/bin/su-tools
cd ..
rm -rf coreutils-8.15

#################
# Diffutils 3.2 #
#################

tar xf diffutils-3.2.tar.gz 
cd diffutils-3.2
./configure --prefix=/tools
make -j4
make install
cd ..
rm -rf diffutils-3.2

#############
# File 5.10 #
#############

tar xf file-5.10.tar.gz 
cd file-5.10
./configure --prefix=/tools
make -j4
make install
cd ..
rm -rf file-5.10 

###################
# Findutils 4.4.2 #
###################

tar xf findutils-4.4.2.tar.gz 
cd findutils-4.4.2
./configure --prefix=/tools
make -j4
make install
cd ..
rm -rf findutils-4.4.2

##############
# Gawk 4.0.0 #
##############

tar xf gawk-4.0.0.tar.bz2 
cd gawk-4.0.0
./configure --prefix=/tools
make -j4
make install
cd ..
rm -rf gawk-4.0.0

####################
# Gettext 0.18.1.1 #
####################

tar xf gettext-0.18.1.1.tar.gz 
cd gettext-0.18.1.1/gettext-tools
./configure --prefix=/tools --disable-shared
make -C gnulib-lib
make -C src msgfmt
cp -v src/msgfmt /tools/bin
cd ../../
rm -rf gettext-0.18.1.1

#############
# Grep 2.10 #
#############

tar xf grep-2.10.tar.xz 
cd grep-2.10
./configure --prefix=/tools --disable-perl-regexp
make -j4
make install
cd ..
rm -rf grep-2.10

############
# Gzip 1.4 #
############

tar xf gzip-1.4.tar.gz 
cd gzip-1.4
./configure --prefix=/tools
make -j4
make install
cd ..
rm -rf gzip-1.4

#############
# M4 1.4.16 #
#############

tar xf m4-1.4.16.tar.bz2 
cd m4-1.4.16
./configure --prefix=/tools
make -j4
make install
cd ..
rm -rf m4-1.4.16

#############
# make 3.82 #
#############

tar xf make-3.82.tar.bz2 
cd make-3.82
./configure --prefix=/tools
make -j4
make install
cd ..
rm -rf make-3.82

###############
# Patch 2.6.1 #
###############

tar xf patch-2.6.1.tar.bz2 
cd patch-2.6.1
./configure --prefix=/tools
make -j4
make install
cd ..
rm -rf patch-2.6.1

###############
# Perl 5.14.2 #
###############

tar xf perl-5.14.2.tar.bz2 
cd perl-5.14.2
patch -Np1 -i ../perl-5.14.2-libc-1.patch 
sh Configure -des -Dprefix=/tools
make -j4
cp -v perl cpan/podlators/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.14.2
cp -Rv lib/* /tools/lib/perl5/5.14.2
cd ..
rm -rf perl-5.14.2

#############
# Sed 4.2.1 #
#############

tar xf sed-4.2.1.tar.bz2 
cd sed-4.2.1
./configure --prefix=/tools
make -j4
make install
cd ..
rm -rf sed-4.2.1

############
# Tar 1.26 #
############

tar xf tar-1.26.tar.bz2 
cd tar-1.26
./configure --prefix=/tools
make -j4
make install
cd ..
rm -rf tar-1.26

#################
# Texinfo 4.13a #
#################

tar xf texinfo-4.13a.tar.gz 
cd texinfo-4.13
./configure --prefix=/tools
make -j4
make install
cd ..
rm -rf texinfo-4.13

############
# Xz 5.0.3 #
############

tar xf xz-5.0.3.tar.bz2 
cd xz-5.0.3
./configure --prefix=/tools
make -j4
make install
cd ..
rm -rf xz-5.0.3


## [Optionally] Strip extra debugging symbols and documentation

#strip --strip-debug /tools/lib*
#strip --strip-unneeded /tools/{,s}bin/*

#rm -rf /tools/{,share}/{info,man,doc}

## Change ownership of tools dir to root
#chown -R root:root $LFS/tools
