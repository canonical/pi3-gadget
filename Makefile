STAGEDIR := "$(CURDIR)/stage"
DESTDIR := "$(CURDIR)/install"

ARCH ?= "armhf"
SERIES ?= "bionic"
ifeq ($(ARCH),arm64)
	UBOOT_TARGET := "rpi_3"
	UBOOT_BIN := "kernel8.img"
else
	UBOOT_TARGET := "rpi_3_32b"
	UBOOT_BIN := "uboot.bin"
endif

# XXX: because of legacy reasons this is done this way but most probably we
#  can just use the stage_package call to get the right binaries.
DEVTREES_PACKAGES := "http://ports.ubuntu.com/ubuntu-ports/dists/$(SERIES)-updates/universe/binary-$(ARCH)/Packages.gz"
DEVTREES_PKGPATH := $(shell wget -q -O- $(DEVTREES_PACKAGES)|zcat|grep-dctrl linux-raspi2|grep linux-modules|grep Filename|tail -1| sed 's/^Filename: //')


define stage_package
	(cd $(2)/debs && apt-get download $(1);)
	dpkg-deb --extract $(2)/debs/$(1)*.deb $(2)/unpack
endef


all: clean
	# Preparation stage
	mkdir -p $(STAGEDIR)/debs $(STAGEDIR)/unpack
	# u-boot
	$(call stage_package,u-boot-rpi,$(STAGEDIR))
	#cp uboot.env.in $(STAGEDIR)/uboot.env.in
	cp boot.scr.in $(STAGEDIR)/boot.scr.in
ifeq ($(ARCH),arm64)
	#sed -i s/bootz/booti/ $(STAGEDIR)/uboot.env.in
	sed -i s/bootz/booti/ $(STAGEDIR)/boot.scr.in
endif
	mkimage -A $(ARCH) -O linux -T script -C none -n "boot script" -d $(STAGEDIR)/boot.scr.in $(STAGEDIR)/boot.scr
	#mkenvimage -r -s 131072 -o $(STAGEDIR)/uboot.env $(STAGEDIR)/uboot.env.in
	# boot-firmware
	$(call stage_package,raspi3-firmware,$(STAGEDIR))
	# devicetrees
	wget http://ports.ubuntu.com/ubuntu-ports/$(DEVTREES_PKGPATH) -P $(STAGEDIR)/debs
	dpkg -x $(STAGEDIR)/debs/$$(basename $(DEVTREES_PKGPATH)) $(STAGEDIR)/unpack/
	# Staging stage
	mkdir -p $(DESTDIR)/boot-assets
	# u-boot
	cp $(STAGEDIR)/unpack/usr/lib/u-boot/$(UBOOT_TARGET)/u-boot.bin $(DESTDIR)/boot-assets/$(UBOOT_BIN)
	#cp $(STAGEDIR)/uboot.env $(DESTDIR)
	#ln -s uboot.env $(DESTDIR)/uboot.conf
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
