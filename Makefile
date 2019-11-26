STAGEDIR := "$(CURDIR)/stage"
DESTDIR := "$(CURDIR)/install"

ARCH ?= $(shell dpkg --print-architecture)
SERIES ?= "bionic"
ifeq ($(ARCH),arm64)
	MKIMAGE_ARCH := "arm64"
else
	MKIMAGE_ARCH := "arm"
endif

SERIES_HOST ?= $(shell lsb_release --codename --short)
SOURCES_HOST ?= "/etc/apt/sources.list"
SOURCES_MULTIVERSE := "$(STAGEDIR)/apt/multiverse.sources.list"

define stage_package
	( \
		cd $(2)/debs && \
		apt-get download \
			-o APT::Architecture=$(3) \
			-o Dir::Etc::sourcelist=$(SOURCES_MULTIVERSE) $$( \
				apt-cache \
					-o APT::Architecture=$(3) \
					-o Dir::Etc::sourcelist=$(SOURCES_MULTIVERSE) \
					showpkg $(1) | \
					sed -n -e 's/^Package: *//p' | \
					sort -V | tail -1 \
		); \
	)
	dpkg-deb --extract $$(ls $(2)/debs/$(1)*.deb | tail -1) $(2)/unpack
endef

define enable_multiverse
	mkdir -p $(STAGEDIR)/apt
	cp $(SOURCES_HOST) $(SOURCES_MULTIVERSE)
	sed -i "/^deb/ s/\b$(SERIES_HOST)/$(SERIES)/" $(SOURCES_MULTIVERSE)
	sed -i "/^deb/ s/$$/ multiverse/" $(SOURCES_MULTIVERSE)
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
	# We want to work-around that by actually enabling multiverse just
	# for this one build here as we need it for linux-firmware-raspi2.
	$(call enable_multiverse)

	# Preparation stage
	mkdir -p $(STAGEDIR)/debs $(STAGEDIR)/unpack
	$(call stage_package,flash-kernel,$(STAGEDIR),$(ARCH))
	$(call stage_package,u-boot-rpi,$(STAGEDIR),$(ARCH))
	$(call stage_package,linux-firmware-raspi2,$(STAGEDIR),$(ARCH))
	$(call stage_package,linux-modules-*-raspi2,$(STAGEDIR),$(ARCH))

	# Staging stage
	mkdir -p $(DESTDIR)/boot-assets
	# NOTE: the bootscr.rpi* below is deliberate; older flash-kernels have
	# separate bootscr.rpi? files for different pis, while newer have a
	# single generic bootscr.rpi file
	for kvers in $(STAGEDIR)/unpack/lib/modules/*; do \
		sed \
			-e "s/@@KERNEL_VERSION@@/$${kvers##*/}/g" \
			-e "s/@@LINUX_KERNEL_CMDLINE@@//g" \
			-e "s/@@LINUX_KERNEL_CMDLINE_DEFAULTS@@//g" \
			-e "s/@@UBOOT_ENV_EXTRA@@//g" \
			-e "s/@@UBOOT_PREBOOT_EXTRA@@//g" \
			$(STAGEDIR)/unpack/etc/flash-kernel/bootscript/bootscr.rpi* \
			> $(STAGEDIR)/unpack/bootscr.rpi; \
	done
	mkimage -A $(MKIMAGE_ARCH) -O linux -T script -C none -n "boot script" \
		-d $(STAGEDIR)/unpack/bootscr.rpi $(DESTDIR)/boot-assets/boot.scr
	for platform_path in $(STAGEDIR)/unpack/usr/lib/u-boot/*; do \
		cp -a $$platform_path/u-boot.bin \
			$(DESTDIR)/boot-assets/uboot_$${platform_path##*/}.bin; \
	done
	for file in fixup start bootcode; do \
		cp -a $(STAGEDIR)/unpack/usr/lib/linux-firmware-raspi2/$${file}* \
			$(DESTDIR)/boot-assets/; \
	done
	cp -a $$(find $(STAGEDIR)/unpack/lib/firmware/*/device-tree -name "*.dtb") \
		$(DESTDIR)/boot-assets/
	mkdir -p $(DESTDIR)/boot-assets/overlays
	cp -a $$(find $(STAGEDIR)/unpack/lib/firmware/*/device-tree -name "*.dtbo") \
		$(DESTDIR)/boot-assets/overlays/
	cp -a configs/*.txt $(DESTDIR)/boot-assets/
	cp -a configs/config.txt.$(ARCH) $(DESTDIR)/boot-assets/config.txt
	cp -a configs/user-data $(DESTDIR)/boot-assets/
	cp -a configs/meta-data $(DESTDIR)/boot-assets/
	cp -a configs/network-config $(DESTDIR)/boot-assets/
	cp -a configs/README $(DESTDIR)/boot-assets/
	mkdir -p $(DESTDIR)/meta
	cp gadget.yaml $(DESTDIR)/meta/

clean:
	-rm -rf $(DESTDIR)
	-rm -rf $(STAGEDIR)
