#!/usr/bin/env bash
# Package kernel images into a flashable ZIP for Lineage Recovery
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-husky-wifi-fix-$(date +%Y%m%d)}"
OUT_DIR="$ROOT/out"
FLASH_DIR="$OUT_DIR/flashable/staging"
ZIP_PATH="$OUT_DIR/flashable/${VERSION}.zip"

rm -rf "$FLASH_DIR"
mkdir -p "$FLASH_DIR"

# Copy kernel images
cp "$OUT_DIR/images/boot.img" "$FLASH_DIR/"
cp "$OUT_DIR/images/vendor_kernel_boot.img" "$FLASH_DIR/" 2>/dev/null || true
cp "$OUT_DIR/images/dtbo.img" "$FLASH_DIR/" 2>/dev/null || true

mkdir -p "$FLASH_DIR/META-INF/com/google/android"

# Updater script for Lineage Recovery / TWRP
cat > "$FLASH_DIR/META-INF/com/google/android/updater-script" << 'UPDATER'
ui_print("Husky WiFi/BT Recovery Kernel");
ui_print("With KernelSU root");
ui_print(" ");

show_progress(0.1, 0);
ui_print("- Flashing boot.img...");
package_extract_file("boot.img", "/dev/block/by-name/boot");
show_progress(0.4, 0);

ui_print("- Flashing vendor_kernel_boot.img...");
if (file_exists("vendor_kernel_boot.img")) {
  package_extract_file("vendor_kernel_boot.img", "/dev/block/by-name/vendor_kernel_boot");
}
show_progress(0.7, 0);

ui_print("- Flashing dtbo.img...");
if (file_exists("dtbo.img")) {
  package_extract_file("dtbo.img", "/dev/block/by-name/dtbo");
}
show_progress(1.0, 0);

ui_print(" ");
ui_print("Done! Reboot to activate WiFi/BT fixes + KernelSU.");
UPDATER

# Create flashable ZIP
cd "$FLASH_DIR"
zip -r9 "$ZIP_PATH" . -i \*
cd "$ROOT"

# Checksums
sha256sum "$ZIP_PATH" > "${ZIP_PATH}.sha256"
md5sum "$ZIP_PATH" > "${ZIP_PATH}.md5"

echo "==> Packaged: $ZIP_PATH"
echo "    SHA256: $(cat "${ZIP_PATH}.sha256")"
