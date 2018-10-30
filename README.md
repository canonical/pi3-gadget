# Raspberry Pi 3 Gadget Snap

This repository contains the source for an Ubuntu classic gadget tree for the Raspberry Pi 3.

Building it with snapcraft will automatically pull all the required dependencies from the
Ubuntu archive and put all the required bits into the gadget. Same for the firmware parts.

Last it will pull the latest linux-image-raspi2 from the xenial-updates archive, extract the
devicetree and overlay files from it and add them to the gadget as well.

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

To build the gadget tree locally on an armhf system please use `snapcraft prime`.

To cross build this gadget snap on a PC please run `snapcraft --target-arch=armhf`

## Launchpad Mirror and Automatic Builds.

All commits from the master branch of https://github.com/snapcore/pi3 are
automatically mirrored by Launchpad to the https://launchpad.net/snap-pi3
project.

The master branch is automatically built from the launchpad mirror and
published into the snap store to the edge channel.

You can find build history and other controls here:
https://code.launchpad.net/~canonical-foundations/+snap/pi3
