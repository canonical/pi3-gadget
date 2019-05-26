STAGEDIR := "$(CURDIR)/stage"
DESTDIR := "$(CURDIR)/install"

ARCH ?= $(shell dpkg --print-architecture)
SERIES ?= "bionic"
ifeq ($(ARCH),arm64)
	UBOOT_TARGET := "rpi_3"
	UBOOT_BIN := "kernel8.img"
	MKIMAGE_ARCH := "arm64"
else
	UBOOT_TARGET := "rpi_3_32b"
	UBOOT_BIN := "uboot.bin"
	MKIMAGE_ARCH := "arm"
endif

SOURCES_HOST ?= "/etc/apt/sources.list"
SOURCES_MULTIVERSE := "$(STAGEDIR)/apt/multiverse.sources.list"

define stage_package
	( \
		cd $(2)/debs && \
		apt-get download -o APT::Architecture=$(3) $(1); \
	)
	dpkg-deb --extract $$(ls $(2)/debs/$(1)*.deb | tail -1) $(2)/unpack
endef

define enable_multiverse
	mkdir -p $(STAGEDIR)/apt
	cp $(SOURCES_HOST) $(SOURCES_MULTIVERSE)
	sed -i "s/^\(deb.*\)\$$/\1 multiverse/" $(SOURCES_MULTIVERSE)
	apt-get update \
		-o Dir::Etc::sourcelist=$(SOURCES_MULTIVERSE) \
		-o APT::Architecture=$(ARCH) 2>/dev/null
endef


all: clean
	# The only supported pi architectures are armhf and arm64
	if [ "$(ARCH)" != "armhf" ] && [ "$(ARCH)" != "arm64" ]; then \
		echo "Build architecture is not supported."; \
		exit 1; \
	fi
	# XXX: This is a hack that we can hopefully get rid of once. Currently
	# the livefs Launchpad builders don't have multiverse enabled.
	# We wanto to work-around that by actually enabling multiverse just
	# for this one build here as we need it for linux-firmware-raspi2.
	$(call enable_multiverse)
	# Preparation stage
	mkdir -p $(STAGEDIR)/debs $(STAGEDIR)/unpack
	# u-boot
	$(call stage_package,u-boot-rpi,$(STAGEDIR),$(ARCH))
	cp boot.scr.in $(STAGEDIR)/boot.scr.in
ifeq ($(ARCH),arm64)
	sed -i s/bootz/booti/ $(STAGEDIR)/boot.scr.in
endif
	mkimage -A $(MKIMAGE_ARCH) -O linux -T script -C none -n "boot script" -d $(STAGEDIR)/boot.scr.in $(STAGEDIR)/boot.scr
	# boot-firmware
	$(call stage_package,linux-firmware-raspi2,$(STAGEDIR),$(ARCH))
	# devicetrees
	$(call stage_package,linux-modules-*-raspi2,$(STAGEDIR),$(ARCH))
	# Staging stage
	mkdir -p $(DESTDIR)/boot-assets
	# u-boot
	cp $(STAGEDIR)/unpack/usr/lib/u-boot/$(UBOOT_TARGET)/u-boot.bin $(DESTDIR)/boot-assets/$(UBOOT_BIN)
	cp $(STAGEDIR)/boot.scr $(DESTDIR)
	# boot-firmware
	for file in fixup start bootcode; do \
		cp $(STAGEDIR)/unpack/usr/lib/linux-firmware-raspi2/$${file}* $(DESTDIR)/boot-assets/; \
	done
	# devicetrees
	cp -a $(STAGEDIR)/unpack/lib/firmware/*/device-tree/* $(DESTDIR)/boot-assets
ifeq ($(ARCH),arm64)
	cp -a $(STAGEDIR)/unpack/lib/firmware/*/device-tree/broadcom/*.dtb $(DESTDIR)/boot-assets
endif
	# configs
	cp configs/cmdline.txt $(DESTDIR)/boot-assets/
	cp configs/config.txt.$(ARCH) $(DESTDIR)/boot-assets/config.txt
	cp configs/user-data* $(DESTDIR)/boot-assets/
	cp configs/meta-data* $(DESTDIR)/boot-assets/
	cp configs/network-config* $(DESTDIR)/boot-assets/
	# gadget.yaml
	mkdir -p $(DESTDIR)/meta
	cp gadget.yaml $(DESTDIR)/meta/

clean:
	-rm -rf $(DESTDIR)
	-rm -rf $(STAGEDIR)
