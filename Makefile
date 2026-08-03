# Makefile for NeoOS build driver
.PHONY: help rootfs iso proot all clean test

help:
	@echo "NeoOS targets:"
	@echo "  make rootfs   build Debian 13 trixie rootfs + tarball"
	@echo "  make iso      build bootable live ISO"
	@echo "  make proot    build proot-distro tarball (aarch64 default)"
	@echo "  make all      rootfs + iso + proot"
	@echo "  make test     run test suites"
	@echo "  make clean    remove build artifacts"

rootfs:
	./build.sh rootfs

iso:
	./build.sh iso

proot:
	./build.sh proot

all:
	./build.sh all

test:
	bash tests/test-neolibs.sh

clean:
	./build.sh clean
