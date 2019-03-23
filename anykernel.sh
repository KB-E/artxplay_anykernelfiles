# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers
## AnyKernel setup
# EDIFY properties
kernel.string=ArtxPlay for the Moto Z Play
permissive=1
do.devicecheck=1
do.initd=1
do.ukm=0
do.modules=0
do.cleanup=1
device.name1=addison
device.name2=
device.name3=
device.name4=
device.name5=
device.name6=
device.name7=

# shell variables
block=/dev/block/bootdevice/by-name/boot;
initd=/system/etc/init.d;
bindir=/system/bin;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel permissions
# set permissions for included ramdisk files
chmod 755 /tmp/anykernel/ramdisk/sbin/busybox
chmod -R 755 $ramdisk

## AnyKernel install
dump_boot;

# begin ramdisk changes

# Init.d
cp -fp $patch/init.d/* $initd
chmod -R 755 $initd

# remove mpdecsion binary
mv $bindir/mpdecision $bindir/mpdecision-rm

# Android version
if [ -f "/system/build.prop" ]; then
  SDK="$(grep "ro.build.version.sdk" "/system/build.prop" | cut -d '=' -f 2)";
  ui_print "     Android SDK API: $SDK.";
  if [ "$SDK" -le "25" ]; then
    ui_print " "; ui_print "[!]- Android 7.1 and older is not supported. Aborting..."; exit 1;
  fi;
else
  ui_print " "; ui_print "[!]- No build.prop could be found. Aborting..."; exit 1;
fi;

# Properties
#ui_print "[+]- Modifying properties...";
backup_file default.prop;
replace_string default.prop "ro.adb.secure=0" "ro.adb.secure=1" "ro.adb.secure=0";
replace_string default.prop "ro.secure=0" "ro.secure=1" "ro.secure=0";

# Detect ROM SDK
if [ "$SDK" -ge "28" ]; then
  ui_print "[!]- Pie 9.0 System detected!"
elif [ "$SDK" -ge "27" ]; then
  ui_print "[!]- Oreo 8.1 System detected!"
elif [ "$SDK" -eq "26" ]; then
  ui_print "[!]- Oreo 8.0 System detected!"
fi;

# end ramdisk changes
ui_print "[!]- Flashing Kernel..."
write_boot;
ui_print "     Done"