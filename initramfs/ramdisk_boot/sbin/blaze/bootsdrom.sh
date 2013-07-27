#!/system/bin/sh

cfgfile=/sdmnt/SDRoms/bootsdrom.cfg
bb=/sbin/blaze/busybox

if $bb [ ! -f "$cfgfile" ]; 
then
    cfgfile=/sdmnt1/SDRoms/bootsdrom.cfg
fi;

if $bb [ ! -f "$cfgfile" ]; 
then
    $bb umount /data1
    $bb umount /sdmnt
    $bb umount /sdmnt1

    $bb rmdir /data1
    $bb rmdir /sdmnt
    $bb rmdir /sdmnt1

    exit 0
fi;

# Logging
if [ ! -d /sdmnt/SDRoms ]; 
then
    $bb mkdir /sdmnt/SDRoms
fi;
if $bb [ ! -d /sdmnt/SDRoms/update ]; 
then
    $bb mkdir /sdmnt/SDRoms/update
fi;
$bb cp /sdmnt/SDRoms/bootsdrom.log /sdmnt/SDRoms/bootsdrom.log.bak
$bb rm /sdmnt/SDRoms/bootsdrom.log
exec >>/sdmnt/SDRoms/bootsdrom.log
exec 2>&1

$bb echo "----dualboot init script created by chuandinh----"
$bb echo "----ported by fuss132 to Galaxy S2G----"
$bb echo "----mountsdrom starting----" 

$bb echo "Waiting for 3 seconds to switch the ROM..."
$bb cat /dev/input/event1 > /dev/keycheck & $bb sleep 3
$bb kill -9 $!

key_pressed=0
if [ -s /dev/keycheck ];
then
     $bb echo "Key pressed!!!"
     key_pressed=1

     if $bb [ -f "$cfgfile" ]; 
     then
         defaultf=`$bb grep default= "$cfgfile" | $bb sed -e "s/default=//g"`
         
         if [ "$defaultf" == "sdcard" ];
         then
             $bb echo "Skip booting from SDrom..."
             $bb echo "Tip: set default ROM by changing the default value in bootsdrom.cfg"

             $bb umount /data1
             $bb umount /sdmnt
             $bb umount /sdmnt1

             $bb rmdir /data1
             $bb rmdir /sdmnt
             $bb rmdir /sdmnt1

             exit 0
         fi;
     fi;
fi;

if $bb [ -f "$cfgfile" ]; 
then
    $bb echo "Checking values in the config file..."

    #rom=`$bb head -1 $cfgfile`
    defaultf=`$bb grep ^default= "$cfgfile" | $bb sed -e "s/default=//g"`
    romf=`$bb grep ^rom= "$cfgfile" | $bb sed -e "s/rom=//g"`
    systemf=`$bb grep ^system= "$cfgfile" | $bb sed -e "s/system=//g"`
    dataf=`$bb grep ^data= "$cfgfile" | $bb sed -e "s/data=//g"` 
    cachef=`$bb grep ^cache= "$cfgfile" | $bb sed -e "s/cache=//g"` 
    preloadf=/sdmnt/SDRoms/rom1/preload.img
    sharedataf=`$bb grep ^sharedatap= "$cfgfile" | $bb sed -e "s/sharedatap=//g"` 
	

    if [ ! "$defaultf" == "sdcard" ] && [ "$key_pressed" == "0" ];
    then
        $bb echo "Booting phone ROM..."
        $bb echo "Tip: set default ROM by changing the default value in bootsdrom.cfg"

        $bb umount /data1
        $bb umount /sdmnt
        $bb umount /sdmnt1

        $bb rmdir /data1
        $bb rmdir /sdmnt
        $bb rmdir /sdmnt1

        exit 0
    fi;

    $bb echo "rom=$romf"
    $bb echo "system=$systemf"
    $bb echo "data=$dataf"
    $bb echo "cache=$cachef"
    $bb echo "preload=$preloadf"

    if $bb [ -f "$systemf" ] && [ -f "$dataf" ] && [ -f "$cachef" ]; 
    then
        $bb echo "Booting from $romf..."

        $bb losetup /dev/block/loop1 "$systemf"
        #$bb sleep 1
        $bb losetup /dev/block/loop2 "$dataf"
        #$bb sleep 1
        $bb losetup /dev/block/loop3 "$cachef"
        #$bb sleep 1
        $bb losetup /dev/block/loop4 "$preloadf"

        if $bb [ ! -d "$romf/android_secure" ];
        then
            $bb mkdir "$romf/android_secure"
        fi;
        $bb mount --bind "$romf/android_secure" mnt/secure/asec

	#$bb mkdir "/data1/$rom"
        #$bb mkdir "/data1/$rom/system"
        #$bb mkdir "/data1/$rom/cache"
        #$bb mkdir "/data1/$rom/data"

        $bb mount -t ext4 /dev/block/loop1 "/system"
        $bb mount -t ext4 /dev/block/loop3 "/cache"
        $bb mount -t ext4 /dev/block/loop4 "/preload"

        if [ "$sharedataf" == "1" ];
        then
             if [ ! -d /data/datasd ]; then
                 $bb mkdir /data/datasd
                 $bb mount -t ext4 /dev/block/loop2 "/datasd"

                 if [ ! -d /data/datasd/dalvik-cache ]; then
                     $bb mkdir /data/datasd/dalvik-cache
                 fi;
                 
                 $bb chown system /data/datasd/dalvik-cache
                 $bb chown system.system /data/datasd/dalvik-cache
                 $bb chmod 0771 /data/datasd/dalvik-cache

                 $bb mount --bind /data/datasd/dalvik-cache /data/dalvik-cache
             fi;
        else
             $bb mount -t ext4 /dev/block/loop2 "/data"
        fi;

        # update the SDRom at boot
        if [ -d /sdmnt/SDRoms/update/system ]; 
        then
            $bb echo "Update system on SDRom..."
            $bb mount /system -o remount,rw
            $bb cp -rf /sdmnt/SDRoms/update/system/* /system/
            $bb chmod 644 /system/lib/modules/*
            $bb mv -f /sdmnt/SDRoms/update/system /sdmnt/SDRoms/update/system_updated
            $bb mount /system -o remount,ro
        fi;

        if [ -d /sdmnt/SDRoms/update/data ]; 
        then
            $bb echo "Update data folder on SDRom..."
            $bb cp -rf /sdmnt/SDRoms/update/data/* /data/
            $bb mv -f /sdmnt/SDRoms/update/data /sdmnt/SDRoms/update/data_updated
        fi;

        if $bb [ -f /sdmnt/SDRoms/update/wipe_dalvik-cache ]; 
        then
            $bb echo "Wipe davik-cache on SDRom..."
            $bb rm -rf /data/dalvik-cache/*
            $bb mv -f /sdmnt/SDRoms/update/wipe_dalvik-cache /sdmnt/SDRoms/update/wipe_dalvik-cache_complete
        fi;

        if $bb [ -f /sdmnt/SDRoms/update/update.zip ]; 
        then
            $bb mount /system -o remount,rw

            $bb echo "Extract system to SDRom..."
            $bb unzip -o /sdmnt/SDRoms/update/update.zip "system/*" -d /

            $bb echo "Extract data to SDRom..."
            $bb unzip -o /sdmnt/SDRoms/update/update.zip "data/*" -d /

            $bb mv -f /sdmnt/SDRoms/update/update.zip /sdmnt/SDRoms/update/update_complete.zip

            $bb mount /system -o remount,ro
        fi;
    else
        $bb echo "Error: ROM images not found"
    fi;
else
    $bb echo "Booting phone ROM..."

    #$bb mount -t ext4 /dev/block/mmcblk0p9 /system -o noatime,wait,ro,nodelalloc
    #$bb mount -t ext4 /dev/block/mmcblk0p7 /cache -o nosuid,nodev,noatime,wait,nodelalloc
    #$bb mount -t ext4 /dev/block/mmcblk0p10 /data -o nosuid,nodev,noatime,wait,noauto_da_alloc
fi;

$bb echo "----mountsdrom finished----"
