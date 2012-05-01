#!/bin/bash

LFS=/mnt/lfs

sudo umount $LFS/opt
sudo umount $LFS/usr/src
sudo umount $LFS/usr
sudo umount $LFS/home
sudo umount $LFS/boot
sudo umount $LFS

