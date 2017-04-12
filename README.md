# Raspberry Pi 3 Gadget Snap

This repository contains the official Ubuntu Core gadget snap for the Raspberry
Pi 3.

## Gadget Snaps

Gadget snaps are a special type of snaps that contain device specific support
code and data. You can read more about them in the snapd wiki
https://github.com/snapcore/snapd/wiki/Gadget-snap

## Reporting Issues

Please report all issues on the Launchpad project page
https://bugs.launchpad.net/snap-pi3/+filebug

We use Launchpad to track issues as this allows us to coordinate multiple
projects better than what is available with Github issues.

## Building

To build the gadget snap locally please use `snapcraft`. This repository will
be soon updated to support snapcraft natively, via a `snapcraft.yaml` file,
stay tuned!

In case you need to rebuild u-boot, the steps are

```
sudo apt install gcc-arm-linux-gnueabi
export CROSS_COMPILE=arm-linux-gnueabi-
git clone git://git.denx.de/u-boot.git
cd u-boot; git checkout v2017.01-rc1
git apply <gadget-folder>/prebuilt/uboot.patch
make rpi_3_32b_defconfig
make -j8
```

Building the uboot environment

```
mkenvimage -r -s 131072  -o uboot.env uboot.env.in
```

## Launchpad Mirror and Automatic Builds.

All commits from the master branch of https://github.com/snapcore/pi3 are
automatically mirrored by Launchpad to the https://launchpad.net/snap-pi3
project.

The master branch is automatically built from the launchpad mirror and
published into the snap store to the edge channel.

You can find build history and other controls here:
https://code.launchpad.net/~canonical-foundations/+snap/pi3
