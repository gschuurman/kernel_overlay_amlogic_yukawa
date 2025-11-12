#!/bin/bash
# Wrapper script that runs pkg_install and extracts filtered modules

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Run the pkg_install script
"$REPO_ROOT/bazel-bin/yukawa-device/yukawa_dist_install_script.py" "$@"

# Get the destination directory (default is out/android-mainline)
DIST_DIR="${1:-$REPO_ROOT/out/android-mainline}"

echo "Extracting filtered modules in $DIST_DIR"

# Extract system_dlkm modules
if [ -f "$DIST_DIR/system_dlkm/system_dlkm_filtered.tar" ]; then
    tar -xf "$DIST_DIR/system_dlkm/system_dlkm_filtered.tar" -C "$DIST_DIR/system_dlkm/"
    rm "$DIST_DIR/system_dlkm/system_dlkm_filtered.tar"
    echo "  system_dlkm: $(ls $DIST_DIR/system_dlkm/*.ko 2>/dev/null | wc -l) modules"
fi

# Extract vendor_dlkm modules
if [ -f "$DIST_DIR/vendor_dlkm/vendor_dlkm_filtered.tar" ]; then
    tar -xf "$DIST_DIR/vendor_dlkm/vendor_dlkm_filtered.tar" -C "$DIST_DIR/vendor_dlkm/"
    rm "$DIST_DIR/vendor_dlkm/vendor_dlkm_filtered.tar"
    echo "  vendor_dlkm: $(ls $DIST_DIR/vendor_dlkm/*.ko 2>/dev/null | wc -l) modules"
fi

# Extract ramdisk modules
if [ -f "$DIST_DIR/ramdisk/ramdisk_filtered.tar" ]; then
    tar -xf "$DIST_DIR/ramdisk/ramdisk_filtered.tar" -C "$DIST_DIR/ramdisk/"
    rm "$DIST_DIR/ramdisk/ramdisk_filtered.tar"
    echo "  ramdisk: $(ls $DIST_DIR/ramdisk/*.ko 2>/dev/null | wc -l) modules"
fi
