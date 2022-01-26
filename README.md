# ovdc-snap
ovdc-snap - Oracle virtual desktop client snap package - access remote desktops from Linux like a SunRay terminal

ovdc is Oracle's client for accessing remote virtual X desktops 
via a SunRay server, in the same way that a SunRay smart terminal can do.
It uses Sun ALP protocol, which is similar to RDP
and a good deal snappier than VNC.
Although it works well, Oracle consider this an obsolete product,
and Ubuntu 18.04 was the last release that made available the gnome2 etc libraries
required to support it, and which could directly install the oracle DEB package
ovdc_3.2.0-1_amd64.deb.

So this is a self-contained snap with the above `.deb` contents re-packaged,
plus other gnome2 environment paraphenalia,
that will (should!) run on any Linux distribution that supports snaps.

# Oracle documentation for original DEB package
Supporting documentation for this release of **ovdc** is available on the [Oracle Virtual Desktop Client 3.2 Documentation page](https://docs.oracle.com/cd/E36351_01/index.html).
This page provides access to installation, configuration, and administration information for Oracle Virtual Desktop Client.

# NOTES ON CREATING THE OVDC SNAP

The build takes place in a restricted environment which cannot see outside or above (in this case) `~/mysnaps/ovdc` , the current directory in which snapcraft is run. Since the process unpacks files from the .deb package, it needs to be copied to this directory.

The .snap package produced is in the form of a squashfs filesystem archive. It can be unpacked and examined with the "unsquashfs" command:
```
  sdalley@centaur:~/mysnaps/ovdc-junk$ unsquashfs ../ovdc/ovdc_3.2.0-1-snap0.1_amd64.snap 
  Parallel unsquashfs: Using 2 processors
  21037 inodes (22940 blocks) to write

  [================================================================================================================================================================================\] 22940/22940 100%

  created 11414 files
  created 2192 directories
  created 9623 symlinks
  created 0 devices
  created 0 fifos
```
The Java Runtime Environment needed by **ovdc** is tarballed up under /opt/ovdc in the suppled .deb and is untarred by the **postinst** script. This extra encapsulation isn't needed, and defeats the dump plugin. So let's repack the .deb with those files extracted like all the others are.
```
  sdalley:~/mysnaps/ovdc$ mkdir tmp
  sdalley:~/mysnaps/ovdc$ sudo dpkg-deb -R ovdc_3.2.0-1_amd64.deb tmp/
  root@centaur:/home/sdalley/mysnaps/ovdc/tmp/opt/ovdc# tar xzf jre-7u6-linux-x64.tar.gz
  (as root, edits to remove this action from postinst)
  root@centaur:/home/sdalley/mysnaps/ovdc# dpkg-deb -b tmp/ ovdc_3.2.0-2_amd64.deb
```
The important "parts" are as follows:

- Java Runtime Environment. This is bundled in the original product as a zip file and when installed in a normal ubuntu 18.04 system it appeared at
/opt/ovdc/jre1.7.0_06/ . This in turn contains bin lib and man subdirectories and files, e.g. bin/java and lots of libraries, jar files etc.
- The main OVDC application, a large jar file, which was installed in ubuntu 18.04 in /opt/ovdc/OVDC.jar .
- The "ovdc" command-line executable, a short shell script which the user uses
to launch the whole thing. It passes flags and arguments to the works
underneath, as follows:
```
#!/bin/sh
#
# Copyright (c) 2013, Oracle and/or its affiliates. All rights reserved.
#
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.
cd /opt/ovdc
exec ./jre1.7.0_06/bin/java -jar OVDC.jar "$@"
```
The above suggests that there is at least one binary library in /opt/ovdc. Sure enough, there is...

- "libvdc.so". In the snap package, this should be relocated to somewhere like /usr/local/lib, (which *should* be included on the LD_LIBRARY_PATH that snap installation sets up, in which the snap's own contribution to /usr/local/lib *should* magically appear).

EXTERNAL INTERFACE REQUIREMENTS

The install process for the original .deb package ran the following "postinst" script commnands:
```
GROUPNAME="ovdcusers"
groupadd $GROUPNAME 2>/dev/null

#Security issue user needs to be explicitly added to ovdcusers to access USB
#usermod -a -G ovdcusers $SUDO_USER > /dev/null 2>&1

service udev restart 1>/dev/null
```
which obviously hasn't been used up to now so we won't worry about it.

When running, ovdc reads and writes files in folder .OVDC/ in the user's home directory, creating it if it doesn't exist. This is where it stores setup profiles for configured sunray sessions, and session logging if enabled.

# LEARNING ABOUT SNAPS
I started with tutorial video "Snapcraft Live - A beginner's tutorial on building snaps" https://www.youtube.com/watch?reload=9&v=BEp_l2oUcD8 .

Building a snap requires the (snap) packages "snapcraft" and "multipass".

The heart of a snap project is the snapcraft.yaml configuration file. It's sort-of like a powerful super-make configuration language. The tool that runs on it is the `snapcraft` command, which is like a super-make to generate the snap from it. Previous builds are cached, so it only rebuilds what it needs to.

'multipass' is used mostly under the bonnet to run the snap development environment as a virtual machine with a clean development environment with only the items spelled out in snapcraft.yaml in it. The first time snapcraft is run, by default it will use `multipass` as build machine (there are other options), installing it if it's not already there.

This is a good intro to the process in general: https://ubuntu.com/tutorials/create-your-first-snap .

Since OVDC is java-based, I also referred to https://snapcraft.io/blog/building-a-java-snap-by-example .

This reference gives essential understanding of the process: https://snapcraft.io/docs/parts-lifecycle .

This is also helpful: https://snapcraft.io/docs/environment-variables

## THE SECRET WORLD OF THE SNAP

In the snap world, many things are completely invisible compared to what you are used to from the world of your normal command line and building things locally with your local toolchain, and others are in different places, and change depending on what little world we're in. There are at least three worlds:
### The snapcraft environment
This is typically a virtual machine (VM) using something called
"multipass" in which the building takes place.
This world can be inspected from a shell if you run
```
    snapcraft --shell-after # rebuilds as needed, then starts a local shell
```
For the `hello` test app, this gives you an idea:
```
snapcraft-hello # pwd
/root
snapcraft-hello # ls -F
parts/  prime/  project/  snap/  stage/  state
snapcraft-hello # mount | grep sdalley
:/home/sdalley/mysnaps/hello on /root/project type fuse.sshfs (rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other)
snapcraft-hello # find project/ -ls
        1      4 drwxrwxr-x   1 root     root           50 Jun  9 13:10 project/
        4     96 -rw-r--r--   1 root     root        98304 Jun  9 18:36 project/hello_2.10_amd64.snap
        2      4 drwxrwxr-x   1 root     root           28 Jun  9 12:30 project/snap
        3      4 -rw-rw-r--   1 root     root          463 Jun  9 18:14 project/snap/snapcraft.yaml
snapcraft-hello # ls -l
total 24
drwxr-xr-x 3 root root 4096 Jun  9 13:10 parts
drwxr-xr-x 5 root root 4096 Jun  9 13:10 prime
drwxrwxr-x 1 root root   50 Jun  9 13:10 project
drwxr-xr-x 3 root root 4096 Jun  9 13:09 snap
drwxr-xr-x 4 root root 4096 Jun  9 13:10 stage
-rw-r--r-- 1 root root  363 Jun  9 18:36 state
snapcraft-hello # cat state
!GlobalState
assets:
  build-packages:
  - autoconf=2.69-11
  - automake=1:1.15.1-3ubuntu2
  - autopoint=0.19.8.1-6ubuntu0.3
  - autotools-dev=20180224.1
  - file=1:5.32-2ubuntu0.4
  - libmagic-mgc=1:5.32-2ubuntu0.4
  - libmagic1=1:5.32-2ubuntu0.4
  - libsigsegv2=2.12-1
  - libtool=2.4.6-2
  - m4=1.4.18-1
  build-snaps:
  - core18=2066
  required-grade: stable
snapcraft-hello # gcc --version
gcc (Ubuntu 7.5.0-3ubuntu1~18.04) 7.5.0
Copyright (C) 2017 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

snapcraft-hello # 
```
If you browse down from the top `/` directory you will see that there is a whole booted-up VM with a little distribution and build environment neatly packaged up. When snapcraft first runs, the VM is re-generated as needed from up-to-date upstream packages from the `base` platform, in this case `core18`, a subset of the Ubuntu 18.04 LTS platform.

You are the root user in this world, and your home directory is `/root`.Note that your real-world current directory in which snapcraft is run gets mounted read-write under `/root/project/` in the snapcraft VM. Your `snapcraft.yaml` which specifies the whole thing therefore appears in `/root/project/snap/snapcraft.yaml`. 

#### snapcraft steps
Stop here and read https://snapcraft.io/docs/parts-lifecycle#heading--steps .
Briefly, these are:
- pull - unpacks the specified part(s) into the `parts/` subfolder from its specified `source`,
- build - runs each part's specified `plugin` to create the installable items; these also appear under `parts/`, in various places, e.g. under `parts/\<part\>/build/`
- stage - copies specified built items to staging area `stage/`
- prime - ditto, but to priming area, contains only files needed in final snap,
- snap - packages files in priming area into  `<name-version>.snap`. This file is left in `project/` (which is the current directory of your invoking shell). The snap system configuration metadata is put under `snap/`.

### The snap's local execution environment
This contains all the snap's internal installed pieces, and is what they see when a snap-provided command is running.
For an installed snap, this can be inspected in a shell using a command like (in our case)
```
    snap run --shell ovdc
```
This is set up with useful environment variables such as $SNAP and $HOME which are available to be used in internal shell scripts and such. See
https://snapcraft.io/docs/environment-variables for a full list.

### The user environment
This is what the user sees of the snap contents when
invoking a command or service provided by the snap. This is controlled by the `apps: ` section in `snapcraft.yaml`.
