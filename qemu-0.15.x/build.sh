#!/bin/sh
./configure --disable-kvm --disable-sdl --enable-serialice \
	    --target-list="x86_64-softmmu, i386-softmmu"

if [ $? -eq 0 ]; then
   make
fi
