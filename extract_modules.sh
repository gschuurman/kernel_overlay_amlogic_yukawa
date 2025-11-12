#!/bin/bash
# Script to extract filtered module tars in the dist directory

set -e

DIST_DIR="${1:-out/android-mainline}"

echo "Extracting filtered modules in $DIST_DIR"

# Extract system_dlkm modules
if [ -f "$DIST_DIR/system_dlkm/system_dlkm_filtered.tar" ]; then
    echo "Extracting system_dlkm modules..."
    tar -xf "$DIST_DIR/system_dlkm/system_dlkm_filtered.tar" -C "$DIST_DIR/system_dlkm/"
    rm "$DIST_DIR/system_dlkm/system_dlkm_filtered.tar"
    echo "  $(ls $DIST_DIR/system_dlkm/*.ko 2>/dev/null | wc -l) modules extracted"
fi

# Extract vendor_dlkm modules
if [ -f "$DIST_DIR/vendor_dlkm/vendor_dlkm_filtered.tar" ]; then
    echo "Extracting vendor_dlkm modules..."
    tar -xf "$DIST_DIR/vendor_dlkm/vendor_dlkm_filtered.tar" -C "$DIST_DIR/vendor_dlkm/"
    rm "$DIST_DIR/vendor_dlkm/vendor_dlkm_filtered.tar"
    echo "  $(ls $DIST_DIR/vendor_dlkm/*.ko 2>/dev/null | wc -l) modules extracted"
fi

# Extract ramdisk modules
if [ -f "$DIST_DIR/ramdisk/ramdisk_filtered.tar" ]; then
    echo "Extracting ramdisk modules..."
    tar -xf "$DIST_DIR/ramdisk/ramdisk_filtered.tar" -C "$DIST_DIR/ramdisk/"
    rm "$DIST_DIR/ramdisk/ramdisk_filtered.tar"
    echo "  $(ls $DIST_DIR/ramdisk/*.ko 2>/dev/null | wc -l) modules extracted"
fi

echo "Done!"
