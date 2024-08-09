dirname = $(shell basename `pwd`)

CC = arm-linux-gnueabihf-gcc
CXX = arm-linux-gnueabihf-g++
LD_LIBRARY_PATH = /usr/local/lib

.PHONY: install env

build: env
	./zig0.13/zig build-exe src/main.zig \
	    -target arm-linux-gnueabihf \
		-mcpu arm1176jzf_s \
		-lc \
		-I /usr/local/include -L /usr/local/lib -lpigpio -lpthread

install: env
	sudo apt install -y git musl musl-dev libc6:armhf raspberrypi-kernel-headers

	if [ ! -d "zig0.13" ]; then \
		wget https://ziglang.org/download/0.13.0/zig-linux-armv7a-0.13.0.tar.xz; \
		tar -xf zig-linux-armv7a-0.13.0.tar.xz; \
		rm zig-linux-armv7a-0.13.0.tar.xz; \
		mv zig-linux-armv7a-0.13.0 zig0.13; \
	fi

	if [ ! -d "pigpio-master" ]; then \
		git clone https://github.com/joan2937/pigpio -b develop pigpio-master; \
	else \
		cd pigpio-master && make clean; \
	fi
	cd pigpio-master && make CC=arm-linux-gnueabihf-gcc -j4 && sudo make install

env:
	@echo "export CC=$(CC)"
	@echo "export CXX=$(CXX)"
	@echo "export LD_LIBRARY_PATH=$(LD_LIBRARY_PATH)"

push:
	ssh yohan@192.168.1.45 "mkdir -p /home/yohan/$(dirname)"
	rsync -avx . yohan@192.168.1.45:/home/yohan/$(dirname)

pull:
	rsync -avx yohan@192.168.1.45:/home/yohan/$(dirname)/ .
