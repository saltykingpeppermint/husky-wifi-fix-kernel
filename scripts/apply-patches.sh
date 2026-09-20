#!/usr/bin/env bash
# Apply all WiFi/BT recovery patches to the kernel source tree
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL_DIR="${KERNEL_DIR:-$ROOT/kernel}"
PATCH_DIR="$ROOT/patches"

cd "$KERNEL_DIR"

apply_patch() {
	local patch="$1"
	local target_dir="${2:-.}"

	echo "  Applying $(basename "$patch")..."
	cd "$KERNEL_DIR/$target_dir"

	# Try git apply first, fall back to patch
	if git apply --check "$patch" 2>/dev/null; then
		git apply "$patch"
	elif patch -p1 --dry-run < "$patch" 2>/dev/null; then
		patch -p1 < "$patch"
	else
		echo "  WARNING: $(basename "$patch") did not apply cleanly."
		echo "  Manual merge may be required — see patch file for intended changes."
		# For new files (watchdog driver), create directly from patch
		if grep -q "new file mode" "$patch" 2>/dev/null; then
			echo "  Attempting to extract new file from patch..."
			git apply --reject "$patch" 2>/dev/null || true
		fi
	fi

	cd "$KERNEL_DIR"
}

echo "==> Applying patches from $PATCH_DIR"

# Patch targets depend on Google's tree layout for shusky android16
apply_patch "$PATCH_DIR/0001-s2mpg15-wlan-bt-power-rail-retry.patch" "private/google-modules/soc/gs"
apply_patch "$PATCH_DIR/0002-pcie-brcm-link-recovery-enhanced.patch" "private/google-modules/soc/gs"
apply_patch "$PATCH_DIR/0003-dhd-wifi-init-retry-increase.patch" "private/google-modules/wlan/bcm4383"
apply_patch "$PATCH_DIR/0004-dhd-l1ss-disable-quirk.patch" "private/google-modules/wlan/bcm4383"
apply_patch "$PATCH_DIR/0005-wifi-bt-runtime-recovery-watchdog.patch" "private/google-modules/soc/gs"

# Commit so kernel isn't marked dirty
for dir in common private/google-modules/soc/gs private/google-modules/wlan/bcm4383; do
	if [[ -d "$KERNEL_DIR/$dir/.git" ]] || git -C "$KERNEL_DIR/$dir" rev-parse --git-dir &>/dev/null; then
		git -C "$KERNEL_DIR/$dir" add -A 2>/dev/null || true
		git -C "$KERNEL_DIR/$dir" commit -m "Husky WiFi/BT recovery patches" --allow-empty 2>/dev/null || true
	fi
done

echo "==> Patches applied."
