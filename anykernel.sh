# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers
## AnyKernel setup
# EDIFY properties
kernel.string=
permissive=1
do.devicecheck=1
do.setskiagl=1
do.cleanup=1
device.name1=addison

# Shell Variables
block=/dev/block/bootdevice/by-name/boot;

# AnyKernel methods - Import patching functions/variables
. /tmp/anykernel/tools/ak2-core.sh;

# AnyKernel permissions - Set permissions for included ramdisk files
chmod 755 /tmp/anykernel/ramdisk/sbin/busybox;
chmod -R 755 $ramdisk;

# AnyKernel Install
dump_boot;

#-----------------------
# Begin Ramdisk Changes
#-----------------------

# Android Version
if [ -f "/system/build.prop" ]; then
  SDK="$(grep "ro.build.version.sdk" "/system/build.prop" | cut -d '=' -f 2)";
  ui_print "     Android SDK API: $SDK.";
  ui_print "     Android CPU ABI: $CPUABI.";
  if [ "$SDK" -le "25" ]; then
    ui_print " "; ui_print "[!]- Android 7.1 and older is not supported. Aborting..."; exit 1;
  fi;
else
  ui_print " "; ui_print "[!]- No build.prop could be found. Aborting..."; exit 1;
fi;

# Detect ROM SDK
if [ "$SDK" -ge "28" ]; then
  ui_print "     Android Version: 9.0-Pie";
elif [ "$SDK" -ge "27" ]; then
  ui_print "     Android Version: 8.1-Oreo";
elif [ "$SDK" -eq "26" ]; then
  ui_print "     Android Version: 8.0-Oreo";
fi;
sleep 1
ui_print " "

# Patch init.rc
ui_print "   - Pathing Ramdisk Files"
mount -o rw -t auto /vendor;
mount -o rw -t auto /system;
if [ -f /vendor/etc/init/hw/init.qcom.rc ]; then
  ui_print "     Treble ROM Detected";
  ui_print "     Adding AP-Kernel Settings Patch to /vendor";
  ui_print "     Adding Spectrum support";
  mixerpath=/vendor/etc/mixer_paths_wcd9305.xml;
  cp /tmp/anykernel/ramdisk/init.ak.rc /vendor/etc/init/hw/init.ak.rc;
  cp /tmp/anykernel/ramdisk/init.spectrum.rc /vendor/etc/init/hw/init.spectrum.rc
  cp /tmp/anykernel/ramdisk/init.spectrum.sh /vendor/etc/init/hw/init.spectrum.sh
  insert_line /vendor/etc/init/hw/init.qcom.rc "init.ak.rc" after "import /vendor/etc/init/hw/init.mmi.rc" "import /vendor/etc/init/hw/init.ak.rc";
  insert_line /vendor/etc/init/hw/init.qcom.rc "init.spectrum.rc" after "import /vendor/etc/init/hw/init.ak.rc" "import /vendor/etc/init/hw/init.spectrum.rc"
  chmod 644 /vendor/etc/init/hw/init.ak.rc;
  chmod 644 /vendor/etc/init/hw/init.spectrum.rc
  chmod 644 /vendor/etc/init/hw/init.spectrum.sh
  ui_print " "
elif [ -f /system/vendor/etc/init/hw/init.qcom.rc ]; then
  ui_print "     Adding AP-Kernel Settings Patch to /system"
  ui_print "     Adding Spectrum support";
  mixerpath=/system/vendor/etc/mixer_paths_wcd9305.xml;
  cp /tmp/anykernel/ramdisk/init.ak.rc /system/vendor/etc/init/hw/init.ak.rc;
  cp /tmp/anykernel/ramdisk/init.spectrum.rc /system/vendor/etc/init/hw/init.spectrum.rc
  cp /tmp/anykernel/ramdisk/init.spectrum.sh /system/vendor/etc/init/hw/init.spectrum.sh
  cp /tmp/anykernel/ramdisk/init.ak.rc /system/vendor/etc/init/hw/init.ak.rc;
  insert_line /system/vendor/etc/init/hw/init.qcom.rc "init.ak.rc" after "import /vendor/etc/init/hw/init.mmi.rc" "import /vendor/etc/init/hw/init.ak.rc";
  insert_line /system/vendor/etc/init/hw/init.qcom.rc "init.spectrum.rc" after "import /system/vendor/etc/init/hw/init.ak.rc" "import /system/vendor/etc/init/hw/init.spectrum.rc"
  chmod 644 /system/vendor/etc/init/hw/init.ak.rc;
  chmod 644 /system/vendor/etc/init/hw/init.spectrum.rc
  chmod 644 /system/vendor/etc/init/hw/init.spectrum.sh
  ui_print " "
fi
umount /vendor;
umount /system;

# Sepolicy
ui_print "   - Patching Magisk Sepolicy"
$bin/magiskpolicy --load sepolicy --save sepolicy \
    "allow { audioserver system_server location sensors } diag_device chr_file { read write }" \
    "allow { init modprobe } rootfs system module_load" \
    "allow { msm_irqbalanced hal_perf_default } { rootfs kernel } file { getattr read open }" \
    "allow { msm_irqbalanced hal_perf_default } { rootfs kernel } dir { getattr read open }" \
    "allow init { system_file vendor_file vendor_configs_file } file mounton" \
    "allow init rootfs file execute_no_trans" \
    "allow hal_perf_default hal_perf_default capability { kill }" \
    "allow hal_perf_default hal_graphics_composer_default process { signull }" \
    "allow hal_perf_default kernel dir { read search open }" \
    "allow hal_iop_default priv_app dir { search }" \
    "allow hal_memtrack_default qti_debugfs file { read open getattr }" \
    "allow mediaserver mediaserver_tmpfs file { read write execute }" \
    "allow healthd proc_stat file { read open getattr }" \
    "allow healthd healthd capability { sys_ptrace }" \
    "allow dumpstate fuse dir search" \
    "allow dumpstate fuse file getattr" \
    "allow dumpstate theme_data_file file { read open getattr }" \
    "allow priv_app { cache_private_backup_file unlabeled } dir getattr" \
    "allow shell dalvikcache_data_file dir write" \
    "allow untrusted_app proc_stat file { read open getattr }" \
    "allow untrusted_app rootfs file { read open getattr }" \
    "allow untrusted_app atrace_exec file { read open getattr }" \
    "allow untrusted_app audioserver_exec file { read open getattr }" \
    "allow untrusted_app blkid_exec file { read open getattr }" \
    "allow untrusted_app bootanim_exec file { read open getattr }" \
    "allow untrusted_app bootstat_exec file { read open getattr }" \
    "allow untrusted_app cameraserver_exec file { read open getattr }" \
    "allow untrusted_app cgroup dir { read open getattr }" \
    "allow untrusted_app qti_debugfs dir { search }" \
    "allow untrusted_app hal_memtrack_hwservice hwservice_manager { find }" \
    "allow untrusted_app sysfs_kgsl dir { read write getattr open }" \
    "allow untrusted_app sysfs_kgsl file { read write getattr open }" \
    "allow untrusted_app sysfs dir { read write getattr open }" \
    "allow untrusted_app sysfs file { read write getattr open }" \
    "allow untrusted_app sysfs_leds dir search" \
    "allow untrusted_app sysfs_leds lnk_file read" \
    "allow untrusted_app sysfs_zram dir search" \
    "allow untrusted_app sysfs_zram file { read open getattr }" \
    "allow vold logd dir read" \
    "allow vold logd lnk_file getattr" \
    ;
ui_print "     Done"
ui_print " "
# End Ramdisk Changes
ui_print "   - Initializing Kernel Installation...";
write_boot;

ui_print "     All Done";
