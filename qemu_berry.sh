#!/bin/bash
#this script is based off of the amazing azeria-labs write up on
#manualy creating this.  Check out the page for more information.

qemu_storage_path="${HOME}/qemu_vms"

if [ $UID = 0 ]
then
    SUDO=""
else
    SUDO="sudo"
fi


#get zip, unzip, check image file partitions & set offset size; 
#then mount, mod needed files, &unmount
initial_qemu_img_setup()
{
    local image_name=$1
    local download_url=$2
    local image_path="${qemu_storage_path}/${image_name}.img"
    local image_zip_path="${qemu_storage_path}/${image_name}.zip"

    if [ ! -f ${image_path} ]; then
        if [ ! -f ${image_zip_path} ]; then
            #check if we have a copy localy with this script

            #else we golden retrieve it
            echo ".zip for requested ${image_name} image not found; downloading now...get some coffee...nap...play fetch!"
            wget ${download_url} -O ${image_zip_path}
        else
            echo "Unzipping image file, this may take awhile."
            unzip ${image_zip_path} -d ${qemu_storage_path}
        fi

        fdisk -l ${image_path}
        echo "Enter the start of .img2 above for $image_name and it will be multiplied by 512 for you:"
        read img2_start
        #need to automate finding the start and input it here or check input
        offset=$((${img2_start} * 512))
        echo "Using ${offset} to mount ${image_name}."
        $SUDO mkdir -p /mnt/raspbian
        $SUDO mount -v -o offset=$offset -t ext4 ${image_path} /mnt/raspbian

        cp -f /mnt/raspbian/etc/ld.so.preload /mnt/raspbian/etc/ld.so.preload.bak
        #commenting out all entries
        sed -i 's/^\([^#]\)/#\1/g' /mnt/raspbian/etc/ld.so.preload
        #only doing this to show user what was changed
        diff /mnt/raspbian/etc/ld.so.preload /mnt/raspbian/etc/ld.so.preload.bak

        #copy to .bak instead of using -i.bak with sed due to multiple changes to file
        cp -f /mnt/raspbian/etc/fstab /mnt/raspbian/etc/fstab.bak
        #correcting mmcblk in fstab to sda's
        sed -i 's|/dev/mmcblk0p1|/dev/sda1|g' /mnt/raspbian/etc/fstab
        sed -i 's|/dev/mmcblk0p2|/dev/sda2|g' /mnt/raspbian/etc/fstab
        diff /mnt/raspbian/etc/fstab /mnt/raspbian/etc/fstab.bak
        $SUDO umount /mnt/raspbian

        #we now copy and resize image copy
        #manual input is need in the vm to do this currently
        echo "Making backup of ${image_path}."
        cp ${image_path} ${image_path}.bak
        echo "Resizing image size to +6G."
        qemu-img resize ${image_path} +6G
        
        echo "\#####YOU MUST MANUALY DO AFTER THIS SCRIPT FINISHES FOR EACH IMAGE######"
        echo "You will now need to launch ${image_path}.bak with:"
        echo "sudo qemu-system-arm -kernel ~/qemu_vms/qemu-rpi-kernel/kernel-qemu-4.4.34-jessie -cpu arm1176 -m 256 -M versatilepb -serial stdio -append \"root=/dev/sda2 rootfstype=ext4 rw\" -hda ${image_path}.bak -redir tcp:5022::22 -no-reboot -hdb ${image_path}"
        echo "Login and run: $ sudo cfdisk /dev/sdb, then delete the sdb2 parition, then create new primary partition with all available space. \nYou will need to make sdb1 bootable to be able to write new partition structure."        
        echo "$ sudo e2fsck -f /dev/sdb2"
        echo "$ sudo resize2fs /dev/sdb2"
        echo "$ sudo fsck -f /dev/sdb2"
        echo "$ sudo halt"
        echo "Wait 1 minute then ctrl+c to get back to HOST command prompt."

    else
        echo "The image for ${image_name} already exists. Please delete and try again if you want a fresh install."
    fi
}


#qemu stuff
#qemu from source
function install_qemu
{
    mkdir -p ${HOME}/src
    cd ${HOME}/src
    if [ ! -d qemu ]; then
        git clone git://git.qemu.org/qemu.git
    fi
        cd qemu
        git checkout master
        git pull
        git submodule init
        git submodule update --recursive
        mkdir build
        cd build
        ../configure
        make
        $SUDO make install
}


#get qemu-kvm stuff
function install_qemu_extras_4_kvm
{
    $SUDO apt-get update
        #qemu-kvm contains the basic QEMU KVM programs
        #libvirt-dev contains programs for the libvirt library (udev is used due to different naming on distros the bin is all that is really needed)
        #bridge-utils contains programs to connect your host network to the virtual machine
        #virt-manager GUI for KVM
    $SUDO apt-get install qemu-kvm libvirt-dev bridge-utils virt-manager
    echo "You will need to relogin before use of libvirtd will properly work."
}


#qemu kernels
#download kernels if needed
function git_pi_qemu_kernels
{
if [ ! -d qemu-rpi-kernel ]; then
    git clone "https://github.com/dhruvvyas90/qemu-rpi-kernel.git"
else
    cd ${qemu_storage_path}/qemu-rpi-kernel
    git pull
fi
}




#####THE WORK STARTS HERE#####
$SUDO apt-get update
$SUDO apt-get install git autoconf make

install_qemu
install_qemu_extras_4_kvm

mkdir -p ${qemu_storage_path}
cd ${qemu_storage_path}

#get kernels - still need to verify these kernels and source
git_pi_qemu_kernels

#get raspi images
initial_qemu_img_setup 2013-07-26-wheezy-raspbian "http://downloads.raspberrypi.org/raspbian/images/2013-07-26-wheezy-raspbian/2013-07-26-wheezy-raspbian.zip"

initial_qemu_img_setup 2017-07-05-raspbian-jessie "http://downloads.raspberrypi.org/raspbian/images/raspbian-2017-07-05/2017-07-05-raspbian-jessie.zip"

initial_qemu_img_setup 2017-11-29-raspbian-stretch "http://downloads.raspberrypi.org/raspbian/images/raspbian-2017-12-01/2017-11-29-raspbian-stretch.zip"

#how to runs these
echo "all images use default username: pi"
echo "with default password: raspberry"
echo "There are examples on how to run these images at the end of the script"

#qemu-system-arm -kernel ~/qemu_vms/qemu-rpi-kernel/kernel-qemu-4.4.34-jessie -cpu arm1176 -m 256 -M versatilepb -serial stdio -append "root=/dev/sda2 rootfstype=ext4 rw" -hda ~/qemu_vms/2013-07-26-wheezy-raspbian.img -redir tcp:6022::22 -no-reboot

#qemu-system-arm -kernel ~/qemu_vms/qemu-rpi-kernel/kernel-qemu-4.4.34-jessie -cpu arm1176 -m 256 -M versatilepb -serial stdio -append "root=/dev/sda2 rootfstype=ext4 rw" -hda ~/qemu_vms/2017-07-05-raspbian-jessie.img -redir tcp:6022::22 -no-reboot

#qemu-system-arm -kernel ~/qemu_vms/qemu-rpi-kernel/kernel-qemu-4.4.34-jessie -cpu arm1176 -m 256 -M versatilepb -serial stdio -append "root=/dev/sda2 rootfstype=ext4 rw" -hda ~/qemu_vms/2017-11-29-raspbian-stretch.img -redir tcp:6022::22 -no-reboot

cd ~
exit 0
