# Flashing Guide — Pixel 8 Pro (husky)

## Recover from bootloop FIRST

If stuck at the Google logo, reflash LineageOS stock kernel images:

1. Download LineageOS for husky from [download.lineageos.org/devices/husky](https://download.lineageos.org/devices/husky)
2. Extract `boot.img`, `dtbo.img`, `vendor_kernel_boot.img` from the zip
3. Flash:

```bash
adb reboot bootloader
fastboot flash boot boot.img
fastboot flash vendor_kernel_boot vendor_kernel_boot.img
fastboot flash dtbo dtbo.img
fastboot reboot
```

## Why the previous build bootlooped

1. **`fastboot boot boot.img` does not work** on Pixel 8 Pro — the bootloader cannot combine `boot` + `vendor_kernel_boot` at runtime
2. **Missing `vendor_dlkm.img` and `system_dlkm.img`** — GKI modules must match the custom kernel
3. **Recovery ZIP was broken** — used wrong format; new builds use AnyKernel3
4. **Protected GKI exports** — blocked WiFi/BT driver loading (now fixed in build)

## Correct flash procedure (fastboot)

Download **all five** images from the release:

```bash
adb reboot bootloader

# Stage 1: bootloader mode
fastboot flash boot boot.img
fastboot flash vendor_kernel_boot vendor_kernel_boot.img
fastboot flash dtbo dtbo.img

# Stage 2: fastbootd (required for dynamic DLKM partitions)
fastboot reboot fastboot
# Wait until: fastboot getvar is-userspace → yes

fastboot flash vendor_dlkm vendor_dlkm.img
fastboot flash system_dlkm system_dlkm.img

fastboot reboot
```

First boot may take up to 15 minutes.

## Flash via recovery ZIP

Use `husky-wifi-fix-*.zip` from the release (AnyKernel3 format). Flash from Lineage Recovery → Apply update. The ZIP handles fastbootd transition for DLKM partitions automatically.

## Verify

```bash
adb shell su -c id                    # KernelSU root
adb shell su -c "cat /proc/version"   # custom kernel string
adb shell su -c "dmesg | grep -i wlan_bt_recovery"
```

## Requirements

- Bootloader unlocked
- Android 16 vendor firmware (LineageOS 22.2+ or matching stock)
- Do **not** mix kernel images from different builds
