# Makefile for NeoOS build driver
.PHONY: help rootfs iso proot all clean test neokit-base neokit-all

help:
	@echo "NeoOS targets:"
	@echo "  make rootfs       build Debian 13 trixie rootfs + tarball"
	@echo "  make iso          build bootable live ISO"
	@echo "  make proot        build proot-distro tarball (aarch64 default)"
	@echo "  make all          rootfs + iso + proot"
	@echo "  make test         run test suites"
	@echo "  make clean        remove build artifacts"
	@echo ""
	@echo "Neokit base layer targets:"
	@echo "  make neokit-base     build Neokit 1.0 base rootfs layer"
	@echo "  make neokit-all      neokit-base + rootfs + iso + proot"

rootfs:
	./build.sh rootfs

iso:
	./build.sh iso

proot:
	./build.sh proot

neokit-base:
	./build.sh neokit-base

neokit-all:
	./build.sh neokit-all

all:
	./build.sh all

test:
	bash tests/test-neolibs.sh
	bash tests/test-neos.sh

clean:
	./build.sh clean
