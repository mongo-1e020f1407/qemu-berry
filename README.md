# qemu-berry
script to auto install qemu, rasbian, and kernels need to emulate several versions.

WARNING: The images will take up a large amount of drive space until setup and the backups removed from the system.  Ensure that you have ~35 GB of free space available before running this script.


A big shout out to the amazing Azeria-labs for the initial process this script uses.
There are also some killer tutorials/quides on there to use with these images.

This can be less if you do not finish the instructions to increase the size of the images after install.  Currently 6GB is added to each uncompressed image to give working room.


This script will attempt to download and install several different versions of raspian for use with qemu.

Images are pulled from downloads.raspberrypi.org and can be large (2-4GB each) uncompressed.  Currently 3 images are pulled at:

2013-07-26-wheezy-raspbian.zip  = ~ GB
2017-07-05-raspbian-jessie.zip  = ~ GB
2017-11-29-raspbian-stretch.zip = ~ GB

Qemu is pulled from source master and compiled, this can be changed to allow older version of qemu with support for now depricated systems to be ran.

Kernels used are pulled from a 3rd party repo but can be changed to point anywhere.  Future plans are to give the option to build these if I continue to be mad at buildroot when using older kernels.




LEGAL - Normal LGPL3.0 and use at your own risk


~~MONGO~~


