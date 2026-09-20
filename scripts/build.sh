#!/usr/bin/env bash
# Build Husky WiFi Fix kernel with KernelSU for Pixel 8 Pro
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL_DIR="${KERNEL_DIR:-$ROOT/kernel}"
OUT_DIR="$ROOT/out"
BUILD_ID="${BUILD_ID:-$(date +%Y%m%d)}"
VERSION="husky-wifi-fix-${BUILD_ID}"

echo "==> Building $VERSION"
echo "    Kernel source: $KERNEL_DIR"

if [[ ! -d "$KERNEL_DIR" ]]; then
	echo "ERROR: Kernel source not found. Run ./scripts/setup.sh first."
	exit 1
fi

cd "$KERNEL_DIR"

# Clean previous build artifacts
if [[ "${CLEAN:-0}" == "1" ]]; then
	echo "==> Cleaning build..."
	./tools/bazel clean --expunge 2>/dev/null || true
fi

# Build shusky GKI kernel (Pixel 8 / 8 Pro share this tree)
echo "==> Compiling kernel (45–90 min on first run)..."
bash private/devices/google/shusky/build_shusky.sh \
	--config=pixel_debug_common \
	--lto=thin 2>&1 | tee "$OUT_DIR/build.log"

mkdir -p "$OUT_DIR/images"

# Collect output images
DIST="$KERNEL_DIR/out/shusky/dist"
if [[ -d "$DIST" ]]; then
	cp -v "$DIST"/{boot.img,vendor_kernel_boot.img,dtbo.img} "$OUT_DIR/images/" 2>/dev/null || true
fi

# Also check bazel output paths
BAZEL_OUT="$KERNEL_DIR/bazel-bin"
find "$BAZEL_OUT" -name "boot.img" -exec cp -v {} "$OUT_DIR/images/" \; 2>/dev/null || true
find "$BAZEL_OUT" -name "vendor_kernel_boot.img" -exec cp -v {} "$OUT_DIR/images/" \; 2>/dev/null || true
find "$BAZEL_OUT" -name "dtbo.img" -exec cp -v {} "$OUT_DIR/images/" \; 2>/dev/null || true

# Verify we got images
if [[ ! -f "$OUT_DIR/images/boot.img" ]]; then
	echo "ERROR: boot.img not found in build output."
	echo "Check $OUT_DIR/build.log for errors."
	exit 1
fi

# Verify KernelSU is in the kernel
echo "==> Verifying KernelSU integration..."
if strings "$OUT_DIR/images/boot.img" 2>/dev/null | grep -qi "kernelsu"; then
	echo "    KernelSU: OK"
else
	echo "    WARNING: KernelSU string not found in boot.img — verify setup.sh ran correctly"
fi

# Package flashable ZIP
"$ROOT/scripts/package-flashable.sh" "$VERSION"

echo ""
echo "==> Build complete!"
echo "    Images:  $OUT_DIR/images/"
echo "    ZIP:     $OUT_DIR/flashable/${VERSION}.zip"
echo ""
echo "    Test:    fastboot boot $OUT_DIR/images/boot.img"
echo "    Flash:   fastboot flash boot $OUT_DIR/images/boot.img"
