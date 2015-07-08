#!/bin/bash

TOOLCHAIN="/home/gustavo/toolchain-a9/bin/arm-cortex_a9-linux-gnueabihf-"
STRIP="/home/gustavo/toolchain-a9/bin/arm-cortex_a9-linux-gnueabihf-strip"
OUTDIR="out/zip"
INITRAMFS_SOURCE="/home/gustavo/kernel/out/ramdisk/i9100.list"
RAMDISK="/home/gustavo/kernel/out/ramdisk/initramfs_files"
RAMDISK_OUT="/home/gustavo/kernel/out/ramdisk/boot.cpio"
MODULES=("/home/gustavo/kernel/net/sunrpc/auth_gss/auth_rpcgss.ko" "/home/gustavo/kernel/fs/cifs/cifs.ko" "drivers/net/wireless/bcmdhd/dhd.ko" "/home/gustavo/kernel/fs/lockd/lockd.ko" "/home/gustavo/kernel/fs/nfs/nfs.ko" "/home/gustavo/kernel/net/sunrpc/auth_gss/rpcsec_gss_krb5.ko" "drivers/scsi/scsi_wait_scan.ko" "drivers/samsung/fm_si4709/Si4709_driver.ko" "/home/gustavo/kernel/net/sunrpc/sunrpc.ko")
KERNEL_DIR="/home/gustavo/kernel"
MODULES_DIR="/home/gustavo/kernel/out/zip/system/lib/modules"
CURRENTDATE=$(date +"%d-%m")

case "$1" in
	clean)
        cd ${KERNEL_DIR}
        make clean && make mrproper
		;;
	lp)
        # compress the ramdisk in cpio
        cd ${RAMDISK}
        rm *.cpio
        find . -not -name ".gitignore" | cpio -o -H newc > ${RAMDISK_OUT}
        
        cd ${KERNEL_DIR}
        make -j3 kernel_defconfig ARCH=arm CROSS_COMPILE=${TOOLCHAIN}

        # build modules first to include them into zip file
        make -j3 ARCH=arm CROSS_COMPILE=${TOOLCHAIN} modules
       
        for module in "${MODULES[@]}" ; do
            cp "${module}" ${MODULES_DIR}
            ${STRIP} --strip-unneeded ${MODULES_DIR}/*
        done
      
        # build the kernel with trim
        cd ${KERNEL_DIR}
        make -j3 ARCH=arm CROSS_COMPILE=${TOOLCHAIN} CONFIG_INITRAMFS_SOURCE=${INITRAMFS_SOURCE}
        cp arch/arm/boot/zImage ${OUTDIR}
        cd ${OUTDIR}
		echo "Creating kernel zip..."
        zip -r cm12.1-kernel-$CURRENTDATE.zip ./ -x *.zip *.gitignore
        
         # build the kernel without trim
        #cd ${KERNEL_DIR}
       # patch -Rp1 < trim.patch
       #make -j3 ARCH=arm CROSS_COMPILE=${TOOLCHAIN} CONFIG_INITRAMFS_SOURCE=${INITRAMFS_SOURCE}
      #  cp arch/arm/boot/zImage ${OUTDIR}
      #  cd ${OUTDIR}
	#	echo "Creating kk CWM kernel zip..."
      #  zip -r kk-kernel-$CURRENTDATE-CWM.zip ./ -x *.zip *.gitignore
        
        cd ${KERNEL_DIR}
        patch -p1 < ${KERNEL_DIR}/trim.patch
        
		echo "Done!"
	    ;;
esac
