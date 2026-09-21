### AnyKernel3 — Husky WiFi Fix Kernel (Pixel 8 / 8 Pro)
## Prebuilt GKI images for husky/shiba

properties() { '
kernel.string=Husky WiFi Fix Kernel + KernelSU
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=husky
device.name2=shiba
supported.versions=16
'; }

. tools/ak3-core.sh;

ui_print " ";
ui_print " Husky WiFi Fix Kernel ";
ui_print " Flashing all kernel partitions...";
ui_print " ";

# Static partitions (fastboot mode)
for part in boot vendor_kernel_boot dtbo; do
  if [ -f ${part}.img ]; then
    ui_print " * ${part}";
    flash_generic ${part}.img ${part};
  fi;
done;

# Dynamic DLKM partitions (AK3 reboots to fastbootd automatically)
for part in vendor_dlkm system_dlkm; do
  if [ -f ${part}.img ]; then
    ui_print " * ${part}";
    flash_generic ${part}.img ${part};
  fi;
done;

ui_print " ";
ui_print " Done! Reboot system.";
