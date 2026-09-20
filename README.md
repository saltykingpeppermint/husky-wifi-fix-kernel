# Husky WiFi/BT Recovery Kernel

Custom Android 16 GKI kernel for **Google Pixel 8 Pro (husky)** with:

- WiFi/Bluetooth PCIe power-rail recovery patches
- Aggressive link-training and driver re-init retries
- L1SS (Link State Power Save) workaround for intermittent dropouts
- Runtime recovery watchdog for thermal/intermittent failures
- **KernelSU** pre-integrated (root out of the box)
- LineageOS 22.2+ compatible (Android 16 firmware required)

## Important: What This Can and Cannot Fix

| Symptom | Likely cause | Kernel fix chance |
|---------|--------------|-------------------|
| WiFi/BT work when cold, die when warm | Bad BGA solder on BCM4389 module | **Low** — reflow/reball needed |
| WiFi dies after 5–30 min, BT still works | Driver/L1SS/PCIe recovery bug | **High** |
| `VSYS_PWR_WLAN_BT status=FAILED` at boot, never works | PMIC latched off (FW corruption or HW fault) | **Low–Medium** — retry may recover transient cases |
| Works briefly after stock OTA reflash, then fails | Vendor firmware + driver state | **Medium–High** |
| `Link recovery retry fail count: 10` in dmesg | PCIe link training timeout | **High** |

**Before building:** capture your failure signature:

```bash
adb shell su -c "dmesg | grep -iE 'pcie|brcm|s2mpg15|wlan|dhd|cpif|VSYS'"
```

If you see `s2mpg15-pmu: failed to enable channel 10` on **every** boot with zero recovery, hardware repair is the real fix. This kernel targets the large subset where recovery is possible via software.

## Quick Start (Linux)

### Prerequisites

- Ubuntu 22.04+ or Arch Linux
- 16 GB RAM, 150 GB free disk
- `repo`, `git`, `python3`, `bc`, `bison`, `flex`, `libssl-dev`, `ccache`

### Build

```bash
git clone https://github.com/YOUR_USER/husky-wifi-fix-kernel.git
cd husky-wifi-fix-kernel
./scripts/setup.sh          # clones kernel source (~30 min)
./scripts/build.sh          # builds + packages (~45–90 min)
```

Output: `out/flashable/husky-wifi-fix-kernel-*.zip`

### Flash (LineageOS)

Requires unlocked bootloader and **Android 16 stock firmware** installed first.

```bash
# Test boot without flashing (recommended first)
fastboot boot out/images/boot.img

# If WiFi/BT work, flash permanently:
fastboot flash boot out/images/boot.img
fastboot flash vendor_kernel_boot out/images/vendor_kernel_boot.img
fastboot flash dtbo out/images/dtbo.img
```

Or use the flashable ZIP from Lineage Recovery → Apply update → choose ZIP.

## Patches Applied

1. **s2mpg15-wlan-bt-power-rail-retry** — Retries PMIC CH10 enable with exponential backoff and rail reset
2. **pcie-brcm-link-recovery** — Increases PCIe link wait from 10 to 30 retries, adds power-cycle between attempts
3. **dhd-wifi-init-retry** — Raises `_dhd_module_init` max retries from 3 to 10
4. **dhd-l1ss-disable-quirk** — Disables L1SS on husky to prevent warm-state link drops
5. **wifi-bt-runtime-recovery** — Kernel watchdog re-inits WLAN/BT on `PCI not powered on` errors

## KernelSU

Uses [KernelSU](https://github.com/tiann/KernelSU) (official). After boot:

1. Install **KernelSU manager** APK
2. Root is active immediately — no Magisk needed
3. For Zygisk modules, use **KernelSU's built-in module system**

## LineageOS Compatibility

Built against Google's `android-gs-shusky-6.1-android16` branch (GKI 6.1). Matches LineageOS husky 22.2 kernel ABI. Flash **after** LineageOS is installed; do not mix with mismatched firmware versions.

## GitHub Actions Build

Push to `main` or trigger manually → Actions → **Build Husky Kernel**. Artifacts contain the flashable ZIP.

## Troubleshooting

**Bootloop after flash:** Your firmware version may not match. Reflash stock Android 16 factory image, then retry.

**WiFi still dead:** Run `adb shell su -c dmesg > dmesg.txt` and check for `status=FAILED` vs `Link is DOWN`. Hardware repair (reflow of BCM4389, part G5602550) may be required.

**KernelSU not detected:** Ensure you flashed `boot.img` from this build, not stock.

## License

Kernel patches: GPL-2.0 (same as Linux kernel). Build scripts: MIT.
