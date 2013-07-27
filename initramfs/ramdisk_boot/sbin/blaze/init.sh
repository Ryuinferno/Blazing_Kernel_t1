#!/system/bin/sh

bb=/sbin/blaze/busybox

# custom bootanimtion support (if no bootanimation.zip is found, will run original animation)
$bb mount -o rw,remount /system
if [ -e /system/media/bootanimation.zip ] && [ ! -e /system/etc/cusboot ]; then
  $bb cp /sbin/blaze/bootanimation_cus /system/bin/bootanimation
  $bb chmod 755 /system/bin/bootanimation
  $bb chown 0.2000 /system/bin/bootanimation
  $bb echo "On" > /system/etc/cusboot
  $bb mount -o ro,remount /system
elif [ -e /system/media/bootanimation.zip ] && [ -e /system/etc/cusboot ]; then
  $bb mount -o ro,remount /system
elif [ ! -e /system/media/bootanimation.zip ] && [ ! -e /system/etc/cusboot ]; then
  $bb mount -o ro,remount /system
else
  $bb cp /sbin/blaze/bootanimation_ori /system/bin/bootanimation
  $bb chmod 755 /system/bin/bootanimation
  $bb chown 0.2000 /system/bin/bootanimation
  $bb rm /system/etc/cusboot
  $bb mount -o ro,remount /system
fi

# custom boot sound support
$bb mount -o rw,remount /system
if [ -e /system/media/PowerOn.ogg ]; then
  $bb mv /system/media/PowerOn.ogg /system/media/audio/ui/PowerOn.ogg
  $bb chmod 644 /system/media/audio/ui/PowerOn.ogg
  $bb mount -o ro,remount /system
elif [ -e /system/media/ori_sound ]; then
  $bb cp /sbin/blaze/PowerOn.ogg /system/media/audio/ui/PowerOn.ogg
  $bb chmod 644 /system/media/audio/ui/PowerOn.ogg
  $bb rm /system/media/ori_sound
  $bb mount -o ro,remount /system
elif [ -e /system/media/mute ]; then
  $bb mv /system/media/audio/ui/PowerOn.ogg /system/media/audio/ui/PowerOn.ogg.bak
  $bb rm /system/media/mute
  $bb mount -o ro,remount /system
elif [ -e /system/media/unmute ]; then
  $bb mv /system/media/audio/ui/PowerOn.ogg.bak /system/media/audio/ui/PowerOn.ogg
  $bb rm /system/media/unmute
  $bb mount -o ro,remount /system
else
  $bb mount -o ro,remount /system
fi

# init.d support
if [ -d /system/etc/init.d ]; then
  $bb run-parts /system/etc/init.d
else
  $bb mount -o rw,remount /system
  $bb mkdir /system/etc/init.d
  $bb chmod 777 /system/etc/init.d
  $bb mount -o ro,remount /system
fi

if [ -d /data/etc/init.d ]; then
  $bb run-parts /data/etc/init.d
else
  $bb mkdir /data/etc
  $bb chmod 777 /data/etc
  $bb mkdir /data/etc/init.d
  $bb chmod 777 /data/etc/init.d
fi
