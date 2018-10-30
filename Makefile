STAGEDIR := "$(CURDIR)/stage"
DESTDIR := "$(CURDIR)/install"

DEVTREES_PACKAGES := "http://ports.ubuntu.com/ubuntu-ports/dists/bionic-updates/universe/binary-armhf/Packages.gz"
DEVTREES_PKGPATH := $(shell wget -q -O- $(DEVTREES_PACKAGES)|zcat|grep-dctrl linux-raspi2|grep linux-modules|grep Filename|tail -1| sed 's/^Filename: //')


define stage_package
	(cd $(2)/debs && apt-get download $(1);)
	dpkg-deb --extract $(2)/debs/$(1)*.deb $(2)/unpack
endef


all: clean
	mkdir -p $(STAGEDIR)/debs $(STAGEDIR)/unpack
	# u-boot
	$(call stage_package,u-boot-rpi,$(STAGEDIR))
	mkenvimage -r -s 131072 -o $(STAGEDIR)/uboot.env uboot.env.in
	# boot-firmware
	$(call stage_package,raspi3-firmware,$(STAGEDIR))
	# devicetrees
	wget http://ports.ubuntu.com/ubuntu-ports/$(DEVTREES_PKGPATH) -P $(STAGEDIR)/debs
	dpkg -x $(STAGEDIR)/debs/$$(basename $(DEVTREES_PKGPATH)) $(STAGEDIR)/unpack/

install:
	mkdir -p $(DESTDIR)/boot-assets
	# u-boot
	cp $(STAGEDIR)/unpack/usr/lib/u-boot/rpi_3_32b/u-boot.bin $(DESTDIR)/boot-assets/
	cp $(STAGEDIR)/uboot.env $(DESTDIR)
	ln -s uboot.env $(DESTDIR)/uboot.conf
	# boot-firmware
	for file in fixup start bootcode; do \
		cp $(STAGEDIR)/unpack/usr/lib/raspi3-firmware/$${file}* $(DESTDIR)/boot-assets/; \
	done
	# devicetrees
	cp -a $(STAGEDIR)/unpack/lib/firmware/*/device-tree/* $(DESTDIR)/boot-assets

	# configs
	cp configs/config.txt configs/cmdline.txt $(DESTDIR)/boot-assets/
	# gadget.yaml
	mkdir -p $(DESTDIR)/meta
	cp gadget.yaml $(DESTDIR)/meta/

clean:
	-rm -rf $(DESTDIR)
	-rm -rf $(STAGEDIR)
