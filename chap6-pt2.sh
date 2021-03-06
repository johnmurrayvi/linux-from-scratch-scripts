#!/bin/bash

# in chroot environment now

# make file system hierarchy

mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib,mnt,opt,run}
mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -v /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -v /usr/{local,share}/games

for dir in /usr /usr/local ; do 
	ln -sv share/{man,doc,info} $dir
done

case $(uname -m) in
	x86_64) ln -sv lib /lib64 && ln -sv lib /usr/lib64 ;;
esac

mkdir -v /var/{log,mail,spool}
ln -sv /run /var/run
ln -sv /run/lock /var/lock

mkdir -pv /var/{opt,cache,lib/{misc,locale},local}


# create essential files and symlinks

ln -sv /tools/bin/{bash,cat,echo,pwd,stty} /bin
ln -sv /tools/bin/perl /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib
sed 's/tools/usr/' /tools/lib/libstdc++.la > /usr/lib/libstdc++.la
ln -sv bash /bin/sh

touch /etc/mtab

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:3:
tty:x:4:
tape:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
mail:x:34:
nogroup:x:99:
EOF

exec /tools/bin/bash --login +h

touch /var/run/utmp /var/log/{btmp,lastlog,wtmp}
chgrp -v utmp /var/run/utmp /var/log/lastlog 
chmod -v 664 /var/run/utmp /var/log/lastlog 
chmod -v 600 /var/log/btmp 


## Time to install a lot of pacakages

cd sources/

###############
# Linux 3.2.6 #
###############

tar xf linux-3.2.6.tar.xz 
cd linux-3.2.6
make mrproper
make headers_check
make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include/
cd ..
rm -rf linux-3.2.6


##################
# Man Pages 3.35 #
##################

tar xf man-pages-3.35.tar.gz 
cd man-pages-3.35
make install
man pages
man
man
cd ..
rm -rf man-pages-3.35


################
# Glibc 2.14.1 #
################

tar jxf glibc-2.14.1.tar.bz2 
cd glibc-2.14.1
DL=$(readelf -l /bin/sh | sed -n 's@.*interpret.*/tools\(.*\)]$@\1@p')
sed -i "s|libs -o|libs -L/usr/lib -Wl,-dynamic-linker=$DL -o|" \
	scripts/test-installation.pl
unset DL
sed -i -e 's/"db1"/& \&\& $name ne "nss_test1"/' scripts/test-installation.pl
sed -i 's|@BASH@|/bin/bash|' elf/ldd.bash.in
patch -Np1 -i ../glibc-2.14.1-fixes-1.patch
patch -Np1 -i ../glibc-2.14.1-sort-1.patch 
patch -Np1 -i ../glibc-2.14.1-gcc_fix-1.patch
sed -i '195,213 s/PRIVATE_FUTEX/FUTEX_CLOCK_REALTIME/' \
	nptl/sysdeps/unix/sysv/linux/x86_64/pthread_rwlock_timed{rd,wr}lock.S
mkdir -v ../glibc-build
cd ../glibc-build/
../glibc-2.14.1/configure --prefix=/usr \
	--disable-profile --enable-add-ons \
	--enable-kernel=2.6.25 --libexecdir=/usr/lib/glibc
make
cp -v ../glibc-2.14.1/iconvdata/gconv-modules iconvdata
make -k check 2>&1 | tee glibc-check-log
grep Error glibc-check-log
touch /etc/ld.so.conf
make install
cp -v ../glibc-2.14.1/sunrpc/rpc/*.h /usr/include/rpc
cp -v ../glibc-2.14.1/sunrpc/rpcsvc/*.h /usr/include/rpcsvc
cp -v ../glibc-2.14.1/nis/rpcsvc/*.h /usr/include/rpcsvc

mkdir -pv /usr/lib/locale
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030


# /etc/nsswitch.conf

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tzselect
cp -v --remove-destination /usr/share/zoneinfo/America/New_York /etc/localtime

# /etc/ld.so.conf 

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

# optional include dir

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF

mkdir -v /etc/ld.so.conf.d


######################
# readjust toolchain #
######################

mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(gcc -dumpmachine)/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld
gcc -dumpspecs | sed -e 's@/tools@@g' \
	-e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
	-e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' \
	> `dirname $(gcc --print-libgcc-file-name)`/specs
dirname $(gcc --print-libgcc-file-name)
cat /tools/lib/gcc/x86_64-unknown-linux-gnu/4.6.2/specs 
echo 'main(){}' > dummy.c
cc dummy.c -v -W1,--verbose &> dummy.lo
readelf -l a.out | grep ': /lib'
which cc
cc
ls
cat dummy.log 
echo 'main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
rm dummy.* a.out 
echo 'main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
grep -o '/usr/lib.*/crt[lin].*succeeded' dummy.log 
grep -Bl '^ /usr/include' dummy.log 
grep -B1 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log | sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log 
grep found dummy.log 
rm -v a.out dummy.c dummy.log 


cd ..
rm -rf glibc-build/ glibc-2.14.1

##############
# zlib 1.2.6 #
##############

tar xf zlib-1.2.6.tar.bz2 
cd zlib-1.2.6
./configure --prefix=/usr
make
make check
make install
mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/libz.so.1.2.6 /usr/lib/libz.so 
cd ..
rm -rf zlib-1.2.6


#############
# file 5.10 #
#############

tar xf file-5.10.tar.gz 
cd file-5.10
./configure --prefix=/usr
make
make check
make install
cd ..
rm -rf file-5.10


#################
# binutils 2.22 #
#################

tar xf binutils-2.22.tar.bz2 
cd binutils-2.22
expect -c "spawn ls"
rm -fv etc/standards.info 
sed -i.bak '/^INFO/s/standards.info //' etc/Makefile.in 
sed -i "/exception_defines.h/d" ld/testsuite/ld-elf/new.cc 
sed -i "s/-fvtable-gc //" ld/testsuite/ld-selective/selective.exp 
mkdir -v ../binutils-build
cd ../binutils-build/
../binutils-2.22/configure --prefix=/usr --enable-shared
make tooldir=/usr
make -k check
make tooldir=/usr install
cp ../binutils-2.22/include/libiberty.h /usr/include/
cd ..
rm -rf binutils-build/ binutils-2.22


#############
# gmp 5.0.4 #
#############

tar xf gmp-5.0.4.tar.xz 
cd gmp-5.0.4
./configure --prefix=/usr --enable-cxx --enable-mpbsd
make
make check 2>&1 | tee gmp-check-log
awk '/tests passed/{total+=$2} ; END{print total}' gmp-check-log
make install
mkdir -v /usr/share/doc/gmp-5.0.4
cp -v doc/{isa_abi_headache,configuration} doc/*.html /usr/share/doc/gmp-5.0.4
cd ..
rm -rf gmp-5.0.4


##############
# mpfr 3.1.0 #
##############

tar xf mpfr-3.1.0.tar.bz2 
cd mpfr-3.1.0
patch -Np1 ../mpfr-3.1.0-fixes-1.patch 
patch -Np1 -i ../mpfr-3.1.0-fixes-1.patch
./configure --prefix=/usr --enable-thread-safe --docdir=/usr/share/doc/mpfr-3.1.0
make
make check
make install
make html
make install-html
cd ..
rm -rf mpfr-3.1.0


###########
# mpc 0.9 #
###########

tar xf mpc-0.9.tar.gz 
cd mpc-0.9
./configure --prefix=/usr
make
make check
make install
cd ..
rm -rf mpc-0.9


#############
# gcc 4.6.2 #
#############

tar xf gcc-4.6.2.tar.bz2 
cd gcc-4.6.2
sed -i 's/install_to_$(INSTALL_DIR) //' libiberty/Makefile.in 
case `uname -m` in
	i?86) sed -i 's/^T_CFLAGS =$/& -fomit-frame-pointer/' gcc/Makefile.in ;; 
esac
sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in 
mkdir ../gcc-build
cd ../gcc-build/
../gcc-4.6.2/configure --prefix=/usr --libexecdir=/usr/lib --enable-shared \
	--enable-threads=posix --enable-__cxa_atexit --enable-clocale=gnu \
	--enable-languages=c,c++ --disable-multilib --disable-bootstrap --with-system-zlib
make
ulimit -s 16384
make -k check
grep -A7 Summ
../gcc-4.6.2/contrib/test_summary | grep -A7 Summ
make install
ln -sv ../../usr/bin/cpp /lib
rm /lib/cpp 
ln -sv ../usr/bin/cpp /lib
ln -sv gcc /usr/bin/cc
echo 'main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
grep -B4 '^ /usr/include' dummy.log 
grep 'SEARCH.*/usr/lib' dummy.log | sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log 
grep found dummy.log 
rm -v dummy.* a.out 
dirname $(gcc --print-libgcc-file-name)
cd /usr/lib/gcc/x86_64-unknown-linux-gnu/4.6.2/
cd /sources/
rm -rf gcc-build gcc-4.6.2 


#############
# sed 4.2.1 #
#############

tar xf sed-4.2.1.tar.bz2 
cd sed-4.2.1
./configure --prefix=/usr --bindir=/bin --htmldir=/usr/share/doc/sed-4.2.1
make
make html
make check
make install
make -C doc install-html
cd ..
rm -rf sed-4.2.1


##############
# bzip 1.0.6 #
##############

tar xf bzip2-1.0.6.tar.gz 
cd bzip2-1.0.6
patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch 
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
make -f Makefile-libbz2_so 
make
make PREFIX=/usr install
cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat
cd ..
rm -rf bzip2-1.0.6


###############
# ncurses 5.9 #
###############

tar xf ncurses-5.9.tar.gz 
cd ncurses-5.9
./configure --prefix=/usr --with-shared --without-debug --enable-widec
make
make install
mv -v /usr/lib/libncursesw.so.5* /lib
ln -sfv ../../lib/libncursesw.so.5 /usr/lib/libncursesw.so 

for lib in ncurses form panel menu ; do
	rm -vf /usr/lib/lib${lib}.so
	echo "INPUT(-l${lib}w)" >/usr/lib/lib${lib}.so
	ln -sfv lib${lib}w.a /usr/lib/lib${lib}.a
done

ln -sfv libncurses++w.a /usr/lib/libncurses++w.a 
rm -vf /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so /usr/lib/libcurses.so
ln -sfv libncursesw.a /usr/lib/libcursesw.a
ln -sfv libncurses.a /usr/lib/libcurses.a
mkdir -v /usr/share/doc/ncurses-5.9
cp -v -R doc/* /usr/share/doc/ncurses-5.9
make distclean
./configure --prefix=/usr --with-shared --without-normal \
	--without-debug --without-cxx-binding
make sources libs
cp -av lib/lib*.so.5* /usr/lib
cd ..
rm -rf ncurses-5.9


#####################
# util-linux 2.20.1 #
#####################

tar xf util-linux-2.20.1.tar.bz2 
cd util-linux-2.20.1
sed -e 's@etc/adjtime@var/lib/hwclock/adjtime@g' -i $(grep -rl '/etc/adjtime' .)
mkdir -pv /var/lib/hwclock
./configure --enable-arch --enable-partx --enable-write
make
make install
cd ..
rm -rf util-linux-2.20.1

################
# psmisc 22.15 #
################

tar xf psmisc-22.15.tar.gz 
cd psmisc-22.15
./configure --prefix=/usr
make
make install
mv -v /usr/bin/fuser /bin
mv -v /usr/bin/killall /bin
cd ..
rm -rf psmisc-22.15


##################
# e2fsprogs 1.42 #
##################

tar xf e2fsprogs-1.42.tar.gz 
cd e2fsprogs-1.42
mkdir build
cd build/
PKG_CONFIG=/tools/bin/true LDFLAGS="-lblkid -luuid" \
	../configure --prefix=/usr --with-root-prefix=/ \
	--enable-elf-shlibs --disable-libblkid \
	--disable-libuuid --disable-uuidd --disable-fsck
make
make check
make install
make install-libs
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz 
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info 
makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo 
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info 
cd ../../
rm -rf e2fsprogs-1.42


##################
# coreutils 8.15 #
##################

tar xf coreutils-8.15.tar.xz 
cd coreutils-8.15
patch -Np1 -i ../coreutils-8.15-uname-1.patch 
patch -Np1 -i ../coreutils-8.15-i18n-1.patch 
./configure --prefix=/usr --libexecdir=/usr/lib --enable-no-install-program=kill,uptime
make
make install
mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
mv -v /usr/bin/{head,sleep,nice} /bin
cd ..
rm -rf coreutils-8.15


#################
# iana-etc 2.30 #
#################

tar xf iana-etc-2.30.tar.bz2 
cd iana-etc-2.30
make
make install
cd ..
rm -rf iana-etc-2.30


#############
# m4 1.4.16 #
#############

tar xf m4-1.4.16.tar.bz2 
cd m4-1.4.16
./configure --prefix=/usr
make
sed -i -e '41s/ENOENT/& || errno == EINVAL/' tests/test-readlink.h
make check
make install
cd ..
rm -rf m4-1.4.16


#############
# bison 2.5 #
#############

tar xf bison-2.5.tar.bz2 
cd bison-2.5
./configure --prefix=/usr
echo '#define YYENABLE_NLS 1' >> lib/config.h
make
make check
make install
cd ..
rm -rf bison-2.5


################
# procps 3.2.8 #
################

tar xf procps-3.2.8.tar.gz 
cd procps-3.2.8
patch -Np1 -i ../procps-3.2.8-fix_HZ_errors-1.patch 
patch -Np1 -i ../procps-3.2.8-watch_unicode-1.patch 
sed -i -e 's@\*/module.mk@proc/module.mk ps/module.mk@' Makefile 
make
make install
cd ..
rm -rf procps-3.2.8


#############
# grep 2.10 #
#############

tar xf grep-2.10.tar.xz 
cd grep-2.10
sed -i 's/cp/#&/' tests/unibyte-bracket-expr 
./configure --prefix=/usr --bindir=/bin
make
make check
make install
cd ..
rm -rf grep-2.10


################
# readline 6.2 #
################

tar xf readline-6.2.tar.gz 
cd readline-6.2
sed -i '/MV.*old/d' Makefile.in 
sed -i '/{OLDSUFF}/c:' support/shlib-install 
patch -Np1 -i ../readline-6.2-fixes-1.patch 
./configure --prefix=/usr --libdir=/lib
make SHLIB_LIBS=-lncurses
make install
mv -v /usr/lib{readline,history}.a /usr/lib
mv -v /lib/lib{readline,history}.a /usr/lib
rm -v /lib/lib{readline,history}.so 
ln -sfv ../../lib/libreadline.so.6 /usr/lib/libreadline.so
ln -sfv ../../lib/libhistory.so.6 /usr/lib/libhistory.so
mkdir -v /usr/share/doc/readline-6.2
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-6.2
cd ..
rm -rf readline-6.2


############
# bash 4.2 #
############

tar xf bash-4.2.tar.gz 
cd bash-4.2
patch -Np1 -i ../bash-4.2-fixes-4.patch 
./configure --prefix=/usr --bindir=/bin \
	--htmldir=/usr/share/doc/bash-4.2 --without-bash-malloc \
	--with-installed-readline
make
make install
exec /bin/bash --login +h
cd ..
rm -rf bash-4.2


#################
# libtool 2.4.2 #
#################

tar xf libtool-2.4.2.tar.gz 
cd libtool-2.4.2
./configure --prefix=/usr
make
make check
make install
cd ..
rm -rf libtool-2.4.2


#############
# gdbm 1.10 #
#############

tar xf gdbm-1.10.tar.gz 
cd gdbm-1.10
./configure --prefix=/usr --enable-libgdbm-compat
make
make check
make install
cd ..
rm -rf gdbm-1.10


###################
# inetutils 1.9.1 #
###################

tar xf inetutils-1.9.1.tar.gz 
cd inetutils-1.9.1
./configure --prefix=/usr --libexecdir=/usr/sbin \
	--localstatedir=/var --disable-ifconfig \
	--disable-logger --disable-syslogd \
	--disable-whois --disable-servers
make
make check
make install
make -C doc html
make -C doc install-html docdir=/usr/share/doc/inetutils-1.9.1
mv -v /usr/bin/{hostname,ping,ping6} /bin
mv -v /usr/bin/traceroute /sbin
cd ..
rm -rf inetutils-1.9.1


###############
# Perl 5.14.2 #
###############

tar xf perl-5.14.2.tar.bz2 
cd perl-5.14.2
patch -Np1 -i ../perl-5.14.2-security_fix-1.patch 
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
sed -i -e "s|BUILD_ZLIB\s*= True|BUILD_ZLIB = False|" \
	-e "s|INCLUDE\s*= ./zlib-src|INCLUDE = /usr/include|" \
	-e "s|LIB\s*= ./zlib-src|LIB = /usr/lib|" cpan/Compress-Raw-Zlib/config.in
sh Configure -des -Dprefix=/usr \
	-Dvendorprefix=/usr \
	-Dman1dir=/usr/share/man/man1 \
	-Dman3dir=/usr/share/man/man3 \
	-Dpager="/usr/bin/less -isR" \
	-Duseshrplib
make
make test
make install
cd ..
rm -rf perl-5.14.2


#################
# Autoconf 2.68 #
#################

tar xf autoconf-2.68.tar.bz2 
cd autoconf-2.68
./configure --prefix=/usr
make
make check
make install
cd ..
rm -rf autoconf-2.68


###################
# Automake 1.11.3 #
###################

tar xf automake-1.11.3.tar.xz 
cd automake-1.11.3
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.11.3
make
make check
cat tests/test-suite.log  | grep FAIL
make install
cd ..
rm -rf automake-1.11.3


#################
# Diffutils 3.2 #
##############$$$

tar xf diffutils-3.2.tar.gz 
cd diffutils-3.2
./configure --prefix=/usr
make
make check
make install
cd ..
rm -rf diffutils-3.2


##############
# Gawk 4.0.0 #
##############

tar xf gawk-4.0.0.tar.bz2 
cd gawk-4.0.0
./configure --prefix=/usr --libexecdir=/usr/lib
make
make check
make install
mkdir -v /usr/share/doc/gawk-4.0.0
cp -v doc/{awkforia.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-4.0.0
cd ..
rm -rf gawk-4.0.0


###################
# Findutils 4.4.2 #
###################

tar xf findutils-4.4.2.tar.gz 
cd findutils-4.4.2
./configure --prefix=/usr --libexecdir=/usr/lib/findutils --localstatedir=/var/lib/locate
make
make check
make install
mv -v /usr/bin/find /bin
sed -i 's/find:=${BINDIR}/find:=\/bin/' /usr/bin/updatedb 
cd ..
rm -rf findutils-4.4.2


###############
# Flex 2.5.35 #
###############

tar xf flex-2.5.35.tar.bz2 
cd flex-2.5.35
patch -Np1 -i ../flex-2.5.35-gcc44-1.patch 
./configure --prefix=/usr
make
make check
make install
ln -sv libfl.a /usr/lib/libl.a

cat /usr/bin/lex << "EOF"
#!/bin/sh
# Begin /usr/bin/lex

exec /usr/bin/flex -l "$@"

# End /usr/bin/lex
EOF

chmod -v 755 /usr/bin/lex
mkdir -v /usr/share/doc/flex-2.5.35
cp -v doc/flex.pdf /usr/share/doc/flex-2.5.35/
cd ..
rm -rf flex-2.5.35


####################
# Gettext 0.18.1.1 #
####################

tar xf gettext-0.18.1.1.tar.gz 
cd gettext-0.18.1.1
./configure --prefix=/usr --docdir=/usr/share/doc/gettext-0.18.1.1
make
make check
make install
cd ..
rm -rf gettext-0.18.1.1


##############
# Groff 1.21 #
##############

tar xf groff-1.21.tar.gz 
cd groff-1.21
PAGE=letter ./configure --prefix=/usr
make
make install
ln -sv eqn /usr/bin/geqn
ln -sv tbl /usr/bin/gtbl
cd ..
rm -rf groff-1.21


############
# Xz 5.0.3 #
############

tar xf xz-5.0.3.tar.bz2 
cd xz-5.0.3
./configure --prefix=/usr --libdir=/lib --docdir=/usr/share/doc/xz-5.0.3
make
make check
make pkgconfigdir=/usr/lib/pkgconfig install
cd ..
rm -rf xz-5.0.3


#############
# Grub 1.99 #
#############

tar xf grub-1.99.tar.gz 
cd grub-1.99
./configure --prefix=/usr --sysconfdir=/etc --disable-grub-emu-usb --disable-efiemu --disable-werror
make
make install
cd ..
rm -rf grub-1.99


############
# Gzip 1.4 #
############

tar xf gzip-1.4.tar.gz 
cd gzip-1.4
./configure --prefix=/usr --bindir=/bin
make
make check
make install
mv -v /bin/{gzexe,uncompress,zcmp,zdiff,zegrep} /usr/bin
mv -v /bin/{zfgrep,zforce,zgrep,zless,zmore,znew} /usr/bin/
cd ..
rm -rf gzip-1.4


#################
# IProute 3.2.0 #
#################

tar xf iproute2-3.2.0.tar.xz 
cd iproute2-3.2.0
sed -i '/^TARGETS/s@arpd@@g' misc/Makefile 
sed -i /ARPD/d Makefile 
rm man/man8/arpd.8 
sed -i -e '/netlink\//d' ip/ipl2tp.c 
make DESTDIR=
make DESTDIR= MANDIR=/usr/share/man DOCDIR=/usr/share/doc/iproute2-3.2.0 install
cd ..
rm -rf iproute2-3.2.0


##############
# Kbd 1.15.2 #
##############

tar xf kbd-1.15.2.tar.gz 
cd kbd-1.15.2
patch -Np1 -i ../kbd-1.15.2-backspace-1.patch 
./configure --prefix=/usr --datadir=/lib/kbd
make
make install
mv -v /usr/bin/{kbd_mode,loadkeys,openvt,setfont} /bin
mkdir -v /usr/share/doc/kbd-1.15.2
cp -R -v doc/* /usr/share/doc/kbd-1.15.2/
cd ..
rm -rf kbd-1.15.2


##########
# Kmod 5 #
##########

tar xf kmod-5.tar.xz 
cd kmod-5
liblzma_CFLAGS="-I/usr/include" liblzma_LIBS="-L/lib -llzma" zlib_CFLAGS="-I/usr/include" zlib_LIBS="-L/lib -lz" ./configure --prefix=/usr --bindir=/bin --libdir=/lib --sysconfdir=/etc --with-xz --with-zlib
make
make check
make pkgconfigdir=/usr/lib/pkgconfig install

for target in depmod insmod modinfo modprobe rmmod; do
	ln -sv ../bin/kmod /sbin/$target
done

ln -sv kmod /bin/lsmod
cd ..
rm -rf kmod-5


#############
# Less 4.44 #
#############

tar xf less-444.tar.gz 
cd less-444
./configure --prefix=/usr --sysconfdir=/etc
make
make install
cd ..
rm -rf less-444


#####################
# Libpipeline 1.2.0 #
#####################

tar xf libpipeline-1.2.0.tar.gz 
cd libpipeline-1.2.0
./configure CHECK_CFLAGS=-I/tools/include CHECK_LIBS="-L/tools/lib -lcheck" --prefix=/usr
make
make check
make install
cd ..
rm -rf libpipeline-1.2.0


#############
# Make 3.82 #
#############

tar xf make-3.82.tar.bz2 
cd make-3.82
./configure --prefix=/usr
make
make check
make install
cd ..
rm -rf make-3.82


################
# Man DB 2.6.1 #
################

tar xf man-db-2.6.1.tar.gz 
cd man-db-2.6.1
PKG_CONFIG=/tools/bin/true libpipeline_CFLAGS='' libpipeline_LIBS='-lpipeline' \
	./configure --prefix=/usr --libexecdir=/usr/lib --docdir=/usr/share/doc/man-db-2.6.1 \
	--sysconfdir=/etc --disable-setuid --with-browser=/usr/bin/lynx \
	--with-vgrind=/usr/bin/vgrind --with-grap=/usr/bin/grap
make
make check
make install
cd ..
rm -rf man-db-2.6.1


###############
# Patch 2.6.1 #
###############

tar xf patch-2.6.1.tar.bz2 
cd patch-2.6.1
patch -Np1 -i ../patch-2.6.1-test_fix-1.patch 
./configure --prefix=/usr
make 
make check
make install
cd ..
rm -rf patch-2.6.1


################
# Shadow 4.1.5 #
################

tar xf shadow-4.1.5.tar.bz2 
cd shadow-4.1.5
patch -Np1 -i ../shadow-4.1.5-nscd-1.patch 
sed -i 's/groups$(EXEEXT) //' src/Makefile.in 
find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
	-e 's@/var/spool/mail@/var/mail@' etc/login.defs 
./configure --sysconfdir=/etc
make
make install
mv -v /usr/bin/passwd /bin
cd ..
pwconv
grpconv
sed -i 's/yes/no/' /etc/default/useradd 
passwd root
cd ..
rm -rf shadow-4.1.5


################
# Sysklogd 1.5 #
################

tar xf sysklogd-1.5.tar.gz 
cd sysklogd-1.5
make
make BINDIR=/sbin install

cat > /etc/syslog.conf << "EOF"
auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

EOF

cd ..
rm -rf sysklogd-1.5


####################
# SysVinit 2.88dsf #
####################

tar xf sysvinit-2.88dsf.tar.bz2 
cd sysvinit-2.88dsf
sed -i 's@Sending processes@& configured via /etc/inittab@g' src/init.c 
sed -i -e 's/utmpdump wall/utmpdump/' \
	-e '/= mountpoint/d' -e 's/mountpoint.1 wall.1//' src/Makefile 
make -C src
make -C src install
cd ..
rm -rf sysvinit-2.88dsf


############
# Tar 1.26 #
############

tar xf tar-1.26.tar.bz2 
cd tar-1.26
FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr --bindir=/bin --libexecdir=/usr/sbin
make
make check
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.2.6
cd ..
rm -rf tar-1.26


##################
# Textinfo 4.13a #
##################

tar xf texinfo-4.13a.tar.gz 
cd texinfo-4.13
./configure --prefix=/usr
make
make check
make install
make TEXMF=/usr/share/texmf install-tex

cat > /usr/bin/update-infodoc << "EOF"
cd /usr/share/info
rm -v dir
for f in * ; do 
install-info $f dir 2>/dev/null
done
EOF

cd ..
rm -rf texinfo-4.13


##############
# Udev 1.8.1 #
##############

tar xf udev-181.tar.xz 
cd udev-181
tar xf ../udev-config-20100128.tar.bz2 
install -dv /lib/{firmware,udev/device/pts}
mknod -m0666 /lib/udev/device/null c 1 3
BLKID_CFLAGS="-I/usr/include/blkid" BLKID_LIBS="-L/lib -lblkid" \
	KMOD_CFLAGS="-I/usr/include" KMOD_LIBS="-L/lib -lkmod" ./configure \
	--prefix=/usr --with-rootprefixe='' --bindir=/sbin --sysconfdir=/etc \
	--libexecdir=/lib --enable-rule-generator --disable-introspection \
	--disable-keymap --disable-gudev --with-usb-ids-path=no \
	--with-pci-ids-path=no --with-systemdsystemunitdir=no
make
make check
make install
rmdir -v /usr/share/doc/udev/
cd udev-config-20100128/
make install
make install-doc
cd ../../
rm -rf udev-181


###########
# Vim 7.3 #
###########

tar xf vim-7.3.tar.bz2 
cd vim73/
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h 
./configure --prefix=/usr --enable-multibyte
make test
make install
ln -sv vim /usr/bin/vi

for L in  /usr/share/man/{,*/}man1/vim.1; do
	ln -sv vim.1 $(dirname $L)/vi.1
done

ln -sv ../vim/vim73/doc /usr/share/doc/vim-7.3

cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

set nocompatible
set backspace=2
syntax on
if (&term == "iterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

cd ..
rm -rf vim73/


# Done with /tools directory #

cd /
rm -rf /tools
