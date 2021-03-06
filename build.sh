#!/bin/bash

# variables
VERSION="v16"
TOOLCHAIN="/opt/linaro-4.7.4-2013.09/bin/arm-cortex_a9-linux-gnueabi-"
STRIP="${TOOLCHAIN}strip"
OUTDIR="../out"
OUTDIR2="out"
ZIPDIR="../tools/zipfile"
PLACEHOLDER="Delete_before_compiling"
ANDROID="initramfs/ramdisk_boot"
ANDROID2="ramdisk_boot1"
ANDROID3="ramdisk_boot2"
REC="ramdisk_recovery"
REC_TOUCH="ramdisk_recovery_touch"
REC_MOD="ramdisk_recovery_mod"
REC_TWRP="ramdisk_recovery_twrp"
REC_PHILZ="ramdisk_recovery_philz"
MODULES=("drivers/net/wireless/bcmdhd/dhd.ko" "drivers/scsi/scsi_wait_scan.ko" "fs/cifs/cifs.ko" "drivers/samsung/j4fs/j4fs.ko" "drivers/samsung/exfat/exfat_fs.ko" "drivers/samsung/exfat/exfat_core.ko" "net/sunrpc/sunrpc.ko" "net/sunrpc/auth_gss/auth_rpcgss.ko" "fs/nfs/nfs.ko" "fs/lockd/lockd.ko")
START=$(date +%s)

  case "$1" in
  clean)
          # for a clean build
          make mrproper CROSS_COMPILE=${TOOLCHAIN}
          rm -rf ${OUTDIR}
          rm -rf ${OUTDIR2}
          rm -f ../tools/zipfile/system/lib/modules/*
   ;;
   *)  
        if [ ! -z "$blaze" ]; then
            mkdir -p ${OUTDIR}
        else
            mkdir -p ${OUTDIR2}
        fi
   
        make -j8 blazing_defconfig CROSS_COMPILE=${TOOLCHAIN}
       
        # create modules first to include in ramdisk
        make -j8 CROSS_COMPILE=${TOOLCHAIN}
        
        for module in "${MODULES[@]}" ; do
            $STRIP --strip-unneeded --strip-debug "${module}"
            if [ ! -z "$blaze" ]; then
                cp "${module}" ${ZIPDIR}/system/lib/modules
            else
                cp "${module}" ${OUTDIR2}
            fi
        done
        chmod 644 ${ZIPDIR}/system/lib/modules/*

        cd usr/pvr-source/eu*/bu*/li*/om*
        make -j8 ARCH=arm CROSS_COMPILE=${TOOLCHAIN} KERNELDIR=~/Repos/Dual/kernel TARGET_PRODUCT="blaze_tablet" BUILD=release TARGET_SGX=540 PLATFORM_VERSION=4.0
        $STRIP --strip-unneeded --strip-debug ../../../bi*/target/pvrsrvkm_sgx540_120.ko
        if [ ! -z "$blaze" ]; then
            mv ../../../bi*/target/pvrsrvkm_sgx540_120.ko ../../../../../../${ZIPDIR}/system/lib/modules
        else
            mv ../../../bi*/target/pvrsrvkm_sgx540_120.ko ../../../../../../${OUTDIR2}
        fi
        rm -r ../../../bi*
        cd ../../../../../..

        # create the android ramdisk
        rm initramfs/stage1/boot.cpio
        cd ${ANDROID}
        find . | cpio -o -H newc > ../stage1/boot.cpio
        cd ..

        rm stage1/boot1.cpio
        cd ${ANDROID2}
        rm data/$PLACEHOLDER
        rm system/$PLACEHOLDER
        find . | cpio -o -H newc > ../stage1/boot1.cpio
        echo > data/$PLACEHOLDER
        echo > system/$PLACEHOLDER
        cd ..
        
        rm stage1/boot2.cpio
        cd ${ANDROID3}
        rm data/$PLACEHOLDER
        rm system/$PLACEHOLDER
        find . | cpio -o -H newc > ../stage1/boot2.cpio
        echo > data/$PLACEHOLDER
        echo > system/$PLACEHOLDER
        cd ..

        # create the recovery ramdisk, "cwm6" is for 6.0.1.2, "old" is for 5.5.0.4, "touch" is for touch recovery, "twrp" for TWRP 2.6.3.0, "philz" for Philz recovery 5.15.0
        # default is modified 6.0.4.0
      case "$1" in
      touch)
        RECOVERY=${REC_TOUCH}
        REC_NAME="TOUCH"
      ;;
      cwm6)
        RECOVERY=${REC}
        REC_NAME="CWM6"
      ;;
      twrp)
        RECOVERY=${REC_TWRP}
        REC_NAME="TWRP"
      ;;
      philz)
        RECOVERY=${REC_PHILZ}
        REC_NAME="PHILZ"
      ;;
      *)
        RECOVERY=${REC_MOD}
        REC_NAME="CWM6_MOD"
      ;;
      esac

        rm stage1/recovery.cpio
        cd ${RECOVERY}
        rm tmp/$PLACEHOLDER
        find . | cpio -o -H newc > ../stage1/recovery.cpio
        echo > tmp/$PLACEHOLDER
        cd ../.. 
        
        # build the zImage
        echo 0 > .version
        make -j8 CROSS_COMPILE=${TOOLCHAIN}
        if [ ! -z "$blaze" ]; then
            cp arch/arm/boot/zImage ${OUTDIR}
            cp arch/arm/boot/zImage ${ZIPDIR}
        else
            cp arch/arm/boot/zImage ${OUTDIR2}
        fi
     
      cd ..

        if [ ! -z "$blaze" ]; then
            # creating zip for kernel
            echo "Creating flashable zip..."
            cd tools/zipfile
            zip -r Blazing_Kernel_${VERSION}_${REC_NAME}.zip *
            cd ..
            echo "Sigining zip..."
            java -jar signapk.jar -w testkey.x509.pem testkey.pk8 zipfile/Blazing_Kernel_${VERSION}_${REC_NAME}.zip ${OUTDIR}/Blazing_Kernel_${VERSION}_${REC_NAME}.zip
  
            rm zipfile/*.zip zipfile/zImage 
            cd ../kernel
        fi
   ;;
   esac

# timer
END=$(date +%s)
ELAPSED=$((END - START))
E_MIN=$((ELAPSED / 60))
E_SEC=$((ELAPSED - E_MIN * 60))
echo -ne "\033[32mElapsed: "
[ $E_MIN != 0 ] && echo -ne "$E_MIN min(s) "
echo -e "$E_SEC sec(s)\033[0m"
