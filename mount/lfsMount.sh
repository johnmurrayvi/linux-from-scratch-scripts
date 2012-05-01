#!/bin/bash

LFS=/mnt/lfs


if [ ! -d $LFS ] ; then
	sudo mkdir $LFS
fi
sudo mount -v -t ext3 /dev/sdb5 $LFS

i=6
for dir in boot home usr usr/src opt ; do
	if [ ! -d $LFS/$dir ] ; then
		sudo mkdir $LFS/$dir
	fi
	sudo mount -v -t ext3 /dev/sdb$i $LFS/$dir
	let "i+=1"
done

#if [ ! -d $LFS/boot ] ; then
#	sudo mkdir $LFS/boot
#fi
#sudo mount -v -t ext3 /dev/sdb6 $LFS/boot


#if [ ! -d $LFS/home ] ; then
#	sudo mkdir $LFS/home
#fi
#sudo mount -v -t ext3 /dev/sdb7 $LFS/home


#if [ ! -d $LFS/usr ] ; then
#	sudo mkdir $LFS/usr
#fi
#sudo mount -v -t ext3 /dev/sdb8 $LFS/usr


#if [ ! -d $LFS/usr/src ] ; then
#	sudo mkdir $LFS/usr/src
#fi
#sudo mount -v -t ext3 /dev/sdb9 $LFS/usr/src


#if [ ! -d $LFS/opt ] ; then
#	sudo mkdir $LFS/opt
#fi
#sudo mount -v -t ext3 /dev/sdb10 $LFS/opt

