STAGEDIR := "$(CURDIR)/stage"
DESTDIR := "$(CURDIR)/install"

ARCH ?= "armhf"
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

define stage_package
	(cd $(2)/debs && apt-get download $(1);)
	dpkg-deb --extract $$(ls $(2)/debs/$(1)*.deb | tail -1) $(2)/unpack
endef


all: clean
	# Preparation stage
	mkdir -p $(STAGEDIR)/debs $(STAGEDIR)/unpack
	# u-boot
	$(call stage_package,u-boot-rpi,$(STAGEDIR))
	cp boot.scr.in $(STAGEDIR)/boot.scr.in
ifeq ($(ARCH),arm64)
	sed -i s/bootz/booti/ $(STAGEDIR)/boot.scr.in
endif
	mkimage -A $(MKIMAGE_ARCH) -O linux -T script -C none -n "boot script" -d $(STAGEDIR)/boot.scr.in $(STAGEDIR)/boot.scr
	# boot-firmware
	$(call stage_package,raspi3-firmware,$(STAGEDIR))
	# devicetrees
	$(call stage_package,linux-modules-*-raspi2,$(STAGEDIR))
	# Staging stage
	mkdir -p $(DESTDIR)/boot-assets
	# u-boot
	cp $(STAGEDIR)/unpack/usr/lib/u-boot/$(UBOOT_TARGET)/u-boot.bin $(DESTDIR)/boot-assets/$(UBOOT_BIN)
	cp $(STAGEDIR)/boot.scr $(DESTDIR)
	# boot-firmware
	for file in fixup start bootcode; do \
		cp $(STAGEDIR)/unpack/usr/lib/raspi3-firmware/$${file}* $(DESTDIR)/boot-assets/; \
	done
	# devicetrees
	cp -a $(STAGEDIR)/unpack/lib/firmware/*/device-tree/* $(DESTDIR)/boot-assets
ifeq ($(ARCH),arm64)
	cp -a $(STAGEDIR)/unpack/lib/firmware/*/device-tree/broadcom/*.dtb $(DESTDIR)/boot-assets
endif
	# configs
	cp configs/config.txt configs/cmdline.txt $(DESTDIR)/boot-assets/
	# gadget.yaml
	mkdir -p $(DESTDIR)/meta
	cp gadget.yaml $(DESTDIR)/meta/

clean:
	-rm -rf $(DESTDIR)
	-rm -rf $(STAGEDIR)
