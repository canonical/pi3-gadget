# Raspberry Pi 3 Gadget Snap

This repository contains the source for an Ubuntu classic gadget tree for the Raspberry Pi 3.

Building it with snapcraft or make will automatically pull all the required
binaries from the Ubuntu archive and stage it to a directory for ubuntu-image
to consume.

## Gadget Snaps

Gadget snaps are a special type of snaps that contain device specific support
code and data. You can read more about them in the snapd wiki
https://github.com/snapcore/snapd/wiki/Gadget-snap

## Gadget Trees

Gadget trees are nothing more than gadget snaps before they have been packed
into a snap. These compiled gadget trees are used by ubuntu-image in the classic
mode when a classic image is to be built using this tool.

## Reporting Issues

Please report all issues on the Launchpad project page
https://bugs.launchpad.net/snap-pi3/+filebug

We use Launchpad to track issues as this allows us to coordinate multiple
projects better than what is available with Github issues.

## Building

To build the gadget tree locally on an armhf system please use `snapcraft prime`
or by using `make`.

To cross build this gadget tree on an amd64 machine please run
`snapcraft prime --target-arch=armhf`.

## Launchpad Mirror.

All commits from the master branch of https://github.com/CanonicalLtd/pi3 are
automatically mirrored by Launchpad to the https://launchpad.net/snap-pi3
project.
