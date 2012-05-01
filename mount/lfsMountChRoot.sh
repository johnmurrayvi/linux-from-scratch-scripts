#!/bin/bash

LFS=/mnt/lfs

if [ ! -d $LFS ] ; then
	sudo mkdir $LFS
fi
sudo mount -v -t ext3 /dev/sdb5 $LFS

i=6 # sdb?+1 from above
for dir in boot home usr usr/src opt ; do
	if [ ! -d $LFS/$dir ] ; then
		sudo mkdir $LFS/$dir
	fi
	sudo mount -v -t ext3 /dev/sdb$i $LFS/$dir
	let "i+=1"
done

# mount necessary fs dirs
sudo mount -v --bind /dev $LFS/dev
sudo mount -vt devpts devpts $LFS/dev/pts
sudo mount -vt tmpfs shm $LFS/dev/shm
sudo mount -vt proc proc $LFS/proc
sudo mount -vt sysfs sysfs $LFS/sys

# assume the tools directory is deleted for non-tools PATH option
if [ -d $LFS/tools ] ; then
	sudo chroot "$LFS" /tools/bin/env -i HOME=/root \
		TERM="$TERM" PS1='\u:\w\$ ' \
		PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
		/tools/bin/bash --login +h
else
	sudo chroot "$LFS" /usr/bin/env -i \
		HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
		PATH=/bin:/usr/bin:/sbin:/usr/sbin \
		/bin/bash --login
fi
