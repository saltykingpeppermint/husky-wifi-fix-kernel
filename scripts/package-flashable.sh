#!/usr/bin/env bash
# Package kernel images into AnyKernel3 flashable ZIP for Pixel 8 Pro
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-husky-wifi-fix-$(date +%Y%m%d)}"
OUT_DIR="$ROOT/out"
FLASH_DIR="$OUT_DIR/flashable/staging"
ZIP_PATH="$OUT_DIR/flashable/${VERSION}.zip"
AK3_DIR="$ROOT/anykernel3"

rm -rf "$FLASH_DIR"
mkdir -p "$FLASH_DIR"

# Clone AnyKernel3 tools if not present
if [[ ! -f "$AK3_DIR/tools/ak3-core.sh" ]]; then
	echo "==> Cloning AnyKernel3..."
	git clone --depth=1 https://github.com/osm0sis/AnyKernel3.git "$AK3_DIR"
fi

# Copy AK3 framework + our anykernel.sh
cp -r "$AK3_DIR/tools" "$AK3_DIR/META-INF" "$FLASH_DIR/"
cp "$ROOT/anykernel3/anykernel.sh" "$FLASH_DIR/anykernel.sh"
chmod +x "$FLASH_DIR/anykernel.sh"

# Copy all kernel partition images
for img in boot vendor_kernel_boot dtbo vendor_dlkm system_dlkm; do
	if [[ -f "$OUT_DIR/images/${img}.img" ]]; then
		cp "$OUT_DIR/images/${img}.img" "$FLASH_DIR/"
		echo "  + ${img}.img"
	fi
done

if [[ ! -f "$FLASH_DIR/boot.img" ]]; then
	echo "ERROR: boot.img missing from out/images/"
	exit 1
fi

# Create flashable ZIP
cd "$FLASH_DIR"
zip -r9 "$ZIP_PATH" . -x '*.git*' 'README.md' '*placeholder*'
cd "$ROOT"

sha256sum "$ZIP_PATH" > "${ZIP_PATH}.sha256"

echo "==> Packaged: $ZIP_PATH"
ls -lh "$OUT_DIR/images/"*.img 2>/dev/null || true
