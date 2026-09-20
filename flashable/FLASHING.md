# Flashing Guide — Pixel 8 Pro (husky)

## Before You Flash

1. **Back up** your data
2. **Bootloader unlocked** (required)
3. **Android 16 stock firmware** installed — LineageOS requires matching vendor firmware
4. **LineageOS 22.2+** installed (or stock Android 16 to test kernel alone)
5. Capture baseline logs: `adb shell su -c "dmesg" > dmesg-before.txt`

## Method 1: Test Boot (Safest)

Does not permanently flash — reboot reverts to previous kernel.

```bash
adb reboot bootloader
fastboot boot out/images/boot.img
```

Wait for boot. Test WiFi and Bluetooth for 30+ minutes (warm-up test).

## Method 2: Fastboot Flash

```bash
adb reboot bootloader

fastboot flash boot out/images/boot.img
fastboot flash vendor_kernel_boot out/images/vendor_kernel_boot.img
fastboot flash dtbo out/images/dtbo.img

fastboot reboot
```

## Method 3: Recovery ZIP

1. Copy `out/flashable/husky-wifi-fix-*.zip` to phone
2. Reboot to Lineage Recovery
3. Apply update → Install from storage → select ZIP
4. Reboot

## Verify KernelSU Root

```bash
adb shell su -c id
# Expected: uid=0(root) gid=0(root)

adb shell su -c "cat /proc/version"
# Should contain KernelSU build string
```

Install KernelSU manager APK from: https://github.com/tiann/KernelSU/releases

## Verify WiFi/BT Fix

```bash
# Check recovery patches are active
adb shell su -c "dmesg | grep -iE 'wlan_bt_recovery|L1SS disable|retry'"

# Monitor for link drops over 30 min
adb shell su -c "dmesg -w" | grep -iE "pcie|wlan|link"
```

## Tune Recovery (Optional)

If WiFi is unstable, adjust module params via adb:

```bash
# More aggressive PMIC retries
adb shell su -c "echo 12 > /sys/module/s2mpg15/parameters/wlan_bt_rail_retries"

# More PCIe link retries
adb shell su -c "echo 40 > /sys/module/pcie_brcm/parameters/pcie_brcm_link_retries"

# Disable runtime watchdog if it causes loops
adb shell su -c "echo 0 > /sys/module/wlan_bt_recovery/parameters/recovery_enabled"
```

## Rollback

Flash stock boot images from [Google Factory Images](https://developer.android.com/studio/run/win-usb):

```bash
fastboot flash boot boot.img
fastboot flash vendor_kernel_boot vendor_kernel_boot.img
fastboot flash dtbo dtbo.img
fastboot reboot
```

## If WiFi Still Dead After Kernel

Your device likely has a **hardware fault** (BGA solder on BCM4389 module). Options:

1. **Reflow/reball** the WiFi IC (G5602550) — ~$80–150 at a board repair shop
2. **Tighten motherboard screw** near WiFi module (some users report this helps)
3. **Google RMA** — cite the widespread Pixel 8 WiFi failure reports
4. **Motherboard replacement**

Hardware repair is the only fix when dmesg shows `status=FAILED` on every boot with zero recovery across all retries.
