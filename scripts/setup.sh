#!/usr/bin/env bash
# Clone Pixel 8 Pro (husky) Android 16 kernel source and apply WiFi/BT patches + KernelSU
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL_DIR="${KERNEL_DIR:-$ROOT/kernel}"
BRANCH="android-gs-shusky-6.1-android16"
GKI_BRANCH="android14-6.1"

echo "==> Husky WiFi Fix Kernel — setup"
echo "    Kernel dir: $KERNEL_DIR"

# Install repo if missing
if ! command -v repo &>/dev/null; then
	echo "Installing repo tool..."
	mkdir -p ~/bin
	curl -sSL https://storage.googleapis.com/git-repo-downloads/repo -o ~/bin/repo
	chmod +x ~/bin/repo
	export PATH="$HOME/bin:$PATH"
fi

# Clone kernel manifest
if [[ ! -d "$KERNEL_DIR/.repo" ]]; then
	echo "==> Initializing kernel manifest (this takes ~30 min)..."
	mkdir -p "$KERNEL_DIR"
	cd "$KERNEL_DIR"
	repo init -u https://android.googlesource.com/kernel/manifest \
		-b "common-$BRANCH" \
		--repo-url=https://android.googlesource.com/tools/repo \
		--repo-branch=stable
	repo sync -c -j"$(nproc)" --no-tags --no-clone-bundle
else
	echo "==> Kernel source already present, syncing..."
	cd "$KERNEL_DIR"
	repo sync -c -j"$(nproc)" --no-tags --no-clone-bundle
fi

cd "$KERNEL_DIR"

# Install KernelSU into common kernel tree
echo "==> Installing KernelSU..."
if [[ ! -d "$KERNEL_DIR/common/KernelSU" ]]; then
	curl -LSs "https://github.com/tiann/KernelSU/raw/main/kernel/setup.sh" | bash -
fi

# Apply WiFi/BT recovery patches
echo "==> Applying WiFi/BT recovery patches..."
"$ROOT/scripts/apply-patches.sh"

# Enable recovery watchdog in defconfig
DEFCONFIG="$KERNEL_DIR/private/google-modules/soc/gs/build.config.gs101"
if [[ -f "$DEFCONFIG" ]]; then
	echo "CONFIG_WLAN_BT_RECOVERY=y" >> "$KERNEL_DIR/common/arch/arm64/configs/gki_defconfig" 2>/dev/null || true
fi

echo ""
echo "==> Setup complete."
echo "    Run: ./scripts/build.sh"
