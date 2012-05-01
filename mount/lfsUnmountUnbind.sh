#!/bin/bash

LFS=/mnt/lfs

sudo umount $LFS/sys
sudo umount $LFS/proc
sudo umount $LFS/dev/pts
sudo umount $LFS/dev/shm
sudo umount $LFS/dev

sudo umount $LFS/opt
sudo umount $LFS/usr/src
sudo umount $LFS/usr
sudo umount $LFS/home
sudo umount $LFS/boot
sudo umount $LFS

