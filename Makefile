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

install: env os zig pigpio libcamera

os: env
	sudo apt install -y git i2c-tools musl musl-dev \
		python3-dev python3-jinja2 \
		libc6:armhf raspberrypi-kernel-headers \
		libgnutls28-dev openssl libtiff-dev pybind11-dev \
		qtbase5-dev libqt5core5a \
		meson cmake \
		python3-yaml python3-ply \
		libglib2.0-dev libgstreamer-plugins-base1.0-dev

zig: env
	if [ ! -d "zig0.13" ]; then \
		wget https://ziglang.org/download/0.13.0/zig-linux-armv7a-0.13.0.tar.xz; \
		tar -xf zig-linux-armv7a-0.13.0.tar.xz; \
		rm zig-linux-armv7a-0.13.0.tar.xz; \
		mv zig-linux-armv7a-0.13.0 zig0.13; \
	fi

pigpio: env
	if [ ! -d "pigpio-master" ]; then \
		git clone https://github.com/joan2937/pigpio -b develop pigpio-master; \
	else \
		cd pigpio-master && make clean; \
	fi
	cd pigpio-master && make CC=arm-linux-gnueabihf-gcc -j4 && sudo make install

libcamera: env
	sudo apt install libcamera-dev g++ libc++-dev
	# if [ ! -d "libcamera" ]; then \
	# 	git clone https://git.linuxtv.org/libcamera.git; \
	# else \
	# 	cd libcamera && git pull; \
	# fi
	# cd libcamera && meson setup build --buildtype=release -Dpipelines=rpi/vc4 -Dv4l2=true -Dgstreamer=enabled -Dtest=false -Dlc-compliance=disabled -Dcam=disabled -Dqcam=disabled -Ddocumentation=disabled -Dpycamera=enabled && ninja -C build install -j1

env:
	@echo "export CC=$(CC)"
	@echo "export CXX=$(CXX)"
	@echo "export LD_LIBRARY_PATH=$(LD_LIBRARY_PATH)"

push:
	ssh yohan@192.168.1.45 "mkdir -p /home/yohan/$(dirname)"
	rsync -avx . yohan@192.168.1.45:/home/yohan/$(dirname)

pull:
	rsync -avx yohan@192.168.1.45:/home/yohan/$(dirname)/ .
