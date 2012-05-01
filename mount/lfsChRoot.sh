#!/bin/bash

LFS=/mnt/lfs

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
