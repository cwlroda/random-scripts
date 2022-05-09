#!/bin/bash
# Backup apt packages script

sudo apt install -y apt-clone

if [ -d ~/apt_packages ]
then
    sudo rm -rf ~/apt_packages/*
fi

sudo apt-clone clone ~/apt_packages --with-dpkg-repack
